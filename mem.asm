;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Memory Management Routines
;;;


;; SaveWorkspace:
;;
;; Save current state to the workspace appvar.
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - OP1

SaveWorkspace:
	ld hl,(appvarStart)
	ld de,5
	add hl,de
	ex de,hl
	ld hl,savedData
	ld bc,savedDataSize
	ldir
	ret
	
	
;; OpenWorkspace:
;;
;; Create a new, default workspace appvar, or reload the old one if it
;; exists.
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - OP1

OpenWorkspace:
	ld hl,workspaceAppVarName
	rst rMOV9TOOP1
	BCALL _ChkFindSym
	jr c,OpenWorkspace_Create
	ld a,b
	or a
	jr nz,OpenWorkspace_UnArchive
	push de
	 push hl
	  ex de,hl
	  inc hl
	  inc hl
	  ld (appvarStartMPtr),hl

	  ;; Check first 5 bytes
	  ld de,workspaceTemplate
	  ld b,5
OpenWorkspace_CheckLoop:
	  ld a,(de)
	  cp (hl)
	  jr nz,OpenWorkspace_Invalid
	  inc de
	  inc hl
	  djnz OpenWorkspace_CheckLoop

	  ld de,savedData
	  ld bc,savedDataSize
	  ldir
	  pop hl
	 pop de
	jr UpdateWorkspace

OpenWorkspace_Invalid:
	  pop hl
	 pop de
	BCALL _DelVar
	jr OpenWorkspace

OpenWorkspace_UnArchive:
	BCALL _Arc_Unarc
	jr OpenWorkspace

OpenWorkspace_Create:
	ld hl,workspaceTemplateSize
	push hl
	 BCALL _CreateAppVar
	 pop bc
	inc de
	inc de
	ld hl,workspaceTemplate
	ldir

	;; We might want at this point to fill in the template with
	;; additional data...

	jr OpenWorkspace


;; UpdateWorkspace:
;;
;; Update the workspace appvar after it might have moved.  Call this
;; routine when we're sure that the saferam is intact, but we may have
;; allocated or deallocated TIOS variables.
;;
;; Destroys:
;; - AF, BC, DE, HL

UpdateWorkspace:
	or a
	ld hl,(appvarStart)	; Check if appvar has moved
	ld de,(appvarStartMPtr)
	sbc hl,de		; HL = (last known address) - (current
				; address) = amount appvar has been
				; moved backwards
	ret z
	ld (appvarStart),de
	ld b,h
	ld c,l
	ld de,0			; "deletion address" set to zero ->
				; all pointers must be adjusted

	call ResizeAppvar	; we actually don't want to change the
				; appvar's size, but
				; DeleteObjectMemUpdate will decrease
				; it by BC, so compensate by adding BC
				; here.

	jr DeleteObjectMemUpdate
	

;; InsertObjectMem:
;;
;; Insert memory in the object area.  This routine should only be used
;; to resize an object or to allocate space for a subr object (which
;; we prefer to keep in low memory.)  Most of the time we should use
;; InsertFinalObjectMem to allocate space for objects.
;;
;; This routine calls DoInsertMem, so stuff may move.  Use managed
;; pointers if you need 'em.
;;
;; Input:
;; - DE = point of insertion (stuff >= this address will be moved)
;; - BC = number of bytes to insert
;;
;; Output:
;; - DE = point of insertion
;;
;; Destroys:
;; - AF, HL

InsertObjectMem:
	call DoInsertMem

	;; Update our pointers
	jr InsertObjectMemUpdate


;; DeleteObjectMem:
;;
;; Delete memory in the object area.
;;
;; Input:
;; - DE = point of deletion (stuff >= this address will be moved)
;; - BC = number of bytes to remove
;;
;; Destroys:
;; - AF, HL

DeleteObjectMem:
	;; Delete the memory and update TIOS pointers
	push bc
	 push de
	  ex de,hl
	  ld d,b
	  ld e,c
	  BCALL _DelMem
	  pop de
	 pop bc
	;; fall through


;; DeleteObjectMemUpdate:
;;
;; Update pointers after a deletion in the object area.  This does not
;; move anything in memory.  Most of the time this routine should not
;; be called directly.
;;
;; Input:
;; - DE = point of deletion (pointers >= this address will be
;;   adjusted)
;; - BC = number of bytes removed
;;
;; Destroys:
;; - AF, HL

DeleteObjectMemUpdate:
	;; Negate BC
	ld a,b
	cpl
	ld b,a
	ld a,c
	cpl
	ld c,a
	inc bc
	;; fall through


;; InsertObjectMemUpdate:
;;
;; Update pointers after an insertion in the object area.  This does
;; not move anything in memory.  Most of the time this routine should
;; not be called directly.
;;
;; Input:
;; - DE = point of insertion (pointers >= this address will be
;;   adjusted -- including new objects -- watch out!)
;; - BC = number of bytes inserted
;;
;; Destroys:
;; - AF, HL

InsertObjectMemUpdate:
	call InsertFinalObjectMemUpdate ; update pointers that come
					; after object memory, and
					; resize the appvar

	;; Update object handles
	ld hl,(userNodeStartMinus2)
	inc hl
InsertObjectMemUpdate_MovedObj:
	inc hl
	push bc
	 ld bc,(uninitNodeStart)
	 jr InsertObjectMemUpdate_Loop

