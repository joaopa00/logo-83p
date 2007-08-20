;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Text I/O
;;;


;; Print:
;;
;; Display a Logo value, leaving off brackets if it is a list.  (Note
;; that unlike the primitive PRINT, this does not move to the next
;; line afterwards.)
;;
;; Input:
;; - HL = value to display
;;
;; Destroys:
;; - AF, BC, DE, HL

Print:
	call IsList
	jr c,Show
	ret z
Print_Loop:
	call GetListFirstButfirst
	push de
	 call Show
	 pop hl
	call IsList
	jr c,Print_ButfirstNotList
	ret z
	ld a,Lspace
	call PutC
	jr Print_Loop

Print_ButfirstNotList:
	ld a,Lspace
	call PutC
	ld a,Lperiod
	call PutC
	ld a,Lspace
	call PutC
	;; fall through


;; Show:
;;
;; Display a Logo value.  (Note that unlike the primitive SHOW, this
;; does not move to the next line afterwards.)
;;
;; Input:
;; - HL = value to display
;;
;; Destroys:
;; - AF, BC, DE, HL

Show:
	push hl
	 ld hl,0
	 call PushOPS
	 pop hl
Show_Loop:
	call IsList
	jr c,Show_NotList
	jr z,Show_ListEmpty
	ld a,LlBrack
	call PutC
Show_Next:
	call PushOPS
	call GetListFirst
	jr Show_Loop

Show_NotList:
	call IsWord
	jr c,Show_NotListOrWord
	ld de,0
Show_WordLoop:
	push hl
	 push de
	  call GetWordChar
	  pop de
	 pop hl
	jr c,Show_WordDone
	call PutC
	inc de
	jr Show_WordLoop
Show_NotListOrWord:
	ld a,Lquestion
	call PutC
Show_WordDone:
	call PopOPS
	ld a,h
	or l
	ret z
	call GetListButfirst
	call IsList
	jr c,Show_ButfirstNotList
	jr z,Show_EndOfList
	ld a,Lspace
	call PutC
	jr Show_Next

Show_ButfirstNotList:
	ld a,Lspace
	call PutC
	ld a,Lperiod
	call PutC
	ld a,Lspace
	call PutC
	call Show		; since it's not a list, this is safe
				; (at least until we have arrays)
	jr Show_EndOfList

Show_ListEmpty:
	ld a,LlBrack
	call PutC
Show_EndOfList:
	ld a,LrBrack
	call PutC
	jr Show_WordDone


;; PutC:
;;
;; Display a character.  Note this has slightly different semantics
;; than TI's PutC routine.
;;
;; Input:
;; - A = character
;;
;; Destroys:
;; - None

PutC:
	push af
	 cp Lenter
	 jr z,NewLine1
	 push de
	  push ix
	   ld d,a
	   ld a,(curCol)
	   cp 16
	   jr c,PutC_ColumnOK
	   BCALL _NewLine
PutC_ColumnOK:
	   ld a,d
	   BCALL _PutMap
	   ld a,(curCol)
	   inc a
	   ld (curCol),a
	   pop ix
	  pop de
	 pop af
	ret


;; NewLine:
;;
;; Move to the next line.
;;
;; Destroys:
;; - None

NewLine1:
	 pop af
NewLine:
	BCALL _NewLine
	ret


;; PutS:
;;
;; Display a zero-terminated string.
;;
;; Input:
;; - HL -> string
;;
;; Output:
;; - HL -> byte following string
;;
;; Destroys:
;; - AF

PutS:
PutS_Console:
	ld a,(hl)
	inc hl
	or a
	ret z
	call PutC
	jr PutS


;; ClearScreen:
;;
;; Clear the screen.
;;
;; Destroys:
;; - None

ClearScreen:
	push af
	 push bc
	  push de
	   push hl
	    BCALL _ClrScrn
	    BCALL _HomeUp
	    pop hl
	   pop de
	  pop bc
	 pop af
	ret


;; SetReadConsole:
;;
;; Start reading input from the console.
;;
;; Destroys:
;; - HL

SetReadConsole:
	ld hl,GetChar_Console
	ld (getCharFunc),hl
	ld hl,GetS_Console
	ld (getSFunc),hl
	ret


;; GetS:
;;
;; Get a string from the current read stream.
;;
;; Input:
;; - HL = address of text buffer
;; - BC = size of buffer
;;
;; Output:
;; - HL = address of zero-terminated string
;; - CF set if user requested abort
;;
;; Destroys:
;; - AF, BC, DE, HL

GetS:
	ld de,(getSFunc)
	push de			; SETRETURN
	ret


;; GetS_Console:
;;
;; Get a string from the user.  If characters have already been
;; printed on this line, they form the prompt.  Note that the buffer
;; must be large enough to hold the prompt string, if any; and thus
;; the output string may not end up being placed at the start of the
;; buffer.
;;
;; Input:
;; - HL = address of text buffer
;; - BC = size of buffer
;;
;; Output:
;; - HL = address of zero-terminated string
;; - CF set if user requested abort
;;
;; Destroys:
;; - AF, BC, DE, HL

