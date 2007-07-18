;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Floating-point Routines
;;;

;; NewReal:
;;
;; Create a new real number.
;;
;; Input:
;; - OP1 = TI-format floating-point number (9 bytes)
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
	 call FP9ToReal
	 pop hl
	ret


;; NewComplex:
;;
;; Create a new complex number.
;;
;; Input:
;; - OP1 = TI-format real part (9 bytes)
;; - OP2 = TI-format imaginary part (9 bytes)
;;
;; Output:
;; - HL = Logo value
;;
;; Destroys:
;; - AF, BC, DE, HL

NewComplex:
	call AllocNodeQuad
	push de
	 ex de,hl
	 ld hl,OP1+8
	 ld a,(OP1)
	 call FP9ToReal
	 ld hl,-5
	 add hl,de
	 set 7,(hl)		; mark as complex
	 inc de
	 ld hl,OP2+8
	 ld a,(OP2)
	 call FP9ToReal
	 pop hl
	ret


;; IsReal:
;;
;; Determine if a value is a real number (i.e., floating point, not
;; integer.)
;;
;; Input:
;; - HL = value
;;
;; Output:
;; - CF set if value is not a real number
;;
;; Destroys:
;; - A

IsReal:
	bit 7,h
	scf
	ret z
	push hl
	 call RefToPointer
	 ld a,(hl)
	 rrca
	 ccf
	 jr c,IsReal_Fail
	 inc hl
	 inc hl
	 ld a,(hl)
	 add a,a
IsReal_Fail:
	 pop hl
	ret


;; IsComplex:
;;
;; Determine if a value is a complex number.
;;
;; Input:
;; - HL = value
;;
;; Output:
;; - CF set if value is not a complex number
;;
;; Destroys:
;; - A

IsComplex:
	bit 7,h
	scf
	ret z
	push hl
	 call RefToPointer
	 ld a,(hl)
	 rrca
	 jr c,IsComplex_Fail
	 inc hl
	 inc hl
	 ld a,(hl)
	 add a,a
IsComplex_Fail:
	 ccf
	 pop hl
	ret


;; GetRealToOP2:
;;
;; Retrieve the value of a real number in TI format.
;;
;; Input:
;; - HL = Logo value
;;
;; Output:
;; - OP2 = TI-format floating-point number (9 bytes)
;;
;; Destroys:
;; - AF, BC, DE, HL

GetRealToOP2:
	call IsReal
	jp c,TypeAssertionFailed
GetRealToOP2_nc:
	call RefToPointer
	ex de,hl
	ld bc,OP2+8
	jr RealToFP9


;; GetRealToOP1:
;;
;; Retrieve the value of a real number in TI format.
;;
;; Input:
;; - HL = Logo value
;;
;; Output:
;; - OP1 = TI-format floating-point number (9 bytes)
;;
;; Destroys:
;; - AF, BC, DE, HL

GetRealToOP1:
	call IsReal
	jp c,TypeAssertionFailed
GetRealToOP1_nc:
	call RefToPointer
	ex de,hl
	ld bc,OP1+8
	;; fall through


;; RealToFP9:
;;
;; Convert a floating-point number from Logo format into 9-byte TI
;; format.
;;
;; Input:
;; - DE = address of input
;; - BC = address of LSB of output
;;
;; Output:
;; - DE advanced by 7 bytes
;;
;; Destroys:
;; - AF, BC, HL

RealToFP9:
	ld a,(de)
	rrca
	call RealToFP_Byte

	ld a,(de)
	call RealToFP_Byte

	ld a,(de)
	call RealToFP_Byte

	ld a,(de)
	push af
	 call RealToFP_Byte

	 ld a,(de)
	 rrca
	 call RealToFP_Byte

	 ld a,(de)
	 call RealToFP_Byte

	 ld a,(de)
	 call RealToFP_Byte

	 ld a,(de)
	 ld (bc),a
	 dec bc
	 pop af
	and 80h
	ld (bc),a
	ret

RealToFP_Byte:
	;; convert one byte binary->BCD
	ld h,a
	rrca
	rrca
	rrca
	and 0Fh
	add a,low realToFPTable
	ld l,a
	ld a,h
	ld h,high realToFPTable
	and 7
	add a,(hl)
	daa
	ld (bc),a
	inc de
	dec bc
	ret
	 	
realToFPTable:
	db 00h, 08h, 16h, 24h, 32h, 40h, 48h, 56h
	db 64h, 72h, 80h, 88h, 96h
 NO_BYTE_CARRY realToFPTable


;; FP9ToReal:
;;
;; Convert a floating-point number from 9-byte TI format into Logo
;; format.
;;
;; Input:
;; - HL = address of LSB of input (e.g., OP1+8)
;; - A = sign byte of input (e.g., (OP1))
;; - DE = address to store result
;;
;; Output:
;; - DE advanced by 7 bytes
;;
;; Destroys:
;; - AF, BC, HL

FP9ToReal:
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
