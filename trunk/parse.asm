;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsing
;;;


;; ParseUserInput:
;;
;; Parse an input string from the user.  If it is incomplete (contains
;; brackets that are not closed), read additional lines until it is
;; complete.
;;
;; Input:
;; - HL = address of string
;; - BC = length of string
;;
;; Output:
;; - HL = result of parsing
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - appBackUpScreen

ParseUserInput:
	ld de,ParseUserInput_Callback
	jr ParseWithCallback

ParseUserInput_Callback:
	ld a,Lellipsis
	call PutC
	BCALL _RunIndicOff
	ld hl,appBackUpScreen
	ld bc,768
	call GetS
	BCALL _RunIndicOn
	call NewLine
	jr c,ParseUserInput_CallbackError
	BCALL _StrLength
	ret
ParseUserInput_CallbackError:
ParseBuffer_ErrorLBrack:
	ld hl,EMsg_TooManyLBracks
	ld a,E_Syntax
	jp ThrowError


;; ParseFileInput:
;;
;; Parse an input string read from a file.  If it is incomplete, read
;; additional lines until it is complete.
;;
;; Input:
;; - HL = address of string
;; - BC = length of string
;;
;; Output:
;; - HL = result of parsing
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - appBackUpScreen

ParseFileInput:
	ld de,ParseFileInput_Callback
	jr ParseWithCallback

ParseFileInput_Callback:
	ld hl,appBackUpScreen
	ld bc,768
	call GetS_FileReadTIOS
	jr c,ParseBuffer_ErrorLBrack
	BCALL _StrLength
	ret


;; ParseBuffer:
;;
;; Parse a text string stored in RAM.
;;
;; Input:
;; - HL = address of string
;; - BC = length of string
;;
;; Output:
;; - HL = result of parsing
;;
;; Destroys:
;; - AF, BC, DE, HL

ParseBuffer:
	ld de,ParseBuffer_ErrorLBrack
ParseWithCallback:
	ld (parseCallback),de
	ld (parseBufferMPtr),hl
	push bc

	 ld hl,emptyNode
	 ld d,h
	 ld e,l
	 call NewList
	 ld (parseParent),hl

	 ld hl,0
	 ld (parseCurrent),hl

ParseBuffer_Loop1:
	 pop bc
	ld hl,(parseBufferMPtr)
ParseBuffer_Loop:
	bit onInterrupt,(iy+onFlags)
	jp nz,ErrBreak
	ld a,b
	or c
	jp z,ParseBuffer_EOF
	ld a,(hl)
	inc hl
	dec bc

	;; Skip whitespace
	cp Lspace
	jr z,ParseBuffer_Loop
	cp Lenter
	jr z,ParseBuffer_Loop

	;; Skip comments
	cp Lsemicolon
	jp z,ParseBuffer_Semicolon

	;; Brackets are special
	cp LlBrack
	jp z,ParseBuffer_LBrack
	cp LrBrack
	jp z,ParseBuffer_RBrack

	;; Except for < and >, all other characters are either word
	;; constituents or single-character tokens

	;; The following assumes we're using ASCII
	cp '?'
	jr nc,ParseBuffer_WC
	cp '('
	jr c,ParseBuffer_WC
	cp '='
	jr z,ParseBuffer_Token
	jr nc,ParseBuffer_GT
	cp '<'
	jr z,ParseBuffer_LT
	cp '0'
	jr nc,ParseBuffer_WC
	cp ','
	jr z,ParseBuffer_WC
	cp '.'
	jr z,ParseBuffer_WC
ParseBuffer_Token:
ParseBuffer_LT:
ParseBuffer_GT:
 WARNING "FIXME: tokens should be builtin, and LT/GT need special handling"
	ld (parseBufferMPtr),hl
	push bc
	 call NewChar
	 jr ParseBuffer_GotWord

ParseBuffer_WC:
	;; We just got the first character of a word.  Now we need to
	;; find out how long it is.

	push hl			; save address of first char + 1
	 ld de,0		; DE = number of characters
	 jr ParseBuffer_WordFirstChar

ParseBuffer_WordVBarBackslash:
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordEOF
	 inc hl
	 dec bc
ParseBuffer_WordVBarLoop:
	 inc de
ParseBuffer_WordVBar:
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordEOF
	 ld a,(hl)
	 inc hl
	 dec bc
	 cp Lbackslash
	 jr z,ParseBuffer_WordVBarBackslash
	 cp Lbar
	 jr nz,ParseBuffer_WordVBarLoop
	 jr ParseBuffer_WordCharNotIncluded

ParseBuffer_WordBackslash:
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordEOF
	 inc hl
	 dec bc
ParseBuffer_WordChar:
	 inc de
ParseBuffer_WordCharNotIncluded:
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordEOF
	 ld a,(hl)
	 inc hl
	 dec bc
