;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Procedure Manipulation
;;;

;; GetProcedureDefaultArity:
;;
;; Get the default arity (number of arguments) for a procedure.
;;
;; Input:
;; - HL = procedure
;;
;; Output:
;; - HL = number of arguments
;;
;; Destroys:
;; - AF, BC, DE, HL

GetProcedureDefaultArity:
	call GetType
	cp T_SUBR
	jr z,GetProcedureDefaultArity_Subr
	cp T_LIST
	jr z,GetProcedureDefaultArity_List
GetProcedureDefaultArity_Error:
	BCALL _ErrDataType
	;; UNREACHABLE

GetProcedureDefaultArity_Subr:
	call GetNodeContents
	INC_BHL
	LOAD_A_iBHL
	ld l,a
	ld h,0
	ret

GetProcedureDefaultArity_List:
	ld de,0
	call GetListFirst
GetProcedureDefaultArity_ListLoop:
	call IsList
	jr c,GetProcedureDefaultArity_Error
	jr z,GetProcedureDefaultArity_ListDone
	inc de
	call GetListButfirst
	jr GetProcedureDefaultArity_ListLoop
GetProcedureDefaultArity_ListDone:
	ex de,hl
	ret


;; EnterSubr:
;;
;; Jump into a primitive.
;;
;; Input:
;; - HL = primitive
;; - BC = offset from start of code
;; - DE = parameter (passed to primitive in HL)

EnterSubr:
	ld (currentSubr),hl
	push de
	 push bc
	  call GetNodeContents
 ifndef NO_PAGED_MEM
	  ld a,b
	  or a
	  jr z,EnterSubr_Paged
 endif
	  ld a,(hl)		; is subr position-independent?
	  ld bc,4
	  add hl,bc
	  ld c,(hl)		; get length of subr
	  inc hl
	  ld b,(hl)
	  inc hl
	  and 1
	  jr z,EnterSubr_NotPI

	  ;; Check if subr falls within executable RAM
	  add hl,bc
	  ld a,h
	  sbc hl,bc
	  cp 0C0h
	  jr nc,EnterSubr_NotPI
EnterSubr_StartingAddr:
	  ld (subrStartAddr),hl
	  pop bc
	 add hl,bc
	 pop de
	push hl			; SETRETURN
	ex de,hl
	ret

EnterSubr_NotPI:
	  ld de,subrExecMem
	  push de
	   ldir
	   pop hl
	  jr EnterSubr_StartingAddr

 ifndef NO_PAGED_MEM
EnterSubr_Paged:
	  ld de,4
	  ADD_BHL_DE
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,b
	  ld b,d
	  ld c,e
	  ld de,subrExecMem
	  push de
	   FLASH_TO_RAM
	   pop hl
	  jr EnterSubr_StartingAddr
 endif


;; IsTOLine:
;;
;; Check if input is a list starting with TO.
;;
;; Input:
;; - HL = input list
;;
;; Output:
;; - CF set if input is not a TO-line
;; - CF clear if input is a TO-line
;;
;; Destroys:
;; - DE

IsTOLine:
	call IsList
	ret c
	scf
	ret z
	push hl
	 call GetListFirst
	 ld de,TO_Node0
	 or a
	 sbc hl,de
	 pop hl
	ret z
	scf
	ret


;; IsENDLine:
;;
;; Check if input is a list containing the single element END.
;;
;; Input:
;; - HL = input list
;;
;; Output:
;; - CF set if input is not an END-line
;; - CF clear if input is an END-line
;;
;; Destroys:
;; - HL, BC, DE
	
IsENDLine:
	call IsList
	ret c
	scf
	ret z
	call GetListFirstButfirst
	ld bc,endNode
	or a
	sbc hl,bc
	scf
	ret nz
	ld hl,emptyNode
	or a
	sbc hl,de
	ret z
	scf
	ret


;; ParseProcDefinition:
;;
;; Parse a TO-form procedure definition.
;;
;; Input:
;; - HL = TO-line
;; - DE = body of procedure
;;
;; Output:
;; - HL = name of new procedure
;;
;; Destroys:
;; - AF, BC, DE, HL

ParseProcDefinition:
	push de
	 call GetListButfirst
	 call IsList
	 jr c,ParseProcDefinition_NoName
	 jr z,ParseProcDefinition_NoName
	 call GetListFirstButfirst
	 push hl		; name of procedure
	  ex de,hl
	  call CopyList
	  push hl		; list of args
ParseProcDefinition_ConvertArgsLoop:
	   call IsList
	   jr z,ParseProcDefinition_ConvertArgsDone
	   push hl
	    call GetListFirst
	    call IsWord
	    jr c,ParseProcDefinition_InvalidArg
	    call GetType
	    cp T_COLON
	    call z,GetAtomData
	    call WordToSymbol
	    jr c,ParseProcDefinition_InvalidArg
	    ex de,hl
	    pop hl
	   push hl
	    call SetListFirst
	    pop hl
	   call GetListButfirst
	   jr ParseProcDefinition_ConvertArgsLoop
