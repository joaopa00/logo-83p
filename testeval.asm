;;; -*- TI-Asm -*-

 processor z80
 nolist
 include <ti83plus.inc>
 list

 include "defs.inc"

 org userMem-2
 db t2ByteTok, tasmCmp

	BCALL _RunIndicOff
	call OpenWorkspace
	ld hl,ErrH
	call APP_PUSH_ERRORH

Loop:	call GetS
	jr c,Quit
	push hl
	 BCALL _RunIndicOn
	 BCALL _NewLine
	 pop hl
	push hl
	 BCALL _StrLength
	 pop hl
	call ParseBuffer
	call EvalMain
	push hl
	 BCALL _RunIndicOff
	 pop hl
	call Display
	BCALL _NewLine
	jr Loop

Quit:	call SaveWorkspace
	call APP_POP_ERRORH
	ret

ErrH:	call SaveWorkspace
	ld a,(errNo)
	and 7Fh
	BCALL _JError
	;; UNREACHABLE

GetS:	ld hl,appBackUpScreen
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
	cp kDel
	jr z,GetS_Del
	cp kEnter
	jr z,GetS_Done
	cp kQuit
	scf
	ret z
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
GetS_Done:
	ld (hl),0
	ld hl,appBackUpScreen
	ret
	
GetS_Del:
	ld a,(curCol)
	or a
	jr z,GetS_Del_LeftEdge
	dec a
GetS_Del_Done:
	dec hl
	ld (curCol),a
	ld a,' '
	BCALL _PutMap
	jr GetS_Loop
GetS_Del_LeftEdge:
	ld a,h
	cp high(appBackUpScreen)
	jr nz,GetS_Del_LeftEdge_OK
	ld a,l
	cp low(appBackUpScreen)
	jr z,GetS_Loop
GetS_Del_LeftEdge_OK:
	ld a,(curRow)
	or a
	jr z,GetS_Del_TopLeft
	dec a
	ld (curRow),a
GetS_Del_LeftEdge_Done:
	ld a,15
	jr GetS_Del_Done
GetS_Del_TopLeft:
	ld (hl),0
	ld bc,-16
	add hl,bc
	BCALL _PutS
	jr GetS_Del_LeftEdge_Done

Display:
	ld bc,0			; indentation level
Display_Indented:
	call IsList
	jr c,Display_NotList
	push af
	 ld a,LlBrack
	 BCALL _PutC
	 pop af
	jr z,Display_ListEmpty
	inc b
Display_ListLoop:
	push hl
	 call GetListFirst
	 call Display_Indented
	 pop hl	
	call GetListButfirst
	call IsList
	jr z,Display_ListDone
	call DisplayIndent
	jr Display_ListLoop
Display_ListDone:
	dec b
Display_ListEmpty:
	ld a,LrBrack
	BCALL _PutC
	ret

Display_NotList:
	call IsWord
	jr c,Display_NotListOrWord
	push bc
	 push hl
	  call GetWordSize
	  ld b,h
	  ld c,l
	  pop hl
	 ld de,0
Display_WordLoop:
	 ld a,b
	 or c
	 jr z,Display_WordDone
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
	 jr Display_WordLoop
Display_WordDone:
	 pop bc
	ret

Display_NotListOrWord:
	ld a,'?'
	BCALL _PutC
	ret

DisplayIndent:
	ld a,c
	inc a
	and 7
	ld c,a
	jr nz,DisplayIndent_NoPause
	push bc
	 push hl
	  BCALL _RunIndicOn
	  ld a,busyPause
	  ld (indicBusy),a
	  BCALL _GetKey
	  BCALL _RunIndicOff
	  pop hl
	 pop bc
DisplayIndent_NoPause:
	BCALL _NewLine
	ld a,b
	or a
	ret z
	push bc
DisplayIndentLoop:
	 ld a,' '
	 BCALL _PutC
	 djnz DisplayIndentLoop
	 pop bc
	ret

 include "logocore.asm"