ParseBuffer_WordFirstChar:
	 cp Lspace
	 jr z,ParseBuffer_WordDone
	 cp Lenter
	 jr z,ParseBuffer_WordDone
	 cp Lsemicolon
	 jr z,ParseBuffer_WordDone
	 cp LlBrack
	 jr z,ParseBuffer_WordDone
	 cp LrBrack
	 jr z,ParseBuffer_WordDone

	 ;; Backslash -> escape single character
	 cp Lbackslash
	 jr z,ParseBuffer_WordBackslash
	 ;; Vertical bar -> escape a sequence of characters
	 cp Lbar
	 jr z,ParseBuffer_WordVBar

	 ;; ASCII
	 cp '?'
	 jr nc,ParseBuffer_WordChar
	 cp '('
	 jr c,ParseBuffer_WordChar
	 cp '<'
	 jr nc,ParseBuffer_WordDone
	 cp '0'
	 jr nc,ParseBuffer_WordChar
	 cp ','
	 jr z,ParseBuffer_WordChar
	 cp '.'
	 jr z,ParseBuffer_WordChar
ParseBuffer_WordDone:
	;; "unget" the last character we read
	 dec hl
	 inc bc
ParseBuffer_WordEOF:
	 ld (parseBufferMPtr),hl
	 pop hl
	dec hl
	push bc
	 ;; HL = address of first char
	 ;; DE = length of word
	 push hl
	  add hl,de
	  ld bc,(parseBufferMPtr)
	  sbc hl,bc
	  ld a,h
	  or l
	  pop hl
	 call ParseQuotedWord
ParseBuffer_GotWord:
	 ;; HL = value that we want to add onto the end of the current list.
	 ld de,emptyNode
	 call NewList
	 ex de,hl		; DE = new list node

	 ;; Is the current list empty?
	 ld hl,(parseCurrent)
	 ld a,h
	 or l
	 ld (parseCurrent),de
	 jr z,ParseBuffer_FirstInList
	 ;; current list was not empty -> nconc the new node onto the end
	 call SetListButfirst
	 jp ParseBuffer_Loop1

ParseBuffer_FirstInList:
	 ;; current list was empty -> the new node is the entire list
	 ld hl,(parseParent)
	 call SetListFirst
	 jp ParseBuffer_Loop1

ParseBuffer_LBrack:
	;; We just saw a left bracket.  We must begin a new list.
	ld (parseBufferMPtr),hl
	push bc
	 ld hl,emptyNode
	 ld de,(parseParent)
	 call NewList
	 ex de,hl		; DE = new list node (whose first
				; element is the empty list)

	 ;; Is the current list empty?
	 ld hl,(parseCurrent)
	 ld a,h
	 or l
	 jr z,ParseBuffer_FirstSubList
	 ;; current list not empty -> nconc the new node onto the end
	 ld (parseParent),de
	 call SetListButfirst
	 ld hl,0
	 ld (parseCurrent),hl
	 jp ParseBuffer_Loop1

ParseBuffer_FirstSubList:
	 ;; current list empty -> the new node is the entire list
	 ld hl,(parseParent)
	 ld (parseParent),de
	 call SetListFirst
	 ld hl,0
	 ld (parseCurrent),hl
	 jp ParseBuffer_Loop1

ParseBuffer_RBrack:
	ld (parseBufferMPtr),hl
	push bc
	 ld hl,(parseParent)
	 ld (parseCurrent),hl
	 push hl
	  call GetListButfirst
	  ld (parseParent),hl
	  pop hl
	 ld de,emptyNode
	 call SetListButfirst
	 ld hl,(parseParent)
	 ld de,emptyNode
	 or a
	 sbc hl,de
	 jp nz,ParseBuffer_Loop1

	 ld hl,EMsg_UnexpectedRBrack
	 ld a,E_Syntax
	 call ThrowError
	 ;; UNREACHABLE

ParseBuffer_Semicolon:
	ld a,b
	or c
	jr z,ParseBuffer_EOF
	ld a,(hl)
	inc hl
	dec bc
	cp Lenter
	jr nz,ParseBuffer_Semicolon
	jp ParseBuffer_Loop

ParseBuffer_EOF:
	ld hl,(parseParent)
	call GetListFirstButfirst
	push hl
	 ld hl,emptyNode
	 or a
	 sbc hl,de
	 jr nz,ParseBuffer_ReadMore
	 push de
	  ld hl,(parseParent)
	  call FreeNode
	  pop de
	 ld hl,0
	 ld (parseParent),hl	; discard old refs
	 ld (parseCurrent),hl
	 pop hl
	ret

ParseBuffer_ReadMore:
	 pop hl
	ld hl,ParseBuffer_Loop
	push hl
	 ld hl,(parseCallback)
	 jp (hl)


;; ParseQuotedWord:
;;
;; Convert a text string, with optional leading quotes, to a word.
;;
;; Input:
;; - HL = address of first character
;; - DE = length of word
;; - A = 0 to ignore backslash/vertical bar escapes; nonzero to
;;   interpret escapes.
;;
;; Output:
;; - HL = word
;;
;; Destroys:
;; - AF, BC, DE, HL

