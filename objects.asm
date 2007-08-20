;;; -*- TI-Asm -*-

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

; 	 ld a,(currentGCFlag)
; 	 ld (hl),a
	 ld (hl),0

	 inc hl
	 ld de,(newObjectMPtr)
	 ld (hl),e
	 inc hl
	 ld (hl),d
	 ex de,hl
	 pop de
	ret


;; NewAtom:
;;
;; Create a new atom.
;;
;; Input:
;; - C = type byte (type ID << 2)
;; - BHL = data
;;
;; Output:
;; - HL = reference to new atom
;;
;; Destroys:
;; - AF, BC, DE

NewAtom:
	push hl
	 push bc
	  call AllocNode
	  pop bc
	 ld (hl),c
	 inc hl

; 	 ld a,(currentGCFlag)
; 	 or b
; 	 ld (hl),a
	 ld (hl),b

	 pop bc
	inc hl
	ld (hl),c
	inc hl
	ld (hl),b
	ex de,hl
	ret


;; GetAtomData:
;;
;; Get the data field from an atom.
;;
;; Input:
;; - HL = atom
;;
;; Output:
;; - BHL = data
;;
;; Destroys:
;; - AF

GetAtomData:
	bit 7,h
	jp z,TypeAssertionFailed
	call GetNodeContents
	xor 4
	and 7
	jp nz,TypeAssertionFailed
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
;; - AF, BC, DE

GetObjectSize:
	call GetNodeContents
GetObjectSizeC:
	cp T_SYMBOL<<2
	jr z,GetObjectSize_Symbol
	cp T_STRING<<2
	jr z,GetObjectSize_String
; 	cp T_ARRAY<<2
; 	jr z,GetObjectSize_Array
; 	cp T_ARRAY_OFFSET<<2
; 	jr z,GetObjectSize_OffsetArray
;	cp T_SUBR<<2
;	jr z,GetObjectSize_Subr
	BCALL _ErrDataType
	;; UNREACHABLE

GetObjectSize_String:
	LOAD_HL_iBHL
	inc hl
	inc hl
	ret

GetObjectSize_Symbol:
	ld de,8
	ADD_BHL_DE
	LOAD_HL_iBHL
	ld bc,10
	add hl,bc
	ret


;; FreeObject:
;;
;; Free an object node along with its accompanying data.  Do not call
;; this on anything other than a valid user object node.  (This
;; routine should only ever be used by the garbage collector anyway.)
;;
;; Input:
;; - HL = reference to object
;;
;; Destroys:
;; - AF, BC, DE, HL

FreeObject:
	push hl
	 call GetNodeContents
	 ld c,a
	 ld a,b
	 or a
	 jr nz,FreeObject_NonRAMData
	 push hl
	  ld a,c
	  call GetObjectSizeC
	  ld b,h
	  ld c,l
	  pop de
	 call DeleteObjectMem
FreeObject_NonRAMData:
	 pop hl
	jp FreeNode
