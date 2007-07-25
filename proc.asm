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
