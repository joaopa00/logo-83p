;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data Structure Primitives: Constructors
;;;


;; FPUT:
;;
;; FPUT thing list
;;
;; Construct a new list by adding :thing onto the beginning of :list.

p_FPUT:
	BUILTIN_PRIMITIVE 2, 2, 2, ".l$"
	call Pop2OPS
	jp NewList


;; LPUT:
;;
;; LPUT thing list
;;
;; Construct a new list by adding :thing onto the end of :list.

p_LPUT:
	BUILTIN_PRIMITIVE 2, 2, 2, ".l$"
	call PopOPS
	call CopyList
	push hl
	 call PopOPS
	 ld de,emptyNode
	 call NewList
	 ex de,hl
	 pop hl
	jp ConcatenateLists


;; LIST:
;;
;; LIST thing1 thing2
;;
;; Construct a new list with two elements, :thing1 and :thing2.

p_LIST:
	BUILTIN_PRIMITIVE 2, 2, 2, ""
	call PopOPS
	ld de,emptyNode
	call NewList
	ex de,hl
	call PopOPS
	jp NewList


;; WORD:
;;
;; WORD word1 word2
;;
;; Construct a new word by concatenating the two inputs.

p_WORD:
	BUILTIN_PRIMITIVE 2, 2, 2, "ww$"
	call Pop2OPS
	push de
	 push hl
	  call GetWordSize
	  ex de,hl
	  call GetWordSize
	  add hl,de
	  ld b,h
	  ld c,l
	  call NewString
	  ex (sp),hl
	  call GetWordChars
	  pop bc
	 pop hl
	push bc
	 call GetWordChars
	 pop hl
	ret


;; SENTENCE:
;;
;; SENTENCE thing1 thing2
;; SE thing1 thing2
;;
;; Construct a new list by combining the inputs.  If the inputs are
;; not lists, the output is the same as LIST; if the inputs are lists,
;; their elements are copied into the new list.
;;
;; For example, SENTENCE 1 2 outputs [1 2], while SENTENCE 1 [2 3]
;; outputs [1 2 3].

p_SENTENCE:
	BUILTIN_PRIMITIVE 2, 2, 2, ""
	call Pop2OPS
	push de
	 call IsList
	 jr nc,SENTENCE_FirstArgIsList
	 ld de,emptyNode
	 call NewList
	 jr SENTENCE_FirstArgNotList
SENTENCE_FirstArgIsList:
	 call CopyList
SENTENCE_FirstArgNotList:
	 ex (sp),hl
	 call IsList
	 ld de,emptyNode
	 call c,NewList
	 ex de,hl
	 pop hl
	jp ConcatenateLists


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data Structure Primitives: Selectors
;;;


;; FIRST:
;;
;; FIRST word-or-list
;;
;; Output the first element of the input list, or the first character
;; of the input word.

p_FIRST:
	BUILTIN_PRIMITIVE 1, 1, 1, "q$"
	call PopOPS
	call IsList
	jr c,FIRST_NotList
	jp nz,GetListFirst
	ex de,hl
	jp ThrowBadInputError
FIRST_NotList:
	ld de,0
	push hl
	 call GetWordChar
	 pop de
	jp nc,NewChar
	jp ThrowBadInputError


;; LAST:
;;
;; LAST list
;;
;; Output the last element of the input list.

p_LAST:
	BUILTIN_PRIMITIVE 1, 1, 1, "n$"
	call PopOPS
LAST_Loop:
	call GetListFirstButfirst
	ex de,hl
	call IsList
	jr nz,LAST_Loop
	ex de,hl
	ret


;; BUTFIRST:
;;
;; BUTFIRST list
;; BF list
;;
;; Output the list containing all but the first element of the input
;; list.

p_BUTFIRST:
	BUILTIN_PRIMITIVE 1, 1, 1, "n$"
	call PopOPS
	jp GetListButfirst


;; ITEM:
;;
;; ITEM number word-or-list
;;
;; Output the nth item of the input word or list (the nth character,
;; if the input is a word, or the nth element, if it is a list.)

p_ITEM:
	BUILTIN_PRIMITIVE 2, 2, 2, "Iq$"
	call Pop2OPS
	push hl
	 ld a,h
	 or l
	 jr z,ITEM_Error
	 dec hl
	 ex de,hl
	 call IsList
	 jr nc,ITEM_List
	 call GetWordChar
	 jr c,ITEM_Error
	 pop hl
	jp NewChar
ITEM_List:
	 jr z,ITEM_Error
	 ld a,d
	 or e
	 jr z,ITEM_ListDone
	 call GetListButfirst
	 dec de
	 call IsList
	 jr ITEM_List
ITEM_ListDone:
	 pop af
	jp GetListFirst

ITEM_Error:
	 pop de
	jp ThrowBadInputError


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data Structure Primitives: Predicates
;;;


;; WORDP:
;;
;; WORDP thing
;; WORD? thing
;;
;; Output TRUE if the input is a word.

p_WORDP:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call IsWord
	jp c,ReturnFalse
	jp ReturnTrue


;; LISTP:
;;
;; LISTP thing
;; LIST? thing
;;
;; Output TRUE if the input is a list.

p_LISTP:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call IsList
	jp c,ReturnFalse
	jp ReturnTrue


;; EMPTYP:
;;
;; EMPTYP thing
;; EMPTY? thing
;;
;; Output TRUE if the input is the empty word or the empty list.

p_EMPTYP:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	call IsWord
	jr nc,EMPTYP_Word
	call IsList
	jp c,ReturnFalse
	jp z,ReturnTrue
	jp ReturnFalse
EMPTYP_Word:
	call GetWordSize
	ld a,h
	or l
	jp z,ReturnTrue
	jp ReturnFalse


;; EQUALP:
;;
;; EQUALP thing1 thing2
;; EQUAL? thing1 thing2
;;
;; Output TRUE if the inputs are equal.

p_EQUALP:
	BUILTIN_PRIMITIVE 2, 2, 2, ""
	call Pop2OPS
	call ValuesEqual
	jp z,ReturnTrue
	jp ReturnFalse


;; NOTEQUALP:
;;
;; NOTEQUALP thing1 thing2
;; NOTEQUAL? thing1 thing2
;;
;; Output TRUE if the inputs are not equal.

p_NOTEQUALP:
	BUILTIN_PRIMITIVE 2, 2, 2, ""
	call Pop2OPS
	call ValuesEqual
	jp nz,ReturnTrue
	jp ReturnFalse


;; NUMBERP:
;;
;; NUMBERP thing
;; NUMBER? thing
;;
;; Output TRUE if the input is a number.

p_NUMBERP:
	BUILTIN_PRIMITIVE 1, 1, 1, ""
	call PopOPS
	bit 7,h
	jp z,ReturnTrue
	jp ReturnFalse


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data Structure Primitives: Queries
;;;


;; COUNT:
;;
;; COUNT word-or-list
;;
;; Output the number of elements in the input if it is a list, or the
;; number of characters if it is a word.

p_COUNT:
	BUILTIN_PRIMITIVE 1, 1, 1, "q$"
	call PopOPS
	call IsList
	ld de,0
	jr nc,COUNT_List
	jp GetWordSize
COUNT_List:
	jr z,COUNT_ListDone
	inc de
	call GetListButfirst
	call IsList
	jr COUNT_List
COUNT_ListDone:
	ex de,hl
	ret
