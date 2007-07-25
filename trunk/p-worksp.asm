;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Workspace Management Primitives
;;;


;; MAKE:
;;
;; MAKE word thing
;;
;; Store the given :thing in the variable named by :word.  Keep in
;; mind that a variable's name is not the same as its value!  You
;; almost always want to say
;;
;;   MAKE "foo 42
;;
;; rather than
;;
;;   MAKE :foo 42
;;
;; (The former assigns a value to the variable foo, while the latter
;; uses the value of foo as the name of a variable to create.)

p_MAKE:
	BUILTIN_PRIMITIVE 2, 2, 2, "S$"
	call Pop2OPS
	call SetSymbolVariable
	jp ReturnVoid


;; DEFINE:
;;
;; DEFINE word list
;;
;; Define a procedure called :word.  The first element of :list must
;; be a list of words, which are the names of the procedure's inputs.
;; The remaining elements of :list make up the procedure's body.

p_DEFINE:
	BUILTIN_PRIMITIVE 2, 2, 2, "Sn$"
	call Pop2OPS
	call SetSymbolProcedure
	jp ReturnVoid
 warning "FIXME: needs more error checking"
