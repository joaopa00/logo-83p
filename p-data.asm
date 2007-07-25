;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Data Structure Primitives
;;;


;; FPUT:
;;
;; FPUT thing list
;;
;; Construct a new list by adding :thing onto the front of :list.

p_FPUT:
	BUILTIN_PRIMITIVE 2, 2, 2, ".l$"
	call Pop2OPS
	jp NewList


;; FIRST:
;;
;; FIRST list
;;
;; Output the first element of the input list.

p_FIRST:
	BUILTIN_PRIMITIVE 1, 1, 1, "n$"
	call PopOPS
	jp GetListFirst


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


;; ITEM:
;;
;; ITEM number word-or-list
;;
;; Output the nth item of the input word or list (the nth character,
;; if the input is a word, or the nth element, if it is a list.)

p_ITEM:
	BUILTIN_PRIMITIVE 2, 2, 2, "Iq$"
	call Pop2OPS
	ld a,h
	or l
	jr z,ErrDimension
	dec hl
	ex de,hl
	call IsList
	jr nc,ITEM_List
	call GetWordChar
	jp NewChar
ITEM_List:
	jr z,ErrDimension
	ld a,d
	or e
	jr z,ITEM_ListDone
	call GetListButfirst
	dec de
	call IsList
	jr ITEM_List
ITEM_ListDone:
	jp GetListFirst

ErrDimension:
	BCALL _ErrDimension
	;; UNREACHABLE
