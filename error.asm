;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Error Handling
;;;


;; ThrowError:
;;
;; Throw a custom error, with an included description.
;;
;; Input:
;; - HL = address of error message
;; - DE = first parameter for error message
;; - BC = second parameter for error message
;; - A = TIOS error code

ThrowError:
	ld (errorMessage),hl
	ld (errorParam1),de
	ld (errorParam2),bc
	BCALL _JError
	;; UNREACHABLE


;; ThrowBadInputError:
;;
;; Throw an error for an invalid input to the current primitive.
;;
;; Input:
;; - DE = invalid input value

ThrowBadInputError:
	ld hl,EMsg_BadInput
	ld bc,(evalNextProc)
	ld a,E_Argument
	jr ThrowError


;; PrintErrorMessage:
;;
;; Print out the most recent error message.
;;
;; Destroys:
;; - AF, BC, DE, HL

PrintErrorMessage:
	ld a,(curCol)
	or a
	jr z,PrintErrorMessage_SameLine
	call NewLine
PrintErrorMessage_SameLine:
	ld hl,(errorMessage)
	ld a,h
	or l
	jr z,PrintErrorMessage_System
PrintErrorMessage_Loop:
	ld a,(hl)
	inc hl
	or a
	jr z,PrintErrorMessage_Done
	cp '#'
	jr z,PrintErrorMessage_Param
	cp '%'
	jr z,PrintErrorMessage_Param
	call PutC
	jr PrintErrorMessage_Loop
PrintErrorMessage_Done:
	ld hl,0
	ld (errorMessage),hl
	ld (errorParam1),hl
	ld (errorParam2),hl
	jp NewLine

PrintErrorMessage_Param:
	ld b,a
	ld a,(hl)
	inc hl
	push hl
	 ld hl,(errorParam1)
	 cp '1'
	 jr z,PrintErrorMessage_Param1
	 ld hl,(errorParam2)
PrintErrorMessage_Param1:
	 ld a,b
	 cp '#'
	 jr z,PrintErrorMessage_ParamShow
	 call Print
	 pop hl
	jr PrintErrorMessage_Loop
PrintErrorMessage_ParamShow:
	 call Show
	 pop hl
	jr PrintErrorMessage_Loop

PrintErrorMessage_System:
	;; Capture the system error message using the localize hook
	ld a,(errNo)
	or a
	ret z

	;; Get the "ERR:" string
	ld hl,ERR_Str
	bit localizeHookActive,(iy+localizeHookFlag)
	jr z,PrintErrorMessage_System_NoHook1
	ld a,0Bh
	BCALL _CallLocalizeHook
PrintErrorMessage_System_NoHook1:
	call PutS

	;; Get the default error message
	ld hl,(localizeHookPtr)
	push hl
	 ld hl,(localizeHookPtr+2)
	 push hl
	  ld a,(flags+localizeHookFlag)
	  push af
	   ld hl,DummyLocalizeHook
	   in a,(6)
	   BCALL _EnableLocalizeHook
	   BCALL _DispErrorScreen
	   res curLock,(iy+curFlags)
	   pop af
	  ld (flags+localizeHookFlag),a
	  pop hl
	 ld (localizeHookPtr+2),hl
	 pop hl
	ld (localizeHookPtr),hl

	;; Get the localized error message
	ld hl,(errorMessage)
	bit localizeHookActive,(iy+localizeHookFlag)
	jr z,PrintErrorMessage_System_NoHook2
	ld a,(errNo)
	and 7Fh
	dec a
	ld e,a
	ld d,0
	ld a,0Ch
	BCALL _CallLocalizeHook
PrintErrorMessage_System_NoHook2:
	ld a,h
	or l
	jp z,NewLine
	ld de,0
	ld (errorMessage),de

	;; Copy string to RAM if necessary
	bit 7,h
	jr nz,PrintErrorMessage_System_NoCopy
	bit 6,h
	jr z,PrintErrorMessage_System_NoCopy
	push hl
	 ld hl,_DispErrorScreen+2
	 ld a,0FBh
	 BCALL _LoadAIndPaged
	 pop hl
	ld de,appErr1
	ld bc,26
	push de
	 BCALL _FlashToRam
	 pop hl
PrintErrorMessage_System_NoCopy:

	;; Skip the FF flag byte at the start, if necessary
	ld a,(hl)
	inc a
	jr nz,PrintErrorMessage_System_NoSkip
	inc hl
PrintErrorMessage_System_NoSkip:
	call PutS
	call NewLine
	xor a
	ld (errNo),a
	ret

DummyLocalizeHook:
	db 83h
	cp 0Ch
	jr nz,DummyLocalizeHook_NotErrMessage
	ld a,(errNo)
	and 7Fh
	dec a
	cp e
	jr nz,DummyLocalizeHook_WrongErrMessage
	ld (errorMessage),hl
DummyLocalizeHook_WrongErrMessage:
	ld hl,appErr1
	ld (hl),0
	ret
DummyLocalizeHook_NotErrMessage:
	cp 0Bh
	ret nz
	jr DummyLocalizeHook_WrongErrMessage

ERR_Str:
	db "ERR:",0

EMsg_OutOfMemory:
	db "Out of memory",0
EMsg_TooManyLParens:
	db "Too many ('s",0
EMsg_TooManyLBracks:
	db "Too many ", LlBrack, "'s",0
EMsg_UnexpectedRBrack:
	db "Unexpected ", LrBrack, 0
EMsg_NotEnoughInputs:
	db "Not enough", Lenter
	db "inputs to", Lenter
	db "%1", 0
EMsg_SayWhatToDo:
	db "You don't say", Lenter
	db "what to do with", Lenter
	db "#1", 0
EMsg_HasNoValue:
	db "%1",Lenter
	db "has no value", 0
EMsg_DontKnowHow:
	db "I don't know how", Lenter
	db "to %1", 0
EMsg_BadInputAPPLY:
	db "Invalid input", Lenter
	db "#1", Lenter
	db "to APPLY", 0
EMsg_BadInput:
	db "Invalid input", Lenter
	db "#1", Lenter
	db "to %2", 0
EMsg_DidntOutput:
	db "%1", Lenter
	db "didn't output to", Lenter
	db "%2", 0
EMsg_OnlyInsideProcedure:
	db "%1 can only", Lenter
	db "be used inside", Lenter
	db "a procedure", 0
EMsg_NotInsideProcedure:
	db "%1 may not be", Lenter
	db "used inside a", Lenter
	db "procedure", 0
EMsg_TOWithoutEND:
	db "TO without END", 0
EMsg_BadFile:
	db "Cannot read file", Lenter
	db "%1", 0
;	    ----====----====
