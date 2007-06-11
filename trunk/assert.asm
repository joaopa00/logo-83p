;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Assertions
;;;

;;; Failing an assertions, unlike a normal error, indicates that the
;;; programmer screwed up somewhere.  Eventually we will be able to
;;; disable some of the internal assertions, and make stuff run
;;; faster.

;;; This will also eventually be more friendly.

StackAssertionFailed:
TypeAssertionFailed:
	push hl
	 BCALL _ClrLCDFull
	 ld hl,0
	 ld (curRow),hl
	 ld hl,AssertionFailedStr
	 BCALL _PutS
	 ex (sp),hl
	 BCALL _DispHL
	 BCALL _NewLine
	 pop hl
	BCALL _PutS
	pop hl			; GETRETURN
	push hl			; SETRETURN
	BCALL _DispHL
	BCALL _GetKey
	BCALL _ErrArgument

AssertionFailedStr:
	db "Assertion failed"
	db "HL: ",0
	db "PC: ",0
