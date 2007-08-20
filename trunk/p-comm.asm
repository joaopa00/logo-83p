;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Communication Primitives: Transmitters
;;;


;; PRINT:
;;
;; PRINT thing
;; PR thing
;;
;; Display :thing in the command window, and move to the next line.
;; If the input is a list, display the elements of the list (but do
;; not display brackets around them.)

p_PRINT:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call Print
	call NewLine
	jp ReturnVoid


;; TYPE:
;;
;; TYPE thing
;;
;; Display :thing in the command window (like PRINT) but do not move
;; to the next line.  You can use this to print several things on one
;; line, or to display a prompt when requesting input from the user.

p_TYPE:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call Print
	jp ReturnVoid


;; SHOW:
;;
;; SHOW thing
;;
;; Display :thing in the command window, and move to the next line. If
;; the input is a list, display brackets around it.

p_SHOW:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call Show
	call NewLine
	jp ReturnVoid


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Communication Primitives: Receivers
;;;


;; READRAWLINE:
;;
;; READRAWLINE
;;
;; Read a line of text from the user, without interpreting any special
;; characters, and output it as a word.

p_READRAWLINE:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	BCALL _RunIndicOff
	ld hl,appBackUpScreen
	ld bc,768
	call GetS
	call NewLine
	BCALL _RunIndicOn
	push hl
	 BCALL _StrLength
	 call NewString
	 ex (sp),hl
	 ldir
	 pop hl
	ret


;; READCHAR:
;;
;; READCHAR
;; RC
;;
;; Read a single character from the user and output it as a word.

p_READCHAR:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	BCALL _RunIndicOff
	call GetChar
	BCALL _RunIndicOn
	jp NewChar


;; READLIST:
;;
;; READLIST
;; RL
;;
;; Read a line of text from the user and output it as a list.

p_READLIST:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	BCALL _RunIndicOff
	ld hl,appBackUpScreen
	ld bc,768
	call GetS
	BCALL _RunIndicOn
	call NewLine
	BCALL _StrLength
	jp ParseUserInput


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Communication Primitives: Terminal Control
;;;


;; CLEARTEXT:
;;
;; CLEARTEXT
;; CT
;;
;; Clear the command window.

p_CLEARTEXT:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	call ClearScreen
	jp ReturnVoid


;; SETCURSOR:
;;
;; SETCURSOR list
;;
;; Move the text cursor to the coordinates given in the input list
;; (first element is the X coordinate, second is the Y coordinate.)
;; Cursor coordinates start with [0 0] being the top left corner of
;; the command window.

p_SETCURSOR:
	BUILTIN_PRIMITIVE 1, 1, 1, "n$"
	call PopOPS
	push hl
	 call GetListFirstButfirst
	 ld a,h
	 or a
	 jr nz,SETCURSOR_Error
	 ld a,l
	 cp 16
	 jr nc,SETCURSOR_Error
	 ld c,a
	 ex de,hl
	 call IsList
	 jr c,SETCURSOR_Error
	 jr z,SETCURSOR_Error
	 call GetListFirstButfirst
	 ld a,d
	 cp high(emptyNode)
	 jr nz,SETCURSOR_Error
	 ld a,e
	 cp low(emptyNode)
	 jr nz,SETCURSOR_Error
	 ld a,(winBtm)
	 ld b,a
	 ld a,(winTop)
	 add a,l
	 jr c,SETCURSOR_Error
	 cp b
	 jr nc,SETCURSOR_Error
	 ld (curRow),a
	 ld a,c
	 ld (curCol),a
	 pop hl
	jp ReturnVoid
SETCURSOR_Error:
	 pop de
	jp ThrowBadInputError


;; CURSOR:
;;
;; CURSOR
;;
;; Get the current position of the text cursor as a list of two
;; numbers (X and Y, with [0 0] being the top left corner of the
;; command window.)

p_CURSOR:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	ld a,(winTop)
	ld b,a
	ld a,(curRow)
	sub b
	ld l,a
	ld h,0
	ld de,emptyNode
	call NewList
	ex de,hl
	ld a,(curCol)
	ld l,a
	ld h,0
	jp NewList