ParseQuotedWord:
	or a
	ld bc,(parseBufferMPtr)
	sbc hl,bc
	push hl			; save offset to first character
	 add hl,bc
	 push de
	  push af
	   ;; Skip over initial quotes/colons
ParseQuotedWord_InitialQuotesLoop:
	   ld a,d
	   or e
	   jr z,ParseQuotedWord_InitialQuotesDone
	   ld a,(hl)
	   cp Lquote
	   jr z,ParseQuotedWord_InitialQuote
	   cp Lcolon
	   jr nz,ParseQuotedWord_InitialQuotesDone
ParseQuotedWord_InitialQuote:
	   inc hl
	   dec de
	   jr ParseQuotedWord_InitialQuotesLoop
ParseQuotedWord_InitialQuotesDone:
	   ld b,d
	   ld c,e
	   pop af
	  push bc
	   call ParseSimpleWord
	   pop bc
	  ld (newSymbol),hl
	  pop hl		; total length of word
	 or a
	 sbc hl,bc
	 ld b,h
	 ld c,l			; BC = number of initial quoting characters
	 pop hl
	ld de,(parseBufferMPtr)
	add hl,de		; address of start of word
	add hl,bc		; start of word following quotes
	;; Now add quotes to the symbol in reverse order
	dec hl
	ex de,hl
	ld hl,(newSymbol)
	push hl
	 ld hl,0
	 ld (newSymbol),hl
	 pop hl
ParseQuotedWord_AddQuotes:
	ld a,b
	or c
	ret z
	ld a,(de)
	dec de
	dec bc
	cp Lcolon
	jr z,ParseQuotedWord_AddColon
	call NewQuote
	jr ParseQuotedWord_AddQuotes
ParseQuotedWord_AddColon:
	call NewColon
	jr ParseQuotedWord_AddQuotes


;; ParseSimpleWord:
;;
;; Convert a text string to a word, without handling quotes.  If
;; backslashes or vertical bars are included, the result will be a
;; string object.  If not, the result will be either a number or a
;; symbol object.
;;
;; Input:
;; - HL = address of first character
;; - BC = length of word
;; - A = 0 to ignore backslash/vertical bar escapes; nonzero to
;;   interpret escapes.
;;
;; Output:
;; - HL = word
;;
;; Destroys:
;; - AF, BC, DE

ParseSimpleWord:
	or a
	jr nz,ParseSimpleWord_Escaped
	ld a,b
	or c
	jp z,GetNamedSymbol
	push hl
	 push bc
	  ex de,hl
	  ld hl,0
ParseSimpleWord_IntLoop:
	  ld a,b
	  or c
	  jr z,ParseSimpleWord_IntDone
	  push bc
	   ld c,l
	   ld b,h
	   add hl,hl
	   jr c,ParseSimpleWord_IntOverflow1
	   add hl,hl
	   jr c,ParseSimpleWord_IntOverflow1
	   add hl,bc
	   jr c,ParseSimpleWord_IntOverflow1
	   add hl,hl
	   jr c,ParseSimpleWord_IntOverflow1
	   pop bc
	  ld a,(de)
	  inc de
	  dec bc
	  sub L0
	  jr c,ParseSimpleWord_NotInt
	  cp 10
	  jr nc,ParseSimpleWord_NotInt
	  add a,l
	  ld l,a
	  jr nc,ParseSimpleWord_IntLoop
	  inc h
	  jr nz,ParseSimpleWord_IntLoop
	  push af
ParseSimpleWord_IntOverflow1:
	   pop af
ParseSimpleWord_IntOverflow:
ParseSimpleWord_NotInt:
	  pop bc
	 pop hl
	jp GetNamedSymbol

ParseSimpleWord_IntDone:
	  bit 7,h
	  jr nz,ParseSimpleWord_IntOverflow
	  pop af
	 pop af
	ret

ParseSimpleWord_Escaped:
	ld de,(parseBufferMPtr)
	sbc hl,de
	push hl
	 call NewString
	 ex (sp),hl
	 push de
	  ld de,(parseBufferMPtr)
	  add hl,de
	  pop de
	 jr ParseSimpleWord_EscapedLoop

ParseSimpleWord_EscapedCopy:
	 ldi
ParseSimpleWord_EscapedLoop:
	 ld a,b
	 or c
	 jr z,ParseSimpleWord_EscapedDone
	 ld a,(hl)
	 cp Lbar
	 jr z,ParseSimpleWord_EscapedVBar
	 cp Lbackslash
	 jr nz,ParseSimpleWord_EscapedCopy
	 inc hl
	 jr ParseSimpleWord_EscapedCopy

ParseSimpleWord_EscapedVBar:
	 inc hl
	 jr ParseSimpleWord_EscapedLoop

ParseSimpleWord_EscapedDone:
	 pop hl
	ret
