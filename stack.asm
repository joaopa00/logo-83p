;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Stack Management
;;;

;; PushOPS:
;;
;; Push a value on the Operator Stack.
;;
;; Input:
;; - HL = value
;;
;; Destroys:
;; - F

PushOPS:
	push de
	 push hl
PushOPS_TryAgain:
	  ld hl,(FPS)
	  ld de,(OPS)
	  dec de
	  or a
	  sbc hl,de
	  jr nc,PushOPS_OutOfMem
PushOPS_AllIsWell:
 ifdef STACK_DEBUG
	  ld hl,(minOPS)
	  or a
	  sbc hl,de
	  jr c,PushOPS_NoSetMin
	  ld (minOPS),de
PushOPS_NoSetMin:
 endif
	  ex de,hl
	  pop de
	 ld (hl),d
	 dec hl
	 ld (hl),e
	 ld (OPS),hl
	 ex de,hl
	 pop de
	ret

PushOPS_OutOfMem:
	  push bc
	   push af
	    call GCRun
	    pop bc
	   ld a,b
	   pop bc
	  jr c,PushOPS_TryAgain

	  ld hl,(FPS)
	  ld de,(OPS)
	  dec de
	  or a
	  sbc hl,de
	  jr c,PushOPS_AllIsWell

	  BCALL _ErrMemory
	  ;; UNREACHABLE

;; PopOPS:
;;
;; Pop a value off the Operator Stack.
;;
;; Output:
;; - HL = value
;;
;; Destroys:
;; - F

PopOPS:
	push de
	 ld hl,(OPS)
	 inc hl
	 ld de,(OPBase)
	 or a
	 sbc hl,de
	 pop de
	jp nc,StackAssertionFailed
PopOPS_nc:
	push de
	 ld hl,(OPS)
	 ld e,(hl)
	 inc hl
	 ld d,(hl)
	 inc hl
	 ld (OPS),hl
	 ex de,hl
	 pop de
	ret


;; Pop2OPS:
;;
;; Pop two values off the Operator Stack.
;;
;; Output:
;; - DE = first value popped
;; - HL = second value popped
;;
;; Destroys:
;; - AF

Pop2OPS:
	ld hl,(OPS)
	inc hl
	inc hl
	inc hl
	ld de,(OPBase)
	or a
	sbc hl,de
	jp nc,StackAssertionFailed
Pop2OPS_nc:
	ld hl,(OPS)
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(hl)
	inc hl
	inc hl
	ld (OPS),hl
	dec hl
	ld h,(hl)
	ld l,a
	ret


;; Pop3OPS:
;;
;; Pop three values off the Operator Stack.
;;
;; Output:
;; - BC = first value popped
;; - DE = second value popped
;; - HL = third value popped
;;
;; Destroys:
;; - AF

Pop3OPS:
	ld hl,(OPS)
	ld de,5
	add hl,de
	ld de,(OPBase)
	sbc hl,de
	jp nc,StackAssertionFailed
Pop3OPS_nc:
	ld hl,(OPS)
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(hl)
	inc hl
	inc hl
	ld (OPS),hl
	dec hl
	ld h,(hl)
	ld l,a
	ret

