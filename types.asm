;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Type Manipulation Routines
;;;

;; GetType:
;;
;; Get the type of a Logo value.
;;
;; Input:
;; - HL = value
;;
;; Output:
;; - A = type
;;
;; Destroys:
;; - F

GetType:
	bit 7,h
	ld a,T_INT
	ret z
	push hl
	 call RefToPointer
	 ld a,(hl)
	 rrca
	 jr c,GetType_Float
	 rrca
	 jr c,GetType_List
	 pop hl
	ret

GetType_Float:
	 inc hl
	 inc hl
	 ld a,(hl)
	 add a,a
	 pop hl
	ld a,T_REAL
	ret nc
	ld a,T_COMPLEX
	ret

GetType_List:
	 pop hl
	ld a,T_LIST
	ret


;; CheckInputTypes:
;;
;; Check the types of a list of inputs, and throw an error if any are
;; incorrect.  The list of accepted types is given as a string, each
;; character representing one input value.  The string is read from
;; the return address of this routine, and is terminated by either a
;; dollar sign or asterisk.  For instance:
;;
;;   call CheckInputTypes
;;   db "llw$"
;;
;; would check that the primitive's first three inputs were a list, a
;; list and a word, in that order.
;;
;; Uppercase letters will force the value to be converted into the
;; type specified, while lowercase letters merely check that the
;; conversion is possible.  For instance, 'r' will match any real
;; number (either an integer, float, or even a complex object if the
;; imaginary part is zero), but 'R' will force it to be converted into
;; a real floating-point object.
;;
;; If the string has an asterisk as its last character, this will
;; check and/or convert all of the remaining arguments.  If it is a
;; dollar sign, remaining arguments are ignored.
;;
;; Char  Type
;;  b    Boolean (the word TRUE or FALSE)
;;  B    Boolean (force conversion to an integer 1 or 0)
;;  c    Complex
;;  C    Complex (force conversion)
;;  i    Integer
;;  I    Integer (force conversion)
;;  l    List
;;  n    Nonempty list
;;  q    Sequence
;;  r    Real
;;  R    Real (force conversion)
;;  S    Symbol (force conversion)
;;  w    Word
;;  .    Anything
;;
;; Input:
;; - HL = number of arguments provided to primitive
;; - (SP) = address of pattern string
;; - (OPS) = list of arguments
;;
;; Destroys:
;; - AF, BC, DE

CheckInputTypes:
	pop bc			; GETRETURN
	push hl
	 ex de,hl
	 ld hl,(OPS)
	 add hl,de
	 add hl,de
CheckInputTypes_Loop:
	 dec hl
	 ld d,(hl)
	 dec hl
	 ld e,(hl)
	 ld a,(bc)
	 inc bc
	 cp '.'
	 jr z,CheckInputTypes_Loop
	 cp '$'
	 jr z,CheckInputTypes_Done
	 ex de,hl
	 cp '*'
	 jr z,CheckInputTypes_Rest
	 push af
	  or 20h
	  cp 'b'
	  jr z,CheckInputTypes_Boolean
; 	  cp 'c'
; 	  jr z,CheckInputTypes_Complex
	  cp 'i'
	  jr z,CheckInputTypes_Int
	  cp 'l'
	  jr z,CheckInputTypes_List
	  cp 'n'
	  jr z,CheckInputTypes_Nonempty
	  cp 'q'
	  jr z,CheckInputTypes_Sequence
; 	  cp 'r'
; 	  jr z,CheckInputTypes_Real
	  cp 's'
	  jr z,CheckInputTypes_Symbol
	  cp 'w'
	  jr z,CheckInputTypes_Word
	  pop af
CheckInputTypes_LoopDE:
	 ex de,hl
	 jr CheckInputTypes_Loop
CheckInputTypes_Done:
	 pop hl
	push bc			; SETRETURN
	ret

CheckInputTypes_Rest:
	 inc de
	 inc de
	 ld hl,(OPS)
	 sbc hl,de
	 jr nc,CheckInputTypes_Done
	 dec bc
	 dec bc
	 jr CheckInputTypes_LoopDE

CheckInputTypes_List:
	  call IsList
	  jr CheckInputTypes_Validate

CheckInputTypes_Nonempty:
	  call IsList
	  jr z,CheckInputTypes_Error
	  jr CheckInputTypes_Validate

CheckInputTypes_Sequence:
	  call IsList
	  jr nc,CheckInputTypes_ValidateOK
CheckInputTypes_Word:
	  call IsWord
CheckInputTypes_Validate:
	  jr c,CheckInputTypes_Error
CheckInputTypes_ValidateOK:
	  pop af
	 jr CheckInputTypes_LoopDE

CheckInputTypes_Error:
	  BCALL _ErrDataType
	  ;; UNREACHABLE

CheckInputTypes_Symbol:
	  call WordToSymbol
CheckInputTypes_Convert:
	  jr c,CheckInputTypes_Error
CheckInputTypes_ConvertOK:
	  pop af
	 and 20h
	 jr nz,CheckInputTypes_LoopDE
	 ex de,hl
	 ld (hl),e
	 inc hl
	 ld (hl),d
	 dec hl
	 jr CheckInputTypes_Loop

CheckInputTypes_Int:
	  call GetType
	  cp T_INT
	  jr z,CheckInputTypes_ValidateOK
; 	  cp T_REAL
; 	  jr z,CheckInputTypes_RealToInt
; 	  cp T_COMPLEX
; 	  jr z,CheckInputTypes_ComplexToInt
	  jr CheckInputTypes_Error
; CheckInputTypes_FloatToInt:
; 	  call RealToInt
; 	  jr CheckInputTypes_Convert
; CheckInputTypes_ComplexToInt:
; 	  call ComplexToInt
; 	  jr CheckInputTypes_Convert

CheckInputTypes_Boolean:
	  call WordToSymbol
	  jr c,CheckInputTypes_Error
 if high(trueNode) != high(falseNode)
 error "high(trueNode) != high(falseNode).  Try rearranging builtin symbols."
 endif
	  ld a,h
	  cp high(trueNode)
	  jr nz,CheckInputTypes_Error
	  ld a,l
	  ld hl,0
	  cp low(falseNode)
	  jr z,CheckInputTypes_ConvertOK
	  inc l
	  cp low(trueNode)
	  jr z,CheckInputTypes_ConvertOK
	  jr CheckInputTypes_Error

