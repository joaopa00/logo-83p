;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Garbage Collection
;;;


;; BeginGenerator:
;;
;; Call this routine to mark a block of code during which the garbage
;; collector may be run at most once.  This represents a promise that
;; the code within the "generator" only creates new nodes and cannot
;; remove any old node references.  Be sure to call EndGenerator when
;; you are done.
;;
;; Destroys:
;; - AF

BeginGenerator:
	ld a,(gcGenState)
	add a,2
	ret c			; Note: we probably won't ever have
				; more than 127 nested generators, but
				; if we do, the worst that could
				; happen is we call the GC without
				; needing to.
	ld (gcGenState),a
	ret


;; EndGenerator:
;;
;; Call this routine at the end of a generator.
;;
;; Destroys:
;; - AF

EndGenerator:
	ld a,(gcGenState)
	sub 2
	ret c
	ld (gcGenState),a
	dec a
	ret nz
	ld (gcGenState),a
	ret


;; GCRun:
;;
;; Run the garbage collector.
;;
;; Output:
;; - CF set if GC incomplete (i.e., calling GCRun again might release
;;   more memory.)
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - All appvar addresses

GCRun:
	xor a
	ld (gcFinishState),a
	ld a,(gcGenState)
	or a
	jr z,GCRunNormal
	rrca			; if bit 0 is set, we've already done
				; a complete GC within this generator
				; block
	ccf
	ret nc
	push ix			; IX isn't used by the GC, but save it
				; on the stack anyway, just in case it
				; contains a reference
	 call GCDeep
	 pop ix
	ret c
	ld a,(gcGenState)
	inc a
	ld (gcGenState),a
	ret

GCRunNormal:
	push ix
	 call GCDeep
	 pop ix
	ret


;; GCQuick:
;;
;; Do a single pass over the Logo data, and free any nodes that could
;; not possibly be referenced.
;;
;; Output:
;; - CF clear if GC complete (nothing found to delete)
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - All appvar addresses

GCQuick:
	ld a,i
	push af
	 di

GCQuick_Run:

;	 ld a,(currentGCFlag)
;	 xor 80h
;	 ld (currentGCFlag),a

	 ;; Mark statically-referenced data
	 ld hl,refDataStart
	 ld bc,refDataSize
	 call GCQuickCheckBlock

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
	 call GCQuickCheckBlock

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
	 call GCQuickCheckBlock

	 ;; Scan nodes
	 ld hl,(userNodeStartMinus2)
	 inc hl
	 inc hl
	 ld bc,(uninitNodeStart)
	 call GCQuick_Main

	 call GCFinish
	 pop af
	jp po,GCQuick_NoEI
	ei
GCQuick_NoEI:
	ld a,(gcFinishState)
	add a,-1
	ret


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

; 	 ld a,(currentGCFlag)
; 	 ld d,(hl)
; 	 res 7,d
; 	 or d
; 	 ld (hl),a
	 set 7,(hl)

	 inc hl
	 inc hl
GCQuick_SymbolDead:
	 inc hl
	 pop bc
	sbc hl,bc
	jr c,GCQuick_Loop
	ret


;; GCQuickCheckBlock:
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

GCQuickCheckBlock:
	res 0,c
	push hl
GCQuickCheckBlock_Loop1:
	 pop hl
GCQuickCheckBlock_Loop:
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
	jr nc,GCQuickCheckBlock_Loop
	bit 0,e
	jr nz,GCQuickCheckBlock_Loop
	bit 1,e
	jr z,GCQuickCheckBlock_Loop
	rrca
	ld d,a
	push hl
	 ld hl,(userNodeStartMinus2)
	 add hl,de
	 jr c,GCQuickCheckBlock_Loop1
	 ld de,(uninitNodeStart)
	 sbc hl,de
	 jr nc,GCQuickCheckBlock_Loop1
	 add hl,de
	 inc hl
; 	 ld a,(currentGCFlag)
; 	 ld d,(hl)
; 	 res 7,d
; 	 or d
; 	 ld (hl),a
	 set 7,(hl)
	 pop hl
	jr GCQuickCheckBlock_Loop



