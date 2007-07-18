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
	  ld hl,(FPS)
	  ld de,(OPS)
	  dec de
	  or a
	  sbc hl,de
	  jr nc,PushOPS_OutOfMem
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
	  ;; [GC]
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
