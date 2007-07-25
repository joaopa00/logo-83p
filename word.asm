;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Word Manipulation Routines
;;;

;; NewString:
;;
;; Create a new string object.  The contents will be uninitialized.
;;
;; Input:
;; - BC = length of string
;;
;; Output:
;; - HL = reference to string
;; - DE = address of first character
;;
;; Destroys:
;; - AF

NewString:
	ld h,b
	ld l,c
	inc hl
	inc hl
	push bc
	 ld a,T_STRING<<2
	 call NewObject
	 pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ex de,hl
	ret


;; NewSymbol:
;;
;; Create a new symbol object.  Its value will be undefined by
;; default, and it will not be added to the obarray.
;;
;; Input:
;; - BC = length of symbol's name
;;
;; Output:
;; - HL = reference to symbol
;; - DE = address of first character
;;
;; Destroys:
;; - AF

NewSymbol:
	ld hl,10
	add hl,bc
	push bc
	 ld a,T_SYMBOL<<2
	 call NewObject
	 ld (hl),low voidNode	; 
	 inc hl			; procedure
	 ld (hl),high voidNode	; 
	 inc hl
	 ld (hl),low voidNode	; 
	 inc hl			; variable
	 ld (hl),high voidNode	; 
	 inc hl
	 ld (hl),low voidNode	; 
	 inc hl			; plist
	 ld (hl),high voidNode	; 
	 inc hl
	 ld (hl),0		; 
	 inc hl			; next pointer
	 ld (hl),0		; 
	 inc hl
	 pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ex de,hl
	ret


;; NewChar:
;;
;; Create a new character atom.
;;
;; Input:
;; - A = character value
;;
;; Output:
;; - HL = reference to character
;;
;; Destroys:
;; - AF, BC, DE

NewChar:
	ld bc,T_CHAR<<2
	ld l,a
	ld h,b
	jp NewAtom
	

;; NewQuote:
;;
;; Create a new quote-prefixed word.
;;
;; Input:
;; - HL = word
;;
;; Output:
;; - HL = word with quote prepended
;;
;; Destroys:
;; - AF

NewQuote:
	push bc
	 push de
	  ld bc,T_QUOTE<<2
	  call NewAtom
	  pop de
	 pop bc
	ret


;; NewColon:
;;
;; Create a new colon-prefixed word.
;;
;; Input:
;; - HL = word
;;
;; Output:
;; - HL = word with colon prepended
;;
;; Destroys:
;; - AF

NewColon:
	push bc
	 push de
	  ld bc,T_COLON<<2
	  call NewAtom
	  pop de
	 pop bc
	ret


;; IsWord:
;;
;; Determine if a value is a word.
;;
;; Input:
;; - HL = value
;;
;; Output:
;; - CF set if value is not a word
;;
;; Destroys:
;; - A

IsWord:
	ld a,h
	and 80h
	ret z
	push hl
	 call RefToPointer
	 ld a,(hl)
	 pop hl
	rrca
	ccf
	ret nc
	rrca
	ret c
	cp T_SYMBOL		; all types >= T_SYMBOL are currently
				; defined to be words
	ret


;; GetWordSize:
;;
;; Calculate the length (number of characters) in a word.
;;
;; Input:
;; - HL = word value (as determined by IsWord)
;;
;; Output:
;; - HL = number of bytes in word
;;
;; Destroys:
;; - AF, B

GetWordSize:
	call IsWord
	jp c,TypeAssertionFailed
GetWordSize_nc:
	bit 7,h
	jr z,GetWordSize_Integer
	push de
	 call GetNodeContents
	 cp T_SYMBOL<<2
	 jr z,GetWordSize_Symbol
	 cp T_CHAR<<2
	 jr z,GetWordSize_Char
	 cp T_STRING<<2
	 jr z,GetWordSize_String
	 cp T_QUOTE<<2
	 jr z,GetWordSize_Quote
	 cp T_COLON<<2
	 jr z,GetWordSize_Colon
;	 rrca
;	 jr c,GetWordSize_Float
	 BCALL _ErrDataType
	 ;; UNREACHABLE

GetWordSize_Symbol:
	 ld de,8
	 ADD_BHL_DE
GetWordSize_String:
	 LOAD_HL_iBHL
	 pop de
	ret

GetWordSize_Char:
	 pop de
	ld hl,1
	ret

GetWordSize_Quote:
GetWordSize_Colon:
	 pop de
 WARNING "FIXME: unsafe recursion"
	call GetWordSize
	inc hl
	ret

