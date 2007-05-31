;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; List Manipulation Routines
;;;


;; CreateList:
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

CreateList:
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


;; GetFirst:
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

GetFirst:
	call RefToPointer
	inc hl
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ret


;; GetButfirst:
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

GetButfirst:
	call RefToPointer
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	set 7,h
	ret

