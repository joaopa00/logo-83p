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

	ld hl,7
	ld (curRow),hl

	ld hl,(selectedNode)
	call IsWord
	jr c,NotWord
	push hl
	 call GetWordSize
	 ld b,h
	 ld c,l
	 pop hl

	ld a,Lquote
	BCALL _PutC
	ld a,Lbar
	BCALL _PutC
	ld de,0
DispWordLoop:
	ld a,b
	or c
	jr z,DispWordDone
	push bc
	 push de
	  push hl
	   call GetWordChar
	   BCALL _PutC
	   pop hl
	  pop de
	 pop bc
	inc de
	dec bc
	jr DispWordLoop
DispWordDone:
	ld a,Lbar
	BCALL _PutC
	jr KeyLoop

NotWord:
	call IsList
	jr c,NotList
	jr z,NotList

	ld a,LlBrack
	BCALL _PutC
	push hl
	 call GetListFirst
	 bit 7,h
	 jr z,FirstIsInt
	 res 7,h
	 srl h
	 rr l
	 srl h
	 rr l
	 ld a,'#'
	 BCALL _PutC
FirstIsInt:
	 BCALL _DispHL
	 ld a,Lperiod
	 BCALL _PutC
	 pop hl
	call GetListButfirst
	res 7,h
	srl h
	rr l
	srl h
	rr l
	ld a,'#'
	BCALL _PutC
	BCALL _DispHL
	ld a,LrBrack
	BCALL _PutC
	jr KeyLoop

NotList:
	ld de,(userNodeStartMinus2)
	inc de
	inc de
	ld hl,(appvarStart)
	ld bc,savedDataSize+5
	add hl,bc
	ex de,hl
	sbc hl,de
	BCALL _DispHL

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
	cp kCapP
	jr z,ParseSomething
	cp kCapF
	jr z,FreeSomething
	cp kCapG
	jr z,RunGC
	jr KeyLoop
	
Left:	ld hl,(selectedNode)
	ld de,-4
	add hl,de
	ld (selectedNode),hl
	jp Loop	

Right:	ld hl,(selectedNode)
	ld de,4
	add hl,de
	ld (selectedNode),hl
	jp Loop	

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

ParseSomething:
	call GetS
	push hl
	 BCALL _StrLength
	 pop hl
	call ParseBuffer
	ld (selectedNode),hl
	jr Proceed

FreeSomething:
	ld hl,(selectedNode)
	call GetType
	cp T_FREE
	jr z,Proceed
	cp T_VOID
	jr z,Proceed
	cp T_EMPTY
	jr z,Proceed
	cp T_SYMBOL
	jr z,Proceed
	cp T_INT
	jr z,Proceed

	push hl
	 call RefToPointer
	 ld a,(hl)
	 pop hl
	and 7
	jr nz,FreeOnlyNode
	call FreeObject
	jr Proceed

FreeOnlyNode:
	call FreeNode
	jr Proceed

RunGC:
	ld hl,(selectedNode)
	push hl
	 call GCQuick
	 pop hl
	jr Proceed

GetS:
	ld hl,7
	ld (curRow),hl
	BCALL _EraseEOL
	ld hl,appBackUpScreen
GetS_Loop:
	push hl
	 BCALL _CursorOn
	 res onInterrupt,(iy+onFlags)
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

 include "logocore.asm"