InsertObjectMemUpdate_Next4:
	 inc hl
InsertObjectMemUpdate_Next3:
	 inc hl
InsertObjectMemUpdate_Next2:
	 inc hl
InsertObjectMemUpdate_Next1:
	 inc hl
InsertObjectMemUpdate_Loop:
	 ;; Have we reached the end of the node table?
	 ld a,b
	 cp h
	 jr c,InsertObjectMemUpdate_Continue
	 ld a,c
	 cp l
	 jr nc,InsertObjectMemUpdate_Done
InsertObjectMemUpdate_Continue:
	 ;; Is this an object node?
	 ld a,(hl)
	 and 7
	 jr nz,InsertObjectMemUpdate_Next4

	 inc hl			; HL -> node + 1 (page number)

	 ;; Is the data for this node stored in RAM?
	 ld a,(hl)
	 and 7Fh
	 jr nz,InsertObjectMemUpdate_Next3

	 inc hl
	 inc hl			; HL -> node + 3 (address MSB)

	 ;; Is the address >= DE?
	 ld a,(hl)
	 cp d
	 jr c,InsertObjectMemUpdate_Next1 ; obj < DE -> skip

	 dec hl			; HL -> node + 2 (address LSB)

	 ld a,(hl)
	 jr nz,InsertObjectMemUpdate_MoveObj ; obj >= DE -> adjust
	 cp e
	 jr c,InsertObjectMemUpdate_Next2 ; obj < DE -> skip

InsertObjectMemUpdate_MoveObj:
	 ;; We've found an object that needs moving
	 ;; A = (HL) = LSB of its address
	 pop bc
	add a,c
	ld (hl),a
	inc hl			; HL -> node + 3 (address MSB)
	ld a,(hl)
	adc a,b
	ld (hl),a
	jr InsertObjectMemUpdate_MovedObj

InsertObjectMemUpdate_Done:
	 pop bc
	ret


;; InsertFinalObjectMem:
;;
;; Insert memory at the end of the object area.  This is what we
;; generally want to do when creating a new object.
;;
;; This routine calls DoInsertMem, so stuff may move.  Use managed
;; pointers if you need 'em.
;;
;; Input:
;; - BC = number of bytes to insert
;;
;; Output:
;; - DE = address of insertion
;;
;; Destroys:
;; - AF, HL

InsertFinalObjectMem:
	ld de,(userNodeStartMinus2)
	inc de
	inc de
	call DoInsertMem

	;; fall through


;; InsertFinalObjectMemUpdate:
;;
;; Update pointers after an insertion at the end of the object area.
;; This does not move anything in memory.  Most of the time this
;; routine should not be called directly.
;;
;; Input:
;; - BC = number of bytes inserted
;;
;; Destroys:
;; - AF, HL

InsertFinalObjectMemUpdate:
	call ResizeAppvar
	
	;; Update pointers to the node table, which has been moved
	ld hl,(userNodeStartMinus2)
	add hl,bc
	ld (userNodeStartMinus2),hl

	ld hl,(uninitNodeStart)
	add hl,bc
	ld (uninitNodeStart),hl

	ld hl,(uninitNodeEnd)
	add hl,bc
	ld (uninitNodeEnd),hl

	;; ... More pointers? ...

	ret


;; ResizeAppvar:
;;
;; Resize the workspace appvar after memory has been inserted or
;; deleted.
;;
;; Input:
;; - BC = number of bytes inserted
;;
;; Destroys:
;; - AF, HL
	
ResizeAppvar:
	;; Resize the appvar
	ld hl,(appvarStart)
	dec hl
	dec hl
	ld a,(hl)
	add a,c
	ld (hl),a
	inc hl
	ld a,(hl)
	adc a,b
	ld (hl),a

	ret


;; InsertUninitNodeMem:
;;
;; Insert new uninitialized node memory.
;;
;; This routine calls DoInsertMem, so stuff may move.  Use managed
;; pointers if you need 'em.
;;
;; Input:
;; - BC = number of bytes requested
;;
;; Destroys:
;; - AF, DE, HL

InsertUninitNodeMem:
	ld de,(uninitNodeEnd)
	call DoInsertMem
	ex de,hl
	add hl,bc
	ld (uninitNodeEnd),hl
	;; No other pointers to update -- UNM is the last thing in the
	;; appvar.
	jr ResizeAppvar


;; DoInsertMem:
;;
;; Insert memory.  If there isn't enough, run the garbage collector,
;; in which case the location where we're doing the insertion may
;; change.  If there still isn't enough after GC-ing, throw an error.
;;
;; Input:
;; - DE = point of insertion
;; - BC = number of bytes to insert
;;
;; Output:
;; - DE = new point of insertion
;;
;; Destroys:
;; - AF, HL
;; - iMathPtr2 (?)

DoInsertMem:
	ld hl,(FPS)
	add hl,bc
	jr c,DoInsertMem_NotEnough
	push bc
	 ld bc,(OPS)
	 sbc hl,bc
	 pop bc
	jr nc,DoInsertMem_NotEnough

	push bc
	 ld h,b
	 ld l,c
	 BCALL _InsertMem
	 pop bc
	ret

DoInsertMem_NotEnough:

	;; [Call garbage collector, check again for free memory.]

	BCALL _ErrMemory
	;; UNREACHABLE

