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

Loop:	ld hl,(OPBase)
	ld (minOPS),hl
	ld hl,appBackUpScreen
	ld bc,768
	call GetS_Console
	jr c,Quit
	push hl
	 BCALL _RunIndicOn
	 BCALL _NewLine
	 pop hl
	push hl
	 BCALL _StrLength
	 pop hl
	call ParseUserInput
	call EvalMain
	push hl
	 BCALL _RunIndicOff
	 pop hl
	call Display
	BCALL _NewLine
	ld hl,(OPBase)
	ld de,(OPS)
	or a
	sbc hl,de
	BCALL _DispHL
	ld hl,(OPBase)
	ld de,(minOPS)
	or a
	sbc hl,de
	BCALL _DispHL
	ld hl,(uninitNodeStart)
	ld de,(appvarStart)
	or a
	sbc hl,de
	BCALL _DispHL
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
