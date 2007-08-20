;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; File I/O
;;;


;; SetReadFileTIOS:
;;
;; Start reading input from the named file.
;;
;; Input:
;; - OP1 = file name
;; - HL = initial offset into file
;;
;; Output:
;; - CF set if error
;;
;; Destroys:
;; - AF, BC, DE, HL

SetReadFileTIOS:
	ld (fileReadOffset),hl
	BCALL _ChkFindSym
	ret c
	ex de,hl
	ld a,b
	or a
	jr z,SetReadFileTIOS_RAM
	ld de,9			; skip 3 bytes archive header + 6
				; bytes VAT entry
	call Add_BHL_DE
	call Load_A_iBHL
	add a,3			; skip name length byte + name + 2
				; bytes file length
	ld e,a
	call Add_BHL_DE

	push bc
	 push hl

	  ld a,b
	  ld de,NFBuffer
	  ld bc,24
	  BCALL _FlashToRam
SetReadFileTIOS_Setup:
	;; Check magic bytes
	  ld hl,(NFBuffer)
	  ld bc,47F3h
	  or a
	  sbc hl,bc
	  jr nz,SetReadFileTIOS_NotNotefolio
	  ld hl,(NFBuffer+2)
	  ld bc,0AFBFh
	  or a
	  sbc hl,bc
	  jr nz,SetReadFileTIOS_NotNotefolio
	;; Get length of text section
	  ld hl,(NFBuffer+16)
	  ld bc,-24
	  add hl,bc
	  ld (fileReadSize),hl
	  pop hl
	 pop bc
	ld de,24
	call Add_BHL_DE
	ld (fileReadStartMPtr),hl
	ld a,b
	ld (fileReadPage),a
	
	ld hl,GetChar_FileReadTIOS
	ld (getCharFunc),hl
	ld hl,GetS_FileReadTIOS
	ld (getSFunc),hl
	or a
	ret

SetReadFileTIOS_NotNotefolio:
	  pop hl
	 pop bc
	scf
	ret

SetReadFileTIOS_RAM:
	inc hl
	inc hl
	xor a
	push af
	 push hl
	  ld de,NFBuffer
	  ld bc,24
	  ldir
	  jr SetReadFileTIOS_Setup


;; GetChar_FileReadTIOS:
;;
;; Get the next character from the input file.
;;
;; Output:
;; - A = character
;;
;; Destroys:
;; - F, BC, DE

GetChar_FileReadTIOS:
	push hl
	 ld hl,(fileReadOffset)
	 ld de,(fileReadSize)
	 or a
	 sbc hl,de
	 jr nc,GetChar_FileReadTIOS_EOF
	 add hl,de
	 inc hl
	 ld (fileReadOffset),hl
	 dec hl
	 ex de,hl
	 ld hl,(fileReadStartMPtr)
	 ld a,(fileReadPage)
	 ld b,a
	 call Add_BHL_DE
	 call Load_A_iBHL
	 pop hl
	cp 0F1h
	ret nz
	ld a,' '
	ret
GetChar_FileReadTIOS_EOF:
	 pop hl
	xor a
	ret


;; GetS_FileReadTIOS:
;;
;; Get the next line from the input file.
;;
;; Input:
;; - HL = address of text buffer
;; - BC = size of buffer
;;
;; Output:
;; - HL = address of zero-terminated string
;; - CF set on EOF
;;
;; Destroys:
;; - AF, BC, DE, HL

GetS_FileReadTIOS:
	push hl
GetS_FileReadTIOS_Loop:
	 call GetChar_FileReadTIOS
	 cp Lenter
	 jr z,GetS_FileReadTIOS_Enter
	 or a
	 jr z,GetS_FileReadTIOS_EOF
	 ld (hl),a
	 inc hl
	 dec bc
	 ld a,b
	 or c
	 jr nz,GetS_FileReadTIOS_Loop
	 dec hl
	 ld (hl),0
	 ld hl,(fileReadOffset)
	 dec hl
	 ld (fileReadOffset),hl
	 pop hl
	ret
GetS_FileReadTIOS_Enter:
	 ld (hl),0
	 pop hl
	ret
GetS_FileReadTIOS_EOF:
	 ld (hl),0
	 pop de
	sbc hl,de
	ex de,hl
	ret nz
	scf
	ret


Add_BHL_DE:
	bit 7,h
	add hl,de
	ret nz
	jr c,Add_BHL_DE_MustFlip
	bit 7,h
	ret z
Add_BHL_DE_MustFlip:
	push af
	 ld a,h
Add_BHL_DE_FlipLoop:
	 sub 40h
	 inc b
	 cp 80h
	 jr nc,Add_BHL_DE_FlipLoop
	 cp 40h
	 jr c,Add_BHL_DE_FlipLoop
	 ld h,a
	 pop af
	ret


Inc_BHL:
	bit 7,h
	inc hl
	ret nz
	bit 7,h
	ret z
	res 7,h
	set 6,h
	inc b
	ret


Load_A_iBHL:
	ld a,b
	BCALL _LoadAIndPaged
	ret
