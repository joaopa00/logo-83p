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
;; - DE = BUTFIRST of the list (caller is responsible for ensuring
;;   that this is a user node.)
;;
;; Output:
;; - HL = new list
;;
;; Destroys:
;; - AF, BC, DE

NewList:
	;; Create a new node
	push hl
	 push de
	  call AllocNode
	  pop bc
	 ;; Fill in the provided data
	 ld (hl),c
	 inc hl
	 ld a,(currentGCFlag)
	 xor b
	 xor 80h		; because B already had bit 7 set
	 ld (hl),a
	 inc hl
	 pop bc
	ld (hl),c
	inc hl
	ld (hl),b
	ex de,hl
	ret


;; GetListFirst:
;;
;; Get first element of a list.  No error checking here.  GIGO.
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
;; Get butfirst of a list.  No error checking here.  GIGO.
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
	call RefToPointer
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	set 7,h
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


