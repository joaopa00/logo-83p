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
	or a
	bit 7,h
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
