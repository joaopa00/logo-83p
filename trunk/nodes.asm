;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Low-level Node Manipulation Routines
;;;

;; RefToPointer:
;;
;; Convert a node reference to a pointer to that node.  Do not pass
;; anything other than a valid node reference.  GIGO.
;;
;; Input:
;; - HL = node reference
;;
;; Output:
;; - HL = address of node
;;
;; Destroys:
;; - F

RefToPointer:
	bit 1,l			; Check if it is a BUILTIN or USER node
	jr z,BuiltinRefToPointer
UserRefToPointer:
	res 7,h
	push de
	 ld de,(userNodeStartMinus2)
	 add hl,de
	 pop de
	ret
BuiltinRefToPointer:
	push de
	 ld de,builtinNodeStart-8000h
	 add hl,de
	 pop de
	ret
UserRefToPointerPlus2:
	inc hl
	inc hl
	jr UserRefToPointer


;; UserPointerToRef:
;;
;; Convert a pointer to a user node into a reference to that node.
;; Don't pass anything other than a valid user node pointer.
;;
;; Input:
;; - HL = node pointer
;;
;; Output:
;; - HL = node reference
;;
;; Destroys:
;; - F

UserPointerToRef:
	push de
	 or a
	 ld de,(userNodeStartMinus2)
	 sbc hl,de
	 pop de
	set 7,h
	ret


