;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsing
;;;


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
	 ld de,1		; DE = number of characters
	 jr ParseBuffer_WordLoop

ParseBuffer_WordVBarLoop:
	 inc de
ParseBuffer_WordVBar:
	 inc hl
	 dec bc
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordDone
	 ld a,(hl)
	 cp Lbar
	 jr nz,ParseBuffer_WordVBarLoop
	 jr ParseBuffer_WordCharNotIncluded

ParseBuffer_WordBackslash:
	 inc hl
	 dec bc
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordDone
ParseBuffer_WordChar:
	 inc de
ParseBuffer_WordCharNotIncluded:
	 inc hl
	 dec bc
ParseBuffer_WordLoop:
	 ld a,b
	 or c
	 jr z,ParseBuffer_WordDone
	 ld a,(hl)

	 cp Lspace
	 jr z,ParseBuffer_WordDone
	 cp Lenter
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
	  pop hl
	 jr z,ParseBuffer_NoEscapes
	 call ParseEscapedWord
	 jr ParseBuffer_GotWord
ParseBuffer_NoEscapes:
	 call ParseUnescapedWord
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
ParseBuffer_Error:
	 BCALL _ErrSyntax
	 ;; UNREACHABLE

ParseBuffer_EOF:
	ld hl,(parseParent)
	call GetListFirstButfirst
	push hl
	 ld hl,emptyNode
	 or a
	 sbc hl,de
	 jr nz,ParseBuffer_Error
	 push de
	  ld hl,(parseParent)
	  call FreeNode
	  pop de
	 ld hl,0
	 ld (parseParent),hl	; discard old refs
	 ld (parseCurrent),hl
	 pop hl
	ret


;; ParseUnescapedWord:
;;
;; Convert a text string to a word, without handling any escape
;; sequences.
;;
;; Input:
;; - HL = address of first character
;; - DE = length of word
;;
;; Output:
;; - HL = word
;;
;; Destroys:
;; - AF, BC, DE, HL

ParseUnescapedWord:
ParseEscapedWord:
	or a
	ld bc,(parseBufferMPtr)
	sbc hl,bc
	push hl			; save offset to first character
	 add hl,bc
	 push de
	  ;; Skip over initial quotes/colons
ParseUnescapedWord_InitialQuotesLoop:
	  ld a,d
	  or e
	  jr z,ParseUnescapedWord_InitialQuotesDone
	  ld a,(hl)
	  cp Lquote
	  jr z,ParseUnescapedWord_InitialQuote
	  cp Lcolon
	  jr nz,ParseUnescapedWord_InitialQuotesDone
ParseUnescapedWord_InitialQuote:
	  inc hl
	  dec de
	  jr ParseUnescapedWord_InitialQuotesLoop
ParseUnescapedWord_InitialQuotesDone:
	  ld b,d
	  ld c,e
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
ParseUnescapedWord_AddQuotes:
	ld a,b
	or c
	ret z
	ld a,(de)
	dec de
	dec bc
	cp Lcolon
	jr z,ParseUnescapedWord_AddColon
	call NewQuote
	jr ParseUnescapedWord_AddQuotes
ParseUnescapedWord_AddColon:
	call NewColon
	jr ParseUnescapedWord_AddQuotes

;; ParseSimpleWord:
;;
;; Convert a text string to a word, without handling any escape
;; sequences or quotes.
;;
;; Input:
;; - HL = address of first character
;; - BC = length of word
;;
;; Output:
;; - HL = word
;;
;; Destroys:
;; - AF, BC, DE

ParseSimpleWord:
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