;; GCDeep:
;;
;; Recursively scan all existing Logo data, and free any nodes that
;; cannot be reached.  (If lists are nested too deeply, this may not
;; be possible, in which case fall back to running GCQuick.)
;;
;; Output:
;; - CF clear if GC complete (deep check finished; or deep check was
;;   aborted and quick check found nothing to delete)
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - All appvar addresses

GCDeep:
	ld a,i
	or a
	push af
	 di
;	 ld a,(currentGCFlag)
;	 xor 80h
;	 ld (currentGCFlag),a

	 ld (gcDeepPanicSP),sp

	 ;; Mark statically-referenced data
	 ld hl,refDataStart
	 ld bc,refDataSize
	 call GCDeepCheckBlock

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
	 call GCDeepCheckBlock

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
	 call GCDeepCheckBlock

	 ;; Mark symbols that have values (and mark their values)
	 ld hl,(firstSymbol)
GCDeep_SymbolLoop:
	 bit 1,l
	 jr z,GCDeep_SymbolsDone
	 call UserRefToPointer
	 inc hl
	 push hl

 ifndef NO_PAGED_MEM
	  ld b,(hl)
	  res 7,b
 endif
	  inc hl
	  ld e,(hl)
	  inc hl
	  ld d,(hl)
	  ex de,hl

	  ;; Procedure
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,d
	  xor 80h
	  or e
	  ld c,a
	  call GCMaybeDeepCheck

	  ;; Variable
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,d
	  xor 80h
	  or e
	  or c
	  ld c,a
	  call GCMaybeDeepCheck

	  ;; Plist
	  LOAD_DE_iBHL
	  INC_BHL
	  ld a,d
	  xor 80h
	  or e
	  or c
	  call GCMaybeDeepCheck

	  ;; Next symbol
	  LOAD_DE_iBHL
	  pop hl
	 or a
	 jr z,GCDeep_SymbolDead

; 	 ld a,(currentGCFlag)
; 	 ld c,(hl)
; 	 res 7,c
; 	 or c
; 	 ld (hl),a
	 set 7,(hl)

GCDeep_SymbolDead:
	 ex de,hl
	 jr GCDeep_SymbolLoop

GCDeep_SymbolsDone:
	 call GCFinish
	 pop af
	ret po
	ei
	ret


GCMaybeDeepCheck:
	bit 7,d
	ret z
	bit 0,e
	ret nz
	bit 1,e
	ret z
	push af
	 push bc
	  push hl
	   call GCDeepCheck
	   pop hl
	  pop bc
	 pop af
	ret


;; GCDeepCheck:
;;
;; Recursively mark a given node as referenced.
;;
;; Input:
;; - DE = reference
;;
;; Destroys:
;; - AF, BC, DE, HL

GCDeepCheck:
     ld (gcDeepTempSP),sp
     ld sp,gcDeepMemEnd
     ld hl,0
     push hl
GCDeepCheck_Loop:
     bit 7,d
     jr z,GCDeepCheck_Skip
     bit 1,e
     jr z,GCDeepCheck_Skip
     ld hl,(userNodeStartMinus2)
     res 7,d
     add hl,de
     ld c,(hl)
     inc hl

;     ld a,(currentGCFlag)
;     xor (hl)
;     jp p,GCDeepCheck_Skip
     bit 7,(hl)
     jr nz,GCDeepCheck_Skip

;     ld a,80h
;     xor (hl)
;     ld (hl),a
     set 7,(hl)

     ld a,c
     rrca
     jr c,GCDeepCheck_Skip
     rrca
     jr c,GCDeepCheck_List
     rrca
     jr c,GCDeepCheck_Atom
GCDeepCheck_Skip:
     pop de
     ld a,d
     or e
     jr nz,GCDeepCheck_Loop
     ld sp,(gcDeepTempSP)
     ret

GCDeepCheck_Atom:
     inc hl
     ld e,(hl)
     inc hl
     ld d,(hl)
     jr GCDeepCheck_Loop

GCDeepCheck_List:
     ex de,hl
     ld hl,0FFFFh-gcDeepMemStart
     add hl,sp
     jr nc,GCDeepCheck_Panic
     ex de,hl
     ld b,(hl)
     set 7,b
     push bc
     inc hl
     ld e,(hl)
     inc hl
     ld d,(hl)
     jr GCDeepCheck_Loop

GCDeepCheck_Panic:
     ld sp,(gcDeepPanicSP)
     jp GCQuick_Run


