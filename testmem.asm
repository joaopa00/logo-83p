 processor z80
 nolist
 include <ti83plus.inc>
 list

 include "defs.inc"

 org userMem-2
 db t2ByteTok, tasmCmp

	xor a
	jr nc,Start
	;; UNREACHABLE
	db "Test",0

Start:
	BCALL _RunIndicOff
	res appTextSave,(iy+appFlags)
	call OpenWorkspace
Loop:
	BCALL _ClrLCDFull
	ld hl,0
	ld (curRow),hl

	ld hl,(uninitNodeStart)
	ld de,(userNodeStartMinus2)
	inc de
	inc de
	or a
	sbc hl,de
	ld b,h
	ld c,l

	ld hl,8002h
RedrawLoop:
	call GetType
	push hl
	 ld hl,TypeCharTable
	 ld e,a
	 ld d,0
	 add hl,de
	 ld a,(hl)
	 BCALL _PutC
	 pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	dec bc
	dec bc
	dec bc
	dec bc
	ld a,b
	or c
	jr nz,RedrawLoop

KeyLoop:
	BCALL _GetKey
	cp kClear
	ret z
	cp kCapL
	jr z,AllocSomething
	cp kCapF
	jr z,FreeSomething
	jr KeyLoop

AllocSomething:
	ld hl,8002h
	ld de,8002h
	call CreateList
Proceed:
	call SaveWorkspace
	jr Loop

FreeSomething:
	BCALL _RunIndicOn
	BCALL _GetKey
	push af
	 BCALL _RunIndicOff
	 pop af
	sub k0
	jr c,KeyLoop
	cp 10
	jr nc,KeyLoop
	inc a
	add a,a
	add a,a
	add a,2
	ld l,a
	ld h,80h
	call FreeNode
	jr Proceed

TypeCharTable:
	db "?.?V?L?EA?O?????"
	db "SCsq?:???c?r?i??"
	db "????????????????"
	db "????????????????"

builtinNodeStart:
	;; ...

 include "mem.asm"
 include "nodes.asm"
 include "types.asm"
 include "list.asm"
 include "data.asm"