GetWordSize_Integer:
	;; Determine number of digits
	ld a,h
	ld h,0
	or a
	jr z,GetWordSize_Integer_0_255
	cp 3			; < 768 ?
	jr c,GetWordSize_Integer_256_767
	jr z,GetWordSize_Integer_768_1023
	cp 27h			; < 9984 ?
	jr c,GetWordSize_Integer_1024_9983
	jr z,GetWordSize_Integer_9984_10239
	ld l,5
	ret

GetWordSize_Integer_0_255:
	ld a,l
	ld l,1
	cp 10
	ret c
	inc l
	cp 100
	ret c
	inc l
	ret

GetWordSize_Integer_256_767:
	ld l,3
	ret

GetWordSize_Integer_768_1023:
	ld a,l
	ld l,3
	cp 0E8h
	ret c
	inc l
	ret

GetWordSize_Integer_1024_9983:
	ld l,4
	ret

GetWordSize_Integer_9984_10239:
	ld a,l
	ld l,4
	cp 10h
	ret c
	inc l
	ret


;; GetWordChar:
;;
;; Retrieve a given character from a word.
;;
;; (For some types of words, this may be implemented using
;; GetWordChars; but use whichever routine is more appropriate for
;; whatever you're doing.  Also note that calling GetWordSize
;; immediately prior to GetWordChar or GetWordChars may speed things
;; up.)
;;
;; Input:
;; - HL = word value (as determined by IsWord)
;; - DE = character offset from start (i.e., 0 for the first
;;   character)
;;
;; Output:
;; - A = desired character
;; - CF set if index invalid
;;
;; Destroys:
;; - F, BC, DE, HL

GetWordChar:
	call IsWord
	jp c,TypeAssertionFailed
GetWordChar_nc:
	bit 7,h
	jr z,GetWordChar_Integer
	push de
	 call GetNodeContents
	 cp T_SYMBOL<<2
	 jr z,GetWordChar_Symbol
	 cp T_CHAR<<2
	 jr z,GetWordChar_Char
	 cp T_STRING<<2
	 jr z,GetWordChar_String
	 cp T_QUOTE<<2
	 jr z,GetWordChar_Quote
	 cp T_COLON<<2
	 jr z,GetWordChar_Colon
;	 rrca
;	 jr c,GetWordChar_Float
	 BCALL _ErrDataType
	 ;; UNREACHABLE

GetWordChar_Symbol:
	 ld de,8
	 ADD_BHL_DE
GetWordChar_String:
	 push hl
	  push bc
	   LOAD_HL_iBHL		; HL = length of string
	   pop af
	  pop bc		; ABC = address of start
	 pop de			; DE = offset
	inc de
	or a
	sbc hl,de
	ret c
	inc de
	ld h,b
	ld l,c
	ld b,a
	ADD_BHL_DE
	LOAD_A_iBHL
	or a
	ret

GetWordChar_Colon:
	 ld b,Lcolon
	 jr GetWordChar_Prefix
GetWordChar_Quote:
	 ld b,Lquote
GetWordChar_Prefix:
	 pop de
	dec de			; if DE = 0, then return the prefix;
				; otherwise, return the character
				; (DE-1) of the quoted word
	ld a,d
	and e
	inc a
	jr nz,GetWordChar
	ld a,b
	ret

GetWordChar_Char:
	 pop de
	ld a,d
	or e
	scf
	ret nz
	or l
	ret

GetWordChar_Integer:
	push de
	 ld de,OP1
	 push de
	  call GetWordChars_Integer
	  pop hl
	 pop bc
	add hl,bc
	ret c
	sbc hl,de
	ccf
	ret c
	add hl,de
	ld a,(hl)
	ret


;; GetWordChars:
;;
;; Retrieve all of the characters in a word.  Call GetWordSize first
;; to ensure that your buffer is large enough.  Result will not be
;; zero-terminated.
;;
;; (For some types of words, this may be implemented using
;; GetWordChar; but use whichever routine is more appropriate for
;; whatever you're doing.  Also note that calling GetWordSize
;; immediately prior to GetWordChar or GetWordChars may speed things
;; up.)
;;
;; Input:
;; - HL = word value (as determined by IsWord)
;; - DE = address of buffer to store characters
;;
;; Output:
;; - DE = address of byte after the last in the string
;;
;; Destroys:
;; - AF, BC, HL

GetWordChars:
	call IsWord
	jp c,TypeAssertionFailed
