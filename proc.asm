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
;	cp T_LIST
;	jr z,GetProcedureDefaultArity_List
	BCALL _ErrDataType
	;; UNREACHABLE

GetProcedureDefaultArity_Subr:
	call GetNodeContents
	INC_BHL
	LOAD_A_iBHL
	ld l,a
	ld h,0
	ret
