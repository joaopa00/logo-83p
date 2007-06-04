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