GetS_Console:
	;; Copy prompt string into buffer
	ld a,(curCol)
	or a
	jr z,GetS_Console_NoPrompt
	cp 16
	jr c,GetS_Console_CopyPrompt
	BCALL _NewLine
	jr GetS_Console_NoPrompt
GetS_Console_CopyPrompt:
	push hl
	 ld d,a
	 ld a,(curRow)
	 add a,a
	 add a,a
	 add a,a
	 add a,a
	 ld e,a
	 ld a,d
	 ld d,0
	 ld hl,textShadow
	 add hl,de
	 pop de
GetS_Console_CopyPromptLoop:
	ldi
	dec a
	jr nz,GetS_Console_CopyPromptLoop
	ex de,hl
GetS_Console_NoPrompt:
	ld (getSBuffer),hl
	add hl,bc
	ld (getSBufferEnd),hl
	sbc hl,bc
	ld a,(curCol)
	cp 16
	jr c,GetS_Console_Loop
	BCALL _NewLine
GetS_Console_Loop:
	call GetChar_Console
	cp Ldelete
	jr z,GetS_Console_Del
	cp Lenter
	jr z,GetS_Console_Done
	or a
	jr z,GetS_Console_Quit
	ld de,(getSBufferEnd)
	sbc hl,de
	add hl,de
	jr z,GetS_Console_Loop
	ld (hl),a
	inc hl
	BCALL _PutC
	jr GetS_Console_Loop
GetS_Console_Quit:
	scf
GetS_Console_Done:
	ld (hl),0
	ld hl,(getSBuffer)
	ret

GetS_Console_Del:
	ld de,(getSBuffer)
	or a
	sbc hl,de
	add hl,de
	jr z,GetS_Console_Loop
GetS_Console_Del_OK:
	ld a,(curCol)
	or a
	jr z,GetS_Console_Del_LeftEdge
	dec a
GetS_Console_Del_Done:
	dec hl
	ld (curCol),a
	ld a,' '
	BCALL _PutMap
	jr GetS_Console_Loop
GetS_Console_Del_LeftEdge:
	ld a,(winTop)
	ld b,a
	ld a,(curRow)
	cp b
	jr z,GetS_Console_Del_TopLeft
	dec a
	ld (curRow),a
GetS_Console_Del_LeftEdge_Done:
	ld a,15
	jr GetS_Console_Del_Done
GetS_Console_Del_TopLeft:
	dec hl
	ld (hl),0
	ld bc,-15
	add hl,bc
	BCALL _PutS
	jr GetS_Console_Del_LeftEdge_Done


;; GetChar:
;;
;; Read a character from the current read stream.
;;
;; Output:
;; - A = character
;;
;; Destroys:
;; - F, BC, DE

GetChar:
	ld hl,(getCharFunc)
	jp (hl)


;; GetChar_Console:
;;
;; Read a character from the user.
;;
;; Output:
;; - A = character
;;
;; Destroys:
;; - F, BC, DE

GetChar_Console:
	push hl
	 ld a,(curCol)
	 cp 16
	 jr c,GetChar_Console_Loop
	 BCALL _NewLine
GetChar_Console_Loop:
	 call CheckOnInterrupt
	 BCALL _CursorOn
	 BCALL _GetKey
	 push af
	  BCALL _CursorOff
	  pop af
	 cp kQuit
	 jr z,GetChar_Console_Exit
	 cp kLeft
	 jr z,GetChar_Console_Delete
	 cp kDel
	 jr z,GetChar_Console_Delete
	 call KeyToChar
	 jr c,GetChar_Console_Loop
	 pop hl
	ret
GetChar_Console_Exit:
	 pop hl
	xor a
	ret
GetChar_Console_Delete:
	 pop hl
	ld a,Ldelete
	ret


;; KeyToChar:
;;
;; Convert GetKey value into a character.
;;
;; Input:
;; - A = primary keycode
;; - (keyExtend) = extended keycode
;;
;; Output:
;; - CF set if key does not have a character value assigned
;; - A = character value
;;
;; Destroys:
;; - BC, DE

KeyToChar:
	cp kEnter
	jr z,KeyToChar_Enter
	cp kCONSTeA		; 2nd + / = backslash
	jr z,KeyToChar_Backslash
	cp kPi			; 2nd + ^ = vertical bar
	jr z,KeyToChar_VBar

	cp EchoStart
	ret c

	ld e,a
	ld d,0
	cp 0FCh
	jr c,KeyToChar_1B
	ld d,a
	ld a,(keyExtend)
	ld e,a
KeyToChar_1B:
	push hl
	 BCALL _KeyToString
	 ld a,(hl)
	 inc hl
	 ld b,(hl)
	 pop hl
	dec a
	ld a,b
	ret z
	scf
	ret

KeyToChar_Enter:
	ld a,Lenter
	ret

KeyToChar_Backslash:
	ld a,Lbackslash
	ret

KeyToChar_VBar:
	ld a,Lbar
	ret


;; CheckOnInterrupt:
;;
;; Check if the On key has been pressed (and thus the program should
;; be aborted.)
;;
;; Destroys:
;; - F

CheckOnInterrupt:
	bit onInterrupt,(iy+onFlags)
	ret z
ErrBreak:
	BCALL _ErrBreak
	;; UNREACHABLE