;; AllocNode:
;;
;; Return a new, uninitialized node.  Caller *must* populate the node
;; with data.
;;
;; The policy (which attempts to minimize fragmentation of the node
;; storage) is to allocate free nodes in this order:
;;
;; - Single free nodes (i.e., those that were previously allocated
;;   individually and then released by the garbage collector)
;;
;; - Uninitialized node memory (the block of memory that's already
;;   been allocated but hasn't been used yet)
;;
;; - Nodes that were previously allocated as pairs or quads and later
;;   released (obviously, in this case we return the leftover nodes to
;;   the free node list(s))
;;
;; - Finally, if none of the above methods were able to find a free
;;   node, then allocate more memory.
;;
;; Output:
;; - DE = reference to new node
;; - HL = address of new node
;;
;; Destroys:
;; - AF

AllocNode:
	;; First, try to get a free node from the list of single nodes
	ld hl,(freeNodeList)
	ld a,h
	or l
	jr z,AllocNode_FreeListEmpty
	push hl
	 call UserRefToPointerPlus2
	 ld e,(hl)
	 inc hl
	 ld d,(hl)
	 ld (freeNodeList),de
	 dec hl
	 dec hl
	 dec hl
	 pop de
	ret

AllocNode_FreeListEmpty:
	;; There are no free nodes in the list.  Try to get a node
	;; from unintialized node memory.
	ld de,4
	call AllocUNM
	jr c,AllocNode_NoUNM
	push hl
	 call UserPointerToRef
	 ex de,hl
	 pop hl
	ret

AllocNode_NoUNM:
	;; We have no free single nodes, and no uninitialized node
	;; memory.  Call AllocNodePair to get a pair of nodes, and use
	;; only one of them.
	call AllocNodePair
	push hl
	 push de
	  ld hl,4
	  add hl,de
	  call FreeNode
	  pop de
	 pop hl
	ret


;; AllocNodePair:
;;
;; Return a pair of new, uninitialized nodes.  Caller must populate
;; both nodes with data.
;;
;; The policy here is to use a free pair if possible, then UNM, then a
;; free quad, then newly-allocated memory.
;;
;; Output:
;; - DE = reference to first node
;; - HL = address of first node
;;
;; Destroys:
;; - AF

AllocNodePair:
	;; First, try to get a pair from the list of free pairs
	ld hl,(freeNodePairList)
	ld a,h
	or l
	jr z,AllocNodePair_FreeListEmpty
	push hl
	 call UserRefToPointerPlus2
	 ld e,(hl)
	 inc hl
	 ld d,(hl)
	 ld (freeNodePairList),de
	 dec hl
	 dec hl
	 dec hl
	 pop de
	ret

AllocNodePair_FreeListEmpty:
	;; There are no free pairs in the list.  Try to get one from
	;; unintialized node memory.
	ld de,8
	call AllocUNM
	jr c,AllocNodePair_NoUNM
	push hl
	 call UserPointerToRef
	 ex de,hl
	 pop hl
	ret

AllocNodePair_NoUNM:
	;; We have no free pairs and no UNM.  Call AllocNodeQuad and
	;; use only two of the nodes we are given.
	call AllocNodeQuad
	push hl
	 push de
	  ld hl,8
	  add hl,de
	  call FreeNodePair
	  pop de
	 pop hl
	ret


;; AllocNodeQuad:
;;
;; Return four new, uninitialized nodes.  Caller must populate all
;; four nodes with data.
;;
;; The policy here is to use a free quad if possible, then UNM, then
;; newly-allocated memory.
;;
;; Output:
;; - DE = reference to first node
;; - HL = address of first node
;;
;; Destroys:
;; - AF

AllocNodeQuad:
	;; First, try to get a quad from the list of free quads
	ld hl,(freeNodeQuadList)
	ld a,h
	or l
	jr z,AllocNodeQuad_FreeListEmpty
	push hl
	 call UserRefToPointerPlus2
	 ld e,(hl)
	 inc hl
	 ld d,(hl)
	 ld (freeNodeQuadList),de
	 dec hl
	 dec hl
	 dec hl
	 pop de
	ret

AllocNodeQuad_NoUNM:
	;; We're really out of space.  Allocate more memory!
	push bc
	 ld bc,NODE_MEM_INCREMENT
	 call InsertUninitNodeMem	; This will throw an error if
					; we're really, really out of
					; space
	 pop bc
AllocNodeQuad_FreeListEmpty:
	;; There are no free quads in the list.  Try to get one from
	;; unintialized node memory.
	ld de,16
	call AllocUNM
	jr c,AllocNodeQuad_NoUNM
	push hl
	 call UserPointerToRef
	 ex de,hl
	 pop hl
	ret


;; AllocUNM:
;; 
;; Try to allocate unintialized node memory.
;;
;; Input:
;; - DE = number of bytes requested
;;
;; Output:
;; - CF set if not enough memory is available
;; - HL = address of requested memory if successful
;;
;; Destroys:
;; - F, DE

AllocUNM:
	ld hl,(uninitNodeStart)
	push hl
	 add hl,de
	 jr c,AllocUNM_Fail
	 ex de,hl
	 ld hl,(uninitNodeEnd)
	 dec hl
	 sbc hl,de
	 jr c,AllocUNM_Fail
	 ld (uninitNodeStart),de
	 pop hl
	ret
AllocUNM_Fail:
	 pop hl
	scf
	ret


;; FreeNode:
;;
;; Free a single node.  Do not call this on anything other than a user
;; node.  (Just a hint: only the garbage collector and the above
;; allocation functions should ever call this routine.)
;;
;; Input:
;; - HL = reference to node to be freed
;;
;; Destroys:
;; - AF, DE, HL

FreeNode:
	ld de,(freeNodeList)
	ld (freeNodeList),hl
	call UserRefToPointer
SetNodeFree:
	ld (hl),T_FREE<<2
	inc hl
	ld a,(currentGCFlag)
	ld (hl),a
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	ret


;; FreeNodePair:
;;
;; Free a node pair.  Same caveat as with FreeNode.
;;
;; Input:
;; - HL = reference to first of two nodes to be freed
;;
;; Destroys:
;; - AF, DE, HL

FreeNodePair:
	ld de,(freeNodePairList)
	ld (freeNodePairList),hl
	call UserRefToPointer
SetPairFree:
	call SetNodeFree
	inc hl
	ld de,0
	jr SetNodeFree


;; FreeNodeQuad:
;;
;; Free a node quad.  Same caveat as with FreeNode.
;;
;; Input:
;; - HL = reference to first of four nodes to be freed
;;
;; Destroys:
;; - AF, DE, HL

FreeNodeQuad:
	ld de,(freeNodeQuadList)
	ld (freeNodeQuadList),hl
	call UserRefToPointer
	call SetNodeFree
	inc hl
	ld de,0
	call SetNodeFree
	jr SetPairFree
