;;; -*- TI-Asm -*-
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Control Structure Primitives
;;;


;; RUN:
;;
;; RUN instructionlist
;;
;; Evaluate the instructions in the input list.

p_RUN:
	BUILTIN_PRIMITIVE 1, 1, 1, "l$"
	call PopOPS
	jp EvalTail


;; IF:
;;
;; IF condition instructionlist
;;
;; If :condition is true, run :instructionlist.

p_IF:
	BUILTIN_PRIMITIVE 2, 2, 2, "Bl$"
	call Pop2OPS
	ld a,l
	or a
	jp z,ReturnVoid
	ex de,hl
	jp EvalTail


;; IFELSE:
;;
;; IFELSE condition instructionlist1 instructionlist2
;;
;; If :condition is true, run instructionlist1; if it is false, run
;; instructionlist2.

p_IFELSE:
	BUILTIN_PRIMITIVE 3, 3, 3, "Bll$"
	call Pop3OPS
	ld a,l
	ld h,b
	ld l,c
	or a
	jr z,IFELSE_False
	ex de,hl
IFELSE_False:
	jp EvalTail


;; REPEAT:
;;
;; REPEAT number instructionlist
;;
;; Run :instructionlist repeatedly, :number times.

p_REPEAT:
	BUILTIN_PRIMITIVE 2, 2, 2, "Il$"
	call Pop2OPS		; HL = count, DE = list
	ld a,h
	or l
	jp z,ReturnVoid
REPEAT_Loop:
	dec hl
	ld a,h
	or l
	jr z,REPEAT_Last
	call PushOPS		; push count
	ex de,hl
	call PushOPS		; push list
	call EvalRecursiveVoid
	call Pop2OPS		; HL = count, DE = list
	jr REPEAT_Loop
REPEAT_Last:
	ex de,hl
	jp EvalTailVoid


;; STOP:
;;
;; STOP
;;
;; End the current procedure immediately, without outputting anything.

p_STOP:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	ld hl,voidNode
	jr OUTPUT_Value


;; OUTPUT:
;;
;; OUTPUT thing
;; OP thing
;;
;; End the current procedure immediately, and output :thing.

p_OUTPUT:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
OUTPUT_Value:
	ld sp,(mainSP)
	push hl
	 ld hl,(evalProcTop)
	 ld a,h
	 or l
	 jr z,OUTPUT_Error
	 ld de,(OPBase)
	 add hl,de
	 ld (OPS),hl
	 pop hl
	jp Eval_ExitProcedure
OUTPUT_Error:
	 ld hl,EMsg_OnlyInsideProcedure
	 ld de,(evalNextProc)
	 ld a,E_Invalid
	 call ThrowError
	 ;; UNREACHABLE


;; BYE:
;;
;; BYE
;;
;; Exit Logo and return to the calculator homescreen.

p_BYE:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	BCALL _JForceCmdNoChar
	;; UNREACHABLE


;; IGNORE:
;;
;; IGNORE thing
;;
;; Do nothing.

p_IGNORE:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	jp ReturnVoid
