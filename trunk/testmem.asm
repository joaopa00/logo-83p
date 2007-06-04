 processor z80
 nolist
 include <ti83plus.inc>
 list

 include "defs.inc"

 org userMem-2
 db t2ByteTok, tasmCmp

	BCALL _RunIndicOff
	call OpenWorkspace
	ld hl,8002h
	ld (selectedNode),hl
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
	 ld de,(selectedNode)
	 or a
	 sbc hl,de
	 jr nz,Redraw_NotSelected
	 set textInverse,(iy+textFlags)
Redraw_NotSelected:

	 ld hl,TypeCharTable
	 ld e,a
	 ld d,0
	 add hl,de
	 ld a,(hl)
	 BCALL _PutC
	 res textInverse,(iy+textFlags)
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
	cp kLeft
	jr z,Left
	cp kRight
	jr z,Right
	cp kCapL
	jr z,AllocAList
	cp kCapS
	jr z,AllocAString
	cp kCapF
	jr z,FreeSomething
	jr KeyLoop
	
Left:	ld hl,(selectedNode)
	ld de,-4
	add hl,de
	ld (selectedNode),hl
	jr Loop	

Right:	ld hl,(selectedNode)
	ld de,4
	add hl,de
	ld (selectedNode),hl
	jr Loop	

AllocAList:
	ld hl,(selectedNode)
	ld de,8002h
	call NewList
	ld (selectedNode),hl
Proceed:
	call SaveWorkspace
	jp Loop

AllocAString:
	call GetS
	push hl
	 BCALL _StrLength
	 call NewString
	 ld (selectedNode),hl
	 pop hl
	ldir
	jr Proceed

FreeSomething:
	ld hl,(selectedNode)
	call FreeNode
	jr Proceed

GetS:
	ld hl,7
	ld (curRow),hl
	BCALL _EraseEOL
	ld hl,appBackUpScreen
GetS_Loop:
	push hl
	 BCALL _CursorOn
	 BCALL _GetKey
	 push af
	  BCALL _CursorOff
	  pop af
	 pop hl
	cp kLeft
	jr z,GetS_Del
	cp kEnter
	jr z,GetS_Done
	cp EchoStart
	jr c,GetS_Loop
	ld e,a
	cp 0FCh
	jr c,GetS_1B
	ld d,a
	ld a,(keyExtend)
	ld e,a
GetS_1B:
	push hl
	 BCALL _KeyToString
	 inc hl
	 ld a,(hl)
	 pop hl
	ld (hl),a
	inc hl
	BCALL _PutC
	jr GetS_Loop

GetS_Del:
	dec hl
	ld a,(curCol)
	dec a
	ld (curCol),a
	ld a,' '
	BCALL _PutMap
	jr GetS_Loop

GetS_Done:
	ld (hl),0
	ld hl,appBackUpScreen
	ret


TypeCharTable:
	db "?.?V?L?EA?O?????"
	db "SCsq?:???c?r?i??"
	db "????????????????"
	db "????????????????"


selectedNode:	dw 0

 include "mem.asm"
 include "nodes.asm"
 include "types.asm"
 include "list.asm"
 include "objects.asm"
 include "word.asm"
 include "data.asm"
