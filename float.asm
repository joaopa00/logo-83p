;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Floating-point Routines
;;;

;; NewReal:
;;
;; Create a new real number.
;;
;; Input:
;; - OP1 = TI-format floating-point number
;;
;; Output:
;; - HL = Logo value
;;
;; Destroys:
;; - AF, BC, DE, HL

NewReal:
	call AllocNodePair
	push de
	 ex de,hl
	 ld hl,OP1+8
	 ld a,(OP1)
	 call FPToReal
	 pop hl
	ret


FPToReal:
	and 80h
	push af
	 call FPToReal_FirstByte
	 adc a,a
	 ld (de),a

	 ld a,(currentGCFlag)
	 ld b,a
	 call FPToReal_Byte
	 or b
	 ld (de),a

	 call FPToReal_Byte
	 ld (de),a

	 call FPToReal_Byte
	 ld c,a
	 pop af
	or c
	ld (de),a

	call FPToReal_Byte
	adc a,a
	ld (de),a

	call FPToReal_Byte
	or b
	ld (de),a

	call FPToReal_Byte
	ld (de),a
	inc de
	ld a,(hl)
	ld (de),a
	ret

FPToReal_Byte:
	;; convert one byte BCD->binary
	;; note this will always return with carry set
	inc de
FPToReal_FirstByte:
	ld a,(hl)
	and 0F0h
	rrca
	rrca
	ld c,a
	rrca
	add a,c			; A = MSB * 6
	scf
	sbc a,(hl)		; A = (MSB * 6) - X - 1 (this will always carry)
	cpl			; A = X - (MSB * 6)
	dec hl
	ret
