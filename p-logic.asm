;;; -*- TI-Asm -*-
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Logical Operations
;;;


;; AND:
;;
;; AND condition1 condition2
;;
;; Output TRUE if both inputs are TRUE, FALSE otherwise.

p_AND:
	BUILTIN_PRIMITIVE 2, 2, 2, "BB$"
	call Pop2OPS
	ld a,l
	and e
	jp z,ReturnFalse
	jp ReturnTrue


;; OR:
;;
;; OR condition1 condition2
;;
;; Output TRUE if either input is TRUE, FALSE otherwise.

p_OR:
	BUILTIN_PRIMITIVE 2, 2, 2, "BB$"
	call Pop2OPS
	ld a,l
	or e
	jp z,ReturnFalse
	jp ReturnTrue


;; NOT:
;;
;; NOT condition
;;
;; Output TRUE if :condition is FALSE, FALSE if :condition is TRUE.

p_NOT:
	BUILTIN_PRIMITIVE 1, 1, 1, "B$"
	call PopOPS
	ld a,l
	or a
	jp z,ReturnTrue
	jp ReturnFalse