GetWordChars_nc:
	bit 7,h
	jr z,GetWordChars_Integer
	push de
	 call GetNodeContents
	 cp T_SYMBOL<<2
	 jr z,GetWordChars_Symbol
	 cp T_CHAR<<2
	 jr z,GetWordChars_Char
	 cp T_STRING<<2
	 jr z,GetWordChars_String
	 cp T_QUOTE<<2
	 jr z,GetWordChars_Quote
	 cp T_COLON<<2
	 jr z,GetWordChars_Colon
;	 rrca
;	 jr c,GetWordChars_Float
	 BCALL _ErrDataType
	 ;; UNREACHABLE

GetWordChars_Symbol:
	 ld de,8
	 ADD_BHL_DE
GetWordChars_String:
	 push hl
	  push bc
	   LOAD_HL_iBHL
	   pop bc
	  ex de,hl
	  pop hl
	 INC_BHL
	 INC_BHL
	 ld a,b
	 ld b,d
	 ld c,e
	 pop de
	FLASH_TO_RAM
	ret

GetWordChars_Char:
	 ld a,l
	 pop de
	ld (de),a
	inc de
	ret

GetWordChars_Colon:
	 ld a,Lcolon
	 jr GetWordChars_Prefix
GetWordChars_Quote:
	 ld a,Lquote
GetWordChars_Prefix:
	 pop de
	ld (de),a
	inc de
	jr GetWordChars	

GetWordChars_Integer:
	or a
	ld bc,-10000
	call GetWordChars_Integer_Digit
	ld bc,-1000
	call GetWordChars_Integer_Digit
	ld bc,-100
	call GetWordChars_Integer_Digit
	ld bc,-10
	call GetWordChars_Integer_Digit
	ld a,l
	add a,L0
	ld (de),a
	inc de
	ret

GetWordChars_Integer_Digit:
	push af
	 ld a,L0-1
GetWordChars_Integer_DigitLoop:
	 add hl,bc
	 inc a
	 jr c,GetWordChars_Integer_DigitLoop
	 sbc hl,bc
	 pop bc
	rr c
	jr c,GetWordChars_Integer_NoHide0
	cp L0
	ret z
	scf
GetWordChars_Integer_NoHide0:
	ld (de),a
	inc de
	ret


;; WordToSymbol:
;;
;; Convert given word into a symbol.
;;
;; Input:
;; - HL = word
;;
;; Output:
;; - HL = symbol
;; - CF set for conversion error
;;
;; Destroys:
;; - AF

WordToSymbol:
	call IsWord
	ret c
WordToSymbol_nc:
	call GetType
	cp T_SYMBOL
	ret z
	push de
	 push bc
	  cp T_INT
	  jr z,WordToSymbol_Short
	  cp T_REAL
	  jr z,WordToSymbol_Short
	  cp T_COMPLEX
	  jr z,WordToSymbol_Short
	  cp T_CHAR
	  jr z,WordToSymbol_Short
	  cp T_STRING
	  jr z,WordToSymbol_String
 warning "FIXME: how to quickly symbolize a quote, colon, or paged string?"
;	cp T_QUOTE
;	jr z,WordToSymbol_Quote
;	cp T_COLON
;	jr z,WordToSymbol_Colon
WordToSymbol_Error:
	  pop bc
	 pop de
	scf
	ret

WordToSymbol_Short:
	  ld de,OP3
	  push de
	   call GetWordChars
	   ex de,hl
	   pop de
	  or a
	  sbc hl,de
	  ld b,h
	  ld c,l
	  ex de,hl
	  call GetNamedSymbol
	  pop bc
	 pop de
	or a
	ret

WordToSymbol_String:
	  call GetNodeContents
 ifndef NO_PAGED_MEM
	  ld a,b
	  or a
	  jr nz,WordToSymbol_Error
 endif
	  ld c,(hl)
	  inc hl
	  ld b,(hl)
	  inc hl
	  call GetNamedSymbol
	  pop bc
	 pop de
	or a
	ret


;; GetSymbolProcedure:
;;
;; Get the procedure definition (if any) associated with a symbol.
;;
;; Input:
;; - HL = symbol
;;
;; Output:
;; - HL = procedure definition, or void if undefined
;;
;; Destroys:
;; - AF, BC, DE

GetSymbolProcedure:
	bit 7,h
	jp z,TypeAssertionFailed
GetSymbolProcedure_nc:
	call GetNodeContents
	cp T_SYMBOL<<2
	jp nz,TypeAssertionFailed
	LOAD_HL_iBHL
	ret
	