;; GCDeepCheckBlock:
;;
;; Check for possible references in a block of data, and recursively
;; mark those nodes as referenced.
;;
;; Input:
;; - HL = start of block
;; - BC = length of block
;;
;; Destroys:
;; - AF, BC, DE, HL

GCDeepCheckBlock:
	res 0,c
	push hl
GCDeepCheckBlock_Loop1:
	 pop hl
GCDeepCheckBlock_Loop:
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
	jr nc,GCDeepCheckBlock_Loop
	bit 0,e
	jr nz,GCDeepCheckBlock_Loop
	bit 1,e
	jr z,GCDeepCheckBlock_Loop
	rrca
	ld d,a
	push hl
	 ld hl,(userNodeStartMinus2)
	 add hl,de
	 jr c,GCDeepCheckBlock_Loop1
	 set 7,d
	 push bc
	  ld bc,(uninitNodeStart)
	  sbc hl,bc
	  call c,GCDeepCheck
	  pop bc
	 pop hl
	jr GCDeepCheckBlock_Loop


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

; 	 ld a,(currentGCFlag)
; 	 ld d,(hl)
; 	 res 7,d
; 	 or d
; 	 ld (hl),a
	 set 7,(hl)

	 ld a,e
	 pop hl
	ret


;; GCFinish:
;;
;; Delete all unmarked nodes.
;;
;; Output:
;; - (gcFinishState) = nonzero if any nodes were deleted
;;
;; Destroys:
;; - AF, BC, DE, HL
;; - All appvar addresses

GCFinish:
	;; Unlink any symbols that are about to be deleted
	ld hl,firstSymbol
	xor a
	ld (gcFinishState),a
	ld b,a
GCFinish_SymbolLoop:
	push hl
	 push bc
	  LOAD_DE_iBHL
GCFinish_SymbolLoop2:
	  bit 1,e
	  jr z,GCFinish_SymbolsDone
	  ex de,hl
	  call UserRefToPointer
	  inc hl

; 	  ld a,(currentGCFlag)
; 	  xor (hl)
	  ld a,(hl)
	  or a

	  ld b,a
	  inc hl
	  ld e,(hl)
	  inc hl
	  ld d,(hl)
	  ex de,hl

;	  jp m,GCFinish_RemoveSymbol
	  jp p,GCFinish_RemoveSymbol

	  pop af
	 pop af
	ld de,6
	ADD_BHL_DE
	jr GCFinish_SymbolLoop
GCFinish_RemoveSymbol:
	  ld de,6
	  ADD_BHL_DE
	  LOAD_DE_iBHL
	  pop bc
	 pop hl
	push hl
	 push bc
	  LOAD_iBHL_DE
	  jr GCFinish_SymbolLoop2
GCFinish_SymbolsDone:
	  pop af
	 pop af

	;; Free unreferenced nodes in reverse order (so the oldest
	;; nodes end up at the front of the free list)

	ld hl,(uninitNodeStart)
GCFinish_CleanupAgain:
	ld bc,(userNodeStartMinus2)
	inc bc
	inc bc
	inc bc
	jr GCFinish_CleanupBegin

GCFinish_CleanupNoObject:
	 call FreeNode
	 pop hl
GCFinish_CleanupBegin:
; 	ld a,(currentGCFlag)
; 	ld d,a
	or a
GCFinish_CleanupLoop:
	sbc hl,bc
	ret c
	add hl,bc
	dec hl
	dec hl
	dec hl

; 	ld a,(hl)
; 	dec hl
; 	xor d
; 	jp p,GCFinish_CleanupLoop

	bit 7,(hl)
	res 7,(hl)
	dec hl
	jr nz,GCFinish_CleanupLoop

	ld a,(hl)
	cp T_FREE<<2
	jr z,GCFinish_CleanupLoop
	ld (gcFinishState),a	; first byte of a valid node cannot be zero
 warning "FIXME: try to reclaim blocks of nodes as pairs or quads"
	push hl
	 call UserPointerToRef
	 and 7
	 jr nz,GCFinish_CleanupNoObject
	 push hl
	  push bc
	   call FreeObject
	   pop bc
	  pop hl
	 call UserRefToPointer
	 pop af
	jr GCFinish_CleanupAgain