ParseProcDefinition_ConvertArgsDone:
	   pop hl		; list of args
	  pop bc		; procedure name
	 pop de			; procedure body
	push bc
	 call NewList
	 ex de,hl
	 pop hl
	push hl
	 call SetSymbolProcedure
	 pop hl
	ret

ParseProcDefinition_NoName:
	 ld hl,EMsg_NotEnoughInputs
	 ld de,TO_Node0
	 ld a,E_Syntax
	 call ThrowError
	 ;; UNREACHABLE

ParseProcDefinition_InvalidArg:
	    ex de,hl
	    ld hl,EMsg_BadInput
	    ld bc,TO_Node0
	    ld a,E_Syntax
	    call ThrowError
	    ;; UNREACHABLE


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Miscellaneous Subroutines
;;;


;; ReturnVoid:
;;
;; Return void.
;;
;; Output:
;; - HL = void
;;
;; Destroys:
;; - None

ReturnVoid:
	ld hl,voidNode
	ret


;; ReturnTrue:
;;
;; Return TRUE.
;;
;; Output:
;; - HL = TRUE
;;
;; Destroys:
;; - None

ReturnTrue:
	ld hl,trueNode
	ret


;; ReturnFalse:
;;
;; Return FALSE.
;;
;; Output:
;; - HL = FALSE
;;
;; Destroys:
;; - None

ReturnFalse:
	ld hl,falseNode
	ret


;; ValuesEqual:
;;
;; Test if two values are equal
;;
;; Input:
;; - HL = first value
;; - DE = second value
;;
;; Output:
;; - ZF set if values are equal
;;
;; Destroys:
;; - AF, BC, DE, HL

ValuesEqual:
	;; Check if the values are identical
	or a
	sbc hl,de
	ret z
	add hl,de

	;; Two integers are equal iff they are identical
	bit 7,h
	jr nz,ValuesEqual_NotInts
	bit 7,d
	jr nz,ValuesEqual_NotInts
RetNZ:	or 1
	ret
ValuesEqual_NotInts:

	call IsList
	jr nc,ValuesEqual_List

	;; Objects other than lists and words are EQUALP iff they are
	;; identical
	call IsWord
	jr c,RetNZ

	call GetType
	push af
	 ex de,hl
	 call IsWord
	 pop bc
	jr c,RetNZ

	;; Two symbols are equal iff they are identical
	ld a,b
	cp T_SYMBOL
	jr nz,ValuesEqual_NotSymbols
	call GetType
	cp T_SYMBOL
	jr z,RetNZ
ValuesEqual_NotSymbols:

	;; Compare lengths of words
	push hl
	 push de
	  call GetWordSize
	  ex de,hl
	  pop hl
	 push hl
	  push de
	   call GetWordSize
	   pop bc
	  or a
	  sbc hl,bc
	  pop de
	 pop hl
ValuesEqual_WordLoop:
	;; Compare words character-by-character
	ld a,b
	or c
	ret z
	dec bc
	push hl
	 push bc
	  push de
	   ld d,b
	   ld e,c
	   call GetWordChar
	   pop hl
	  pop de
	 push de
	  push hl
	   push af
	    call GetWordChar
	    pop bc
	   cp b
	   pop de
	  pop bc
	 pop hl
	jr z,ValuesEqual_WordLoop
	ret

ValuesEqual_List:
	ex de,hl
	call IsList
	jr c,RetNZ

	push hl
	 ld hl,(OPS)
	 ld (equalOPS),hl
	 ld hl,0
	 call PushOPS
	 pop hl
ValuesEqual_ListLoop:
	call IsList
	jr c,ValuesEqual_NotList
	jr z,ValuesEqual_ListEmpty

	ex de,hl
	call IsList
	jr c,ValuesEqual_ListFail
	jr z,ValuesEqual_ListFail

	call PushOPS
	call GetListFirst
	ex de,hl
	call PushOPS
	call GetListFirst
	jr ValuesEqual_ListLoop

ValuesEqual_NotList:
	call ValuesEqual
	jr nz,ValuesEqual_ListFail
ValuesEqual_ListNext:
	call PopOPS
	ld a,h
	or l
	ret z
	call GetListButfirst
	ex de,hl
	call PopOPS
	call GetListButfirst
	jr ValuesEqual_ListLoop

ValuesEqual_ListEmpty:
	ex de,hl
	call IsList
	jr c,ValuesEqual_ListFail
	jr z,ValuesEqual_ListNext
ValuesEqual_ListFail:
	ld hl,(equalOPS)
	ld (OPS),hl
	or 1
	ret