;; GetSymbolVariable:
;;
;; Get the variable value (if any) associated with a symbol.
;;
;; Input:
;; - HL = symbol
;;
;; Output:
;; - HL = variable value, or void if undefined
;;
;; Destroys:
;; - AF, BC, DE

GetSymbolVariable:
	bit 7,h
	jp z,TypeAssertionFailed
GetSymbolVariable_nc:
	call GetNodeContents
	cp T_SYMBOL<<2
	jp nz,TypeAssertionFailed
	INC_BHL
	INC_BHL
	LOAD_HL_iBHL
	ret


;; SetSymbolProcedure:
;;
;; Set the procedure definition associated with a symbol.
;;
;; Input:
;; - HL = symbol
;; - DE = new value
;;
;; Destroys:
;; - AF, BC, DE, HL

SetSymbolProcedure:
	bit 7,h
	jp z,TypeAssertionFailed
	ex de,hl
	call GetType
	cp T_SUBR
	jr z,SetSymbolProcedure_OK
	cp T_LIST
	jp nz,TypeAssertionFailed
	push hl
	 call GetListFirst
	 call IsList
	 pop hl
	jp c,TypeAssertionFailed
SetSymbolProcedure_OK:
	ex de,hl
SetSymbolProcedure_nc:
	push de
	 call GetNodeContents
	 pop de
	cp T_SYMBOL<<2
	jp nz,TypeAssertionFailed
	LOAD_iBHL_DE
	ret


;; SetSymbolVariable:
;;
;; Set the variable value associated with a symbol.
;;
;; Input:
;; - HL = symbol
;; - DE = new value
;;
;; Destroys:
;; - AF, BC, DE, HL

SetSymbolVariable:
	bit 7,h
	jp z,TypeAssertionFailed
SetSymbolVariable_nc:
	push de
	 call GetNodeContents
	 pop de
	cp T_SYMBOL<<2
	jp nz,TypeAssertionFailed
	INC_BHL
	INC_BHL
	LOAD_iBHL_DE
	ret


;; GetNamedSymbol:
;;
;; Find (or create) the symbol with the given name.
;;
;; Input:
;; - HL = address of first character of name
;; - BC = number of characters in name
;;
;; Output:
;; - HL = symbol
;;
;; Destroys:
;; - AF, BC, DE

GetNamedSymbol:
	ld (symbolSearchMPtr),hl
	ld (symbolSearchLen),bc
	ld hl,(firstSymbol)
	push af
	 push hl
	  jr GetNamedSymbol_NextSymbol
GetNamedSymbol_NextSymbol1:
	   pop af
GetNamedSymbol_NextSymbol:
	  pop hl
	 pop af
	ld a,h
	or l
	jr z,GetNamedSymbol_Failed
	push hl			; current symbol
	 call GetNodeContents
	 cp T_SYMBOL<<2
	 jp nz,TypeAssertionFailed1
	 ld de,6
	 ADD_BHL_DE
	 LOAD_DE_iBHL
	 push de		; next symbol
	  INC_BHL
	  LOAD_DE_iBHL		; DE = length of current symbol
	  INC_BHL
	  ;; Check if length is the same
	  push hl
	   ld hl,(symbolSearchLen)
	   or a
	   sbc hl,de
	   pop hl
	  jr nz,GetNamedSymbol_NextSymbol
	  ld c,d
	  ld a,e			; CA = length
	  ld de,(symbolSearchMPtr) ; DE -> search string, BHL -> symbol
GetNamedSymbol_CompareLoop:
	  push af
	   or c
	   jr z,GetNamedSymbol_Done
	   LOAD_A_iBHL
	   ex de,hl
	   cp (hl)
	   jr nz,GetNamedSymbol_NextSymbol1
	   ex de,hl
	   inc de
	   INC_BHL
	   pop af
	  sub 1
	  jr nc,GetNamedSymbol_CompareLoop
	  dec c
	  jr GetNamedSymbol_CompareLoop
GetNamedSymbol_Done:
	   pop af
	  pop hl
	 pop hl
	ret
GetNamedSymbol_Failed:
	;; Create a new symbol
	ld bc,(symbolSearchLen)
	call NewSymbol
	push hl
	 push de
	  dec de
	  dec de
	  dec de
	  ld hl,(firstSymbol)
	  ex de,hl
	  ld (hl),d
	  dec hl
	  ld (hl),e
	  pop de
	 ld hl,(symbolSearchMPtr)
	 ld a,b
	 or c
	 jr z,GetNamedSymbol_Empty
	 ldir
GetNamedSymbol_Empty:
	 pop hl
	ld (firstSymbol),hl
	ret	
