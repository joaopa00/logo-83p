;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Garbage Collection
;;;

;; GCQuick:
;;
;; Do a single pass over the Logo data, and free any nodes that could
;; not possibly be referenced.
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - All appvar addresses

GCQuick:
	ld a,(currentGCFlag)
	xor 80h
	ld (currentGCFlag),a

	;; Mark statically-referenced data
	ld hl,refDataStart
	ld bc,refDataSize
	call GCCheckBlock

	;; Special nodes that can't be destroyed
	ld de,emptyNode
	call GCMarkDE
	ld de,trueNode
	call GCMarkDE
	ld de,falseNode
	call GCMarkDE

	;; Mark data referenced by OPS
	ld hl,(OPBase)
	ld de,(OPS)
	or a
	sbc hl,de
	ld b,h
	ld c,l
	ex de,hl
	call GCCheckBlock

	;; Mark data (potentially) referenced by hardware stack
	ld hl,0
	add hl,sp
	ld a,h
	cpl
	ld b,a
	ld a,l
	cpl
	ld c,a
	inc bc
	call GCCheckBlock

	;; Scan nodes
	ld hl,(userNodeStartMinus2)
	inc hl
	inc hl
	ld bc,(uninitNodeStart)
	call GCQuick_Main

	;; Unlink any symbols that are about to be deleted
	ld hl,firstSymbol
	ld b,0
GCQuick_SymbolLoop:
	push hl
	 push bc
	  LOAD_DE_iBHL
GCQuick_SymbolLoop2:
	  bit 1,e
	  jr z,GCQuick_SymbolsDone
	  ex de,hl
	  call UserRefToPointer
	  inc hl
	  ld a,(currentGCFlag)
	  xor (hl)
	  ld b,a
	  inc hl
	  ld e,(hl)
	  inc hl
	  ld d,(hl)
	  ex de,hl
	  jp m,GCQuick_RemoveSymbol
	  pop af
	 pop af
	ld de,6
	ADD_BHL_DE
	jr GCQuick_SymbolLoop
GCQuick_RemoveSymbol:
	  ld de,6
	  ADD_BHL_DE
	  LOAD_DE_iBHL
	  pop bc
	 pop hl
	push hl
	 push bc
	  LOAD_iBHL_DE
	  jr GCQuick_SymbolLoop2
GCQuick_SymbolsDone:
	  pop af
	 pop af

	;; Free unreferenced nodes in reverse order (so the oldest
	;; nodes end up at the front of the free list)

	ld hl,(uninitNodeStart)
GCQuick_CleanupAgain:
	ld bc,(userNodeStartMinus2)
	inc bc
	inc bc
	inc bc
	jr GCQuick_CleanupBegin

GCQuick_CleanupNoObject:
	 call FreeNode
	 pop hl
GCQuick_CleanupBegin:
	ld a,(currentGCFlag)
	ld d,a
	or a
GCQuick_CleanupLoop:
	sbc hl,bc
	ret c
	add hl,bc
	dec hl
	dec hl
	dec hl
	ld a,(hl)
	dec hl
	xor d
	jp p,GCQuick_CleanupLoop
	ld a,(hl)
	cp T_FREE<<2
	jr z,GCQuick_CleanupLoop
 warning "FIXME: try to reclaim blocks of nodes as pairs or quads"
	push hl
	 call UserPointerToRef
	 and 7
	 jr nz,GCQuick_CleanupNoObject
	 push hl
	  push bc
	   call FreeObject
 warning "FIXME: remove symbols from list/obarray when deleting"
	   pop bc
	  pop hl
	 call UserRefToPointer
	 pop af
	jr GCQuick_CleanupAgain

GCQuick_List:
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	set 7,d
	call GCMarkDE
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	call GCMaybeMarkDE
	or a
	sbc hl,bc
	ret nc
GCQuick_Loop:
	add hl,bc
