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
	ld h,0
	jp NewAtom


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
	ld a,L0-1
GetWordChars_Integer_DigitLoop:
	add hl,bc
	inc a
	jr c,GetWordChars_Integer_DigitLoop
	sbc hl,bc
	cp L0
	ret z
	ld (de),a
	inc de
	ret


