;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; List Manipulation Routines
;;;


;; NewList:
;;
;; Create a new list node.
;;
;; Input:
;; - HL = FIRST element of the list
;; - DE = BUTFIRST of the list (must be a user node)
;;
;; Output:
;; - HL = new list
;;
;; Destroys:
;; - AF, BC, DE

NewList:
	bit 7,d
	jp z,TypeAssertionFailed
	bit 1,e
	jp z,TypeAssertionFailed
NewList_nc:
	;; Create a new node
	push hl
	 push de
	  call AllocNode
	  pop bc
	 ;; Fill in the provided data
	 ld (hl),c
	 inc hl

; 	 ld a,(currentGCFlag)
; 	 xor b
; 	 xor 80h		; because B already had bit 7 set
;	 ld (hl),a
	 res 7,b
	 ld (hl),b

	 inc hl
	 pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	ex de,hl
	ret


;; GetListFirst:
;;
;; Get first element of a list.
;;
;; Input:
;; - HL = nonempty list
;;
;; Output:
;; - HL = first element of the list
;;
;; Destroys:
;; - AF

GetListFirst:
	call IsList
	jp c,TypeAssertionFailed
	jp z,TypeAssertionFailed
GetListFirst_nc:
	call RefToPointer
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ret


;; GetListButfirst:
;;
;; Get butfirst of a list.
;;
;; Input:
;; - HL = nonempy list
;;
;; Output:
;; - HL = list with first element removed
;;
;; Destroys:
;; - AF

GetListButfirst:
	call IsList
	jp c,TypeAssertionFailed
	jp z,TypeAssertionFailed
GetListButfirst_nc:
	call RefToPointer
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	set 7,h
	ret


;; GetListFirstButfirst:
;;
;; Get first and butfirst of a list.
;;
;; Input:
;; - HL = nonempty list
;;
;; Output:
;; - HL = first element of the list
;; - DE = list with first element removed
;;
;; Destroys:
;; - AF

GetListFirstButfirst:
	call IsList
	jp c,TypeAssertionFailed
	jp z,TypeAssertionFailed
GetListFirstButfirst_nc:
	call RefToPointer
	ld e,(hl)
	inc hl
	ld d,(hl)
	set 7,d
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ret



;; SetListFirst:
;;
;; Set first element of a list.
;;
;; Input:
;; - HL = nonempty list
;; - DE = new first element
;;
;; Destroys:
;; - AF, HL

SetListFirst:
	call IsList
	jp c,TypeAssertionFailed
	jp z,TypeAssertionFailed
SetListFirst_nc:
	call RefToPointer
	inc hl
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	ret


;; SetListButfirst:
;;
;; Set butfirst of a list.
;;
;; Input:
;; - HL = nonempty list
;; - DE = new butfirst
;;
;; Destroys:
;; - AF, HL

SetListButfirst:
	call IsList
	jp c,TypeAssertionFailed
	jp z,TypeAssertionFailed
	bit 7,d
	jp z,TypeAssertionFailed
	bit 1,e
	jp z,TypeAssertionFailed
SetListButirst_nc:
	call RefToPointer
	ld (hl),e
	inc hl

; 	ld a,(currentGCFlag)
; 	xor d
; 	xor 80h
	ld a,d
	and 7Fh

	ld (hl),a
	ret


;; IsList:
;;
;; Determine if a value is a list (either empty or nonempty.)
;;
;; Input:
;; - HL = value
;;
;; Output:
;; - CF set if value is not a list
;; - CF clear, ZF set if value is an empty list
;; - CF clear, ZF clear if value is a nonempty list
;;
;; Destroys:
;; - A

IsList:
	bit 7,h
	scf
	ret z
	push hl
	 call RefToPointer
	 ld a,(hl)
	 pop hl
	or a
	rrca
	ret c
	rrca
	ccf
	ret nc
	cp T_EMPTY
	ret z
	scf
	ret


;; CopyList:
;;
;; Make a copy of a list.  (This does not copy the elements of the
;; list; those are identical to the elements of the original.)
;;
;; Input:
;; - HL = original list
;;
;; Output:
;; - HL = new list
;;
;; Destroys:
;; - AF, BC, DE

CopyList:
	call IsList
	jp c,TypeAssertionFailed
	ret z			; copy of empty list is empty list

	call GetListFirstButfirst
	push de
	 ld de,emptyNode
	 call NewList
	 pop de
	push hl			; save start of new list
CopyList_Loop:
	;; HL = last node in new list; DE = next node in original list
	 ld a,e
	 cp low(emptyNode)
	 jr nz,CopyList_Continue
	 ld a,d
	 cp high(emptyNode)
	 jr z,CopyList_Done
CopyList_Continue:
	 push hl		; last node in new list
	  ex de,hl
	  call GetListFirstButfirst ; get next element of original
	  push de
	   ld de,emptyNode
	   call NewList
	   pop bc
	  pop de
	 push bc
	  ex de,hl
	  call SetListButfirst
	  ex de,hl
	  pop de
	 jr CopyList_Loop
CopyList_Done:
	 pop hl
	ret


;; ConcatenateLists:
;;
;; Join two lists together by modifying the first list to point to the
;; second.
;;
;; Input:
;; - HL = first list (WILL BE MODIFIED)
;; - DE = second list
;;
;; Output:
;; - HL = combined list
;;
;; Destroys:
;; - AF, DE

ConcatenateLists:
	call IsList
	jp c,TypeAssertionFailed
	jr z,ConcatenateLists_FirstEmpty
	push hl
ConcatenateLists_Loop:
	 push hl
	  call GetListButfirst
	  call IsList
	  jr z,ConcatenateLists_Done
	  pop af
	 jr ConcatenateLists_Loop
ConcatenateLists_Done:
	  pop hl
	 call SetListButfirst
	 pop hl
	ret

ConcatenateLists_FirstEmpty:
	ex de,hl
	ret