GCQuick_Main:
	ld a,(hl)
	rrca
	jr c,GCQuick_Skip
	rrca
	jr c,GCQuick_List
	rrca
	jr c,GCQuick_Atom
	cp T_SYMBOL/2
	jr z,GCQuick_Symbol
GCQuick_Skip:
	inc hl
	inc hl
	inc hl
	inc hl
	or a
	sbc hl,bc
	jr c,GCQuick_Loop
	ret

GCQuick_Atom:
	inc hl
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	call GCMaybeMarkDE
	or a
	sbc hl,bc
	jr c,GCQuick_Loop
	ret

GCQuick_Symbol:
	inc hl
	push bc
 ifndef NO_PAGED_MEM
	 ld b,(hl)
	 res 7,b
 endif
	 inc hl
	 ld e,(hl)
	 inc hl
	 ld d,(hl)
	 push hl
	  ;; We assume that voidNode = 8000h.  If any of the following
	  ;; values is not equal to 8000h, we know the symbol has a
	  ;; definition and therefore is considered in use (even if it
	  ;; isn't referenced at the moment.)
	  ex de,hl
	  ;; Procedure
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,d
	  xor 80h
	  or e
	  ld c,a
	  call GCMaybeMarkDE
	  ;; Variable
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,d
	  xor 80h
	  or e
	  or c
	  ld c,a
	  call GCMaybeMarkDE
	  ;; Plist
	  LOAD_DE_iBHL
	  ld a,d
	  xor 80h
	  or e
	  or c
	  call GCMaybeMarkDE
	  pop hl
	 or a
	 jr z,GCQuick_SymbolDead
	 dec hl
	 dec hl
	 ld a,(currentGCFlag)
	 ld d,(hl)
	 res 7,d
	 or d
	 ld (hl),a
	 inc hl
	 inc hl
GCQuick_SymbolDead:
	 inc hl
	 pop bc
	sbc hl,bc
	jr c,GCQuick_Loop
	ret


;; GCCheckBlock:
;;
;; Check for possible references in a block of data, and mark those
;; nodes as referenced.
;;
;; Input:
;; - HL = start of block
;; - BC = length of block
;;
;; Destroys:
;; - AF, BC, DE, HL

GCCheckBlock:
	res 0,c
	push hl
GCCheckBlock_Loop1:
	 pop hl
GCCheckBlock_Loop:
	ld a,b
	or c
	ret z

	ld e,(hl)
	inc hl
	ld a,(hl)
	inc hl
	dec bc
	dec c
	add a,a
	jr nc,GCCheckBlock_Loop
	bit 0,e
	jr nz,GCCheckBlock_Loop
	bit 1,e
	jr z,GCCheckBlock_Loop
	ld d,a
	push hl
	 ld hl,(userNodeStartMinus2)
	 add hl,de
	 jr c,GCCheckBlock_Loop1
	 ld de,(uninitNodeStart)
	 sbc hl,de
	 jr nc,GCCheckBlock_Loop1
	 add hl,de
	 inc hl
	 ld a,(currentGCFlag)
	 ld d,(hl)
	 res 7,d
	 or d
	 ld (hl),a
	 pop hl
	jr GCCheckBlock_Loop


;; GCMaybeMarkDE:
;;
;; If DE is a valid node reference, mark that node as referenced.
;;
;; Input:
;; - DE = possible reference
;;
;; Destroys:
;; - F, DE

GCMaybeMarkDE:
	bit 7,d
	ret z
	bit 0,e
	ret nz
	bit 1,e
	ret z
GCMarkDE:
	push hl
	 ld hl,(userNodeStartMinus2)
	 res 7,d
	 add hl,de
	 ld e,a
	 inc hl
	 ld a,(currentGCFlag)
	 ld d,(hl)
	 res 7,d
	 or d
	 ld (hl),a
	 ld a,e
	 pop hl
	ret
