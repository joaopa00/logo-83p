;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; General Object Manipulation Routines
;;;

;; NewObject:
;;
;; Create a new uninitialized object.
;;
;; Input:
;; - A = type byte (type ID << 2)
;; - HL = size of data required
;;
;; Output:
;; - HL = address of data section
;; - DE = reference to new object
;;
;; Destroys:
;; - AF, BC

NewObject:
	push af
	 ld b,h
	 ld c,l
	 call InsertFinalObjectMem
	 ld (newObjectMPtr),de
	 call AllocNode
	 pop af
	push de
	 ld (hl),a
	 inc hl
	 ld a,(currentGCFlag)
	 ld (hl),a
	 inc hl
	 ld de,(newObjectMPtr)
	 ld (hl),e
	 inc hl
	 ld (hl),d
	 ex de,hl
	 pop de
	ret


;; GetObjectSize:
;;
;; Determine the size of a given object's data section.  Do not pass
;; anything other than an object reference.
;;
;; Input:
;; - HL = reference to object
;;
;; Output:
;; - HL = size of object's data
;;
;; Destroys:
;; - AF, BC

GetObjectSize:
	call RefToPointer
	ld a,(hl)
	cp T_SYMBOL<<2
	jr z,GetObjectSize_Symbol
	cp T_STRING<<2
	jr z,GetObjectSize_String
; 	cp T_ARRAY<<2
; 	jr z,GetObjectSize_Array
; 	cp T_ARRAY_OFFSET<<2
; 	jr z,GetObjectSize_OffsetArray
	BCALL _ErrDataType

GetObjectSize_String:
	inc hl
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	call LoadHLIndPaged
	inc hl
	inc hl
	ret

GetObjectSize_Symbol:
	inc hl
	ld b,(hl)
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	push de
	 ld de,8
	 call Add_BHL_DE
	 pop de
	call LoadHLIndPaged
	ld bc,10
	add hl,bc
	ret

