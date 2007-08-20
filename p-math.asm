;;; -*- TI-Asm -*-
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Arithmetic Primitives
;;;


;; SUM:
;;
;; SUM number1 number2
;;
;; Output the sum of the inputs (:number1 + :number2).

p_SUM:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	add hl,de
	bit 7,h
	ret z
ErrOverflow:
	BCALL _ErrOverflow
	;; UNREACHABLE


;; DIFFERENCE:
;;
;; DIFFERENCE number1 number2
;;
;; Output the difference of the inputs (:number1 - :number2).

p_DIFFERENCE:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	or a
	sbc hl,de
	jr c,ErrOverflow
	ret


;; PRODUCT:
;;
;; PRODUCT number1 number2
;;
;; Output the product of the inputs (:number1 x :number2).

p_PRODUCT:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	ld c,h
	ld a,l
	call CAtimesDE_U
	or c
	jr nz,ErrOverflow
	bit 7,h
	jr nz,ErrOverflow
	ret

CAtimesDE_U:
	;; (unsigned)
	;; result in CAHL
	ld hl,0
	ld b,17
CAtimesDE_U_next:
	dec b
	ret z
CAtimesDE_U_loop:
	add hl,hl
	rla
	rl c
	jr nc,CAtimesDE_U_next
	add hl,de
	adc a,0
	jr nc,CAtimesDE_U_next
	inc c
	djnz CAtimesDE_U_loop
	ret


_DivHLByDE equ 804Bh

;; QUOTIENT:
;;
;; QUOTIENT number1 number2
;;
;; Output the quotient of the inputs (:number1 / :number2).

p_QUOTIENT:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	ld a,d
	or e
	jr z,ErrDivBy0
	BCALL _DivHLByDE
	ex de,hl
	ret
ErrDivBy0:
	BCALL _ErrDivBy0
	;; UNREACHABLE


;; REMAINDER:
;;
;; REMAINDER number1 number2
;;
;; Output the remainder when dividing :number1 by :number2.

p_REMAINDER:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	ld a,d
	or e
	jr z,ErrDivBy0
	BCALL _DivHLByDE
	ret


;; LESSP:
;;
;; LESSP number1 number2
;; LESS? number1 number2
;;
;; Test if :number1 is less than :number2.

p_LESSP:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	or a
	sbc hl,de
	jp c,ReturnTrue
	jp ReturnFalse


;; GREATERP:
;;
;; GREATERP number1 number2
;; GREATER? number1 number2
;;
;; Test if :number1 is less than :number2.

p_GREATERP:
	BUILTIN_PRIMITIVE 2, 2, 2, "II$"
	call Pop2OPS
	scf
	sbc hl,de
	jp nc,ReturnTrue
	jp ReturnFalse


;; RANDOM:
;;
;; RANDOM number
;;
;; Output a random integer less than the input and greater than or
;; equal to zero.

p_RANDOM:
	BUILTIN_PRIMITIVE 1, 1, 1, "I$"
	BCALL _Random
	call PopOPS
	BCALL _SetXXXXOP2
	BCALL _FPMult
	BCALL _Trunc
	BCALL _ConvOP1
 warning "FIXME: ConvOP1 is stupid, don't use it"
	ex de,hl
	ret
