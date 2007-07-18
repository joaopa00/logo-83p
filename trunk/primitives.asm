;;; -*- TI-Asm -*-

p_SUM:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	ex de,hl
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	add hl,de
	bit 7,h
	ret z
ErrOverflow:
	BCALL _ErrOverflow
	;; UNREACHABLE
ErrDataType:
	BCALL _ErrDataType
	;; UNREACHABLE

p_DIFFERENCE:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	ex de,hl
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	or a
	sbc hl,de
	jr c,ErrOverflow
	ret

p_PRODUCT:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	ex de,hl
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
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

p_QUOTIENT:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	ld a,h
	or l
	jr z,ErrDivBy0
	ex de,hl
	call PopOPS
	bit 7,h
	jr nz,ErrDataType
	BCALL _DivHLByDE
	ex de,hl
	ret
ErrDivBy0:
	BCALL _ErrDivBy0
	;; UNREACHABLE

p_FPUT:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	call IsList
	jp c,ErrDataType
	ex de,hl
	call PopOPS
	jp NewList

p_FIRST:
	db 0, 1, 1, 1, 0, 0
	call PopOPS
	call IsList
	jp c,ErrDataType
	jp GetListFirst

p_BUTFIRST:
	db 0, 1, 1, 1, 0, 0
	call PopOPS
	call IsList
	jp c,ErrDataType
	jp GetListButfirst

p_COUNT:
	db 0, 1, 1, 1, 0, 0
	call PopOPS
	call IsList
	ld de,0
	jr nc,COUNT_List
	call IsWord
	jp c,ErrDataType
	jp GetWordSize
COUNT_List:
	jr z,COUNT_ListDone
	inc de
	call GetListButfirst
	call IsList
	jr nc,COUNT_List
	jp ErrDataType
COUNT_ListDone:
	ex de,hl
	ret

p_ITEM:
	db 0, 2, 2, 2, 0, 0
	call PopOPS
	ex de,hl
	call PopOPS
	bit 7,h
	jp nz,ErrDataType
	ld a,h
	or l
	jr z,ErrDimension
	dec hl
	ex de,hl
	call IsList
	jr nc,itemList
	call IsWord
	jp c,ErrDataType
	call GetWordChar
	jp NewChar
itemList:
	jr z,ErrDimension
	ld a,d
	or e
	jr z,itemListDone
	call GetListButfirst
	dec de
	call IsList
	jr nc,itemList
	jp ErrDataType
itemListDone:
	jp GetListFirst

ErrDimension:
	BCALL _ErrDimension
	;; UNREACHABLE

