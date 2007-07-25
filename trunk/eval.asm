;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Evaluating
;;;

;;; Evaluator state variables:
;;;
;;; evalList: Stores the next list node to be evaluated, essentially
;;;   the program counter.
;;;
;;; evalProcTop: Stores the location in the OPS of the "top" of the
;;;   current user procedure.  This is used to jump directly out of a
;;;   procedure, when calling STOP or OUTPUT.
;;;
;;; evalRunningProc: Stores the name of the currently-running user
;;;   procedure.
;;;
;;; evalNumArgs: Stores the number of arguments we have collected so
;;;   far.  This number of values have been pushed on the OPS.
;;;
;;; evalContext: Stores the evaluator context.  If this is a
;;;   nonnegative integer, it is the number of arguments that must
;;;   still be collected before evalNextProc can be invoked.  It
;;;   can also be one of the following special values:
;;;
;;;   CONTEXT_OPTIONAL: Either a single nonvoid value or 0 or more
;;;     void values accepted.
;;;
;;;   CONTEXT_VOID: 0 or more void values accepted.
;;;
;;;   CONTEXT_PAREN: Collecting values within parentheses (0 or more
;;;     nonvoid values accepted.)  (Not yet implemented.)
;;;
;;; evalNextProc: In the standard context or CONTEXT_PAREN, stores
;;;   the name of the procedure that will receive the arguments we are
;;;   collecting.  In CONTEXT_VOID and CONTEXT_OPTIONAL, stores the
;;;   address to which the evaluator should return when it finishes.


;; EvalRecursiveVoid:
;;
;; Evaluate a parsed expression which must not return a value.  This
;; routine is to be called from a primitive only.  It may not be
;; jumped to (you should JP to EvalTailVoid instead if possible.)
;;
;; Warning: this routine saves only the current PC within the
;; primitive, and not anything else you may have stored in the
;; hardware stack.  If you need to keep data around, you must use the
;; OPS.
;;
;; Input:
;; - HL = parsed list to evaluate
;;
;; Output:
;; - HL = result of evaluating
;;
;; Destroys:
;; - AF, BC, DE, IX
;; - All safe RAM areas
;; - Contents of stack

EvalRecursiveVoid:
	ld bc,CONTEXT_VOID
	jr EvalRecursive_Context


;; EvalRecursive:
;;
;; Evaluate a parsed expression which may optionally return a value.
;; This routine is to be called from a primitive only.  It may not be
;; jumped to (you should JP to EvalTail instead if possible.)
;;
;; Warning: this routine saves only the current PC within the
;; primitive, and not anything else you may have stored in the
;; hardware stack.  If you need to keep data around, you must use the
;; OPS.
;;
;; Input:
;; - HL = parsed list to evaluate
;;
;; Output:
;; - HL = result of evaluating
;;
;; Destroys:
;; - AF, BC, DE, IX
;; - All safe RAM areas
;; - Contents of stack

EvalRecursive:
	ld bc,CONTEXT_OPTIONAL
EvalRecursive_Context:
	call IsList
	jp c,TypeAssertionFailed

	;; Save current evalList, as well as the subr we're executing,
	;; and the current PC
	ex de,hl
	ld hl,(evalList)
	call PushOPS
	ld (evalList),de
	ld hl,(currentSubr)
	call PushOPS
	pop hl			; GETRETURN
	ld de,(subrStartAddr)
	or a
	sbc hl,de
	call PushOPS

	call Eval_Run

	push hl
	 call Pop3OPS		; HL = evalList, DE = currentSubr, BC = offset
	 ld (evalList),hl
	 ex de,hl
	 pop de
	call EnterSubr
	jp Eval_ReturnValue


;; EvalTailVoid:
;;
;; Evaluate a parsed expression which must not return a value.  This
;; routine is to be jumped to by a primitive only.  It is semantically
;; equivalent to calling EvalRecursiveVoid and then immediately
;; returning, but will be faster and use less memory.
;;
;; Input:
;; - HL = parsed list to evaluate

EvalTailVoid:
	ld bc,CONTEXT_VOID
	jr EvalTail_Context


;; EvalTail:
;;
;; Evaluate a parsed expression which may optionally return a value.
;; This routine is to be jumped to by a primitive only (it may not be
;; called.)  It is semantically equivalent to calling EvalRecursive
;; and then immediately returning, but will be faster and use less
;; memory.
;;
;; Input:
;; - HL = parsed list to evaluate

EvalTail:
	ld bc,CONTEXT_OPTIONAL
EvalTail_Context:
	call IsList
	jp c,TypeAssertionFailed

	ex de,hl
	ld hl,(evalList)
	ld (evalList),de

	;; If evalList = empty and evalContext = VOID or OPTIONAL,
	;; then we can avoid saving the old context
	ld de,emptyNode
	sbc hl,de
	jr z,EvalTail_OldEmpty
	add hl,de

EvalTail_Save:
	;; Otherwise, save current evalList
	call PushOPS
	call Eval_Run
	push hl
	 call PopOPS
	 ld (evalList),hl
	 pop hl
	jp Eval_ReturnValue

EvalTail_OldEmpty:
	call PopOPS
	bit 7,h
	jr z,EvalTail_NeedOldContext
	ld a,l
	cp CONTEXT_PAREN
	jr z,EvalTail_NeedOldContext

	;; OPTIONAL = FF, VOID = FE
	;; New context can be OPTIONAL only if old context was also OPTIONAL
	and c
	ld l,a
	ld (evalContext),hl
	call Pop2OPS
	ld (evalNumArgs),de	; this had better be zero, by the way
	ld (evalNextProc),hl	; old return address
	ld sp,(mainSP)
	jr Eval_Loop

EvalTail_NeedOldContext:
	;; If this ever actually happens, an error message is probably
	;; imminent
	call PushOPS
	ld hl,(evalList)
	jr EvalTail_Save


;; EvalMain:
;;
;; Evaluate a parsed expression.  This routine is to be called from
;; the main GUI only.
;;
;; Input:
;; - HL = parsed list to evaluate
;;
;; Output:
;; - HL = result of evaluating
;;
;; Destroys:
;; - AF, BC, DE, IX

EvalMain:
	ld (evalList),hl
	pop hl			; GETRETURN
	ld (evalNextProc),hl
	ld (mainSP),sp
	ld bc,CONTEXT_OPTIONAL
	jr Eval_Begin

Eval_Run:
	;; Begin evaluator with context BC
	pop hl			; GETRETURN
	ld (evalNextProc),hl
	ld sp,(mainSP)
Eval_Begin:
	ld (evalContext),bc
	ld hl,0
	ld (evalNumArgs),hl
	jr Eval_Loop

Eval_EOF:
	ld hl,(evalContext)
	bit 7,h
	jr z,Eval_NotEnoughArgs
	ld a,l
	cp CONTEXT_PAREN
	jr z,Eval_MissingRightParen

	;; Get final result
	ld hl,voidNode
	ld a,(evalNumArgs)	; must be 0 or 1
	or a
	jr z,Eval_EOF_Void
	call PopOPS
Eval_EOF_Void:
	ld de,(evalNextProc)
	push de			; SETRETURN
	ret

Eval_NotEnoughArgs:
Eval_MissingRightParen:
	BCALL _ErrSyntax
	;; UNREACHABLE


;;; Main Evaluator Loop

Eval_DecRemainingArgs:
	dec hl
Eval_SetContext:
	ld (evalContext),hl
Eval_Loop:
	ld hl,(evalContext)
	ld a,h
	or l
	jp z,Eval_GotAllArgs

	ld hl,(evalList)
	call IsList
	call c,TypeAssertionFailed
	jp z,Eval_EOF

	call GetListFirstButfirst
	ld (evalList),de

	;; HL = next thing in the list
	call GetType
	;; Symbol -> call procedure
	cp T_SYMBOL
	jr z,Eval_Symbol
	;; Quote -> input quoted word
	cp T_QUOTE
	jr z,Eval_Quote
	;; Quote -> get variable value
	cp T_COLON
	jr z,Eval_Colon
	;; Strings and characters -> convert either to symbol or number
	cp T_STRING
	jr z,Eval_String
	cp T_CHAR
	jr z,Eval_Char

	;; All other types are implicit arguments
Eval_GotArg:
	;; Add an argument to the stack
	call PushOPS
	ld hl,(evalNumArgs)
	inc hl
	ld (evalNumArgs),hl

	ld hl,(evalContext)
	bit 7,h
	jr z,Eval_DecRemainingArgs
	ld a,l
	cp CONTEXT_PAREN
	jr z,Eval_Loop
	cp CONTEXT_OPTIONAL
	jr nz,Eval_BadNonVoid
	ld hl,(evalList)
	call IsList
	jr z,Eval_Loop
Eval_BadNonVoid:
	BCALL _ErrSyntax	; non-void return in void context
	;; UNREACHABLE

Eval_Quote:
	call GetAtomData
	jr Eval_GotArg

Eval_Colon:
	call GetAtomData
	call WordToSymbol
	jr c,Eval_VariableUndefined
	call GetSymbolVariable
	ld de,voidNode
	or a
	sbc hl,de
	add hl,de
	jr nz,Eval_GotArg
Eval_VariableUndefined:
Eval_ProcedureUndefined:
	BCALL _ErrUndefined
	;; UNREACHABLE

Eval_Char:
Eval_String:
	call WordToSymbol
Eval_Symbol:
	push hl
	 ld hl,(evalNextProc)
	 call PushOPS
	 ld hl,(evalNumArgs)
	 call PushOPS
	 ld hl,(evalContext)
	 call PushOPS
	 pop hl
	ld (evalNextProc),hl
	call GetSymbolProcedure
	ld de,voidNode
	or a
	sbc hl,de
	jr z,Eval_ProcedureUndefined
	add hl,de
	call GetProcedureDefaultArity
	ld (evalContext),hl
	ld hl,0
	ld (evalNumArgs),hl
	jp Eval_Loop

Eval_GotAllArgs:
	ld hl,(evalNextProc)
	call IsWord
	jr c,Eval_InvokeAnonymous
	call GetSymbolProcedure
Eval_InvokeAnonymous:
	call GetType
	cp T_SUBR
	jr z,Eval_InvokeSubr
	cp T_LIST
	jr z,Eval_InvokeList
	BCALL _ErrDataType
	;; UNREACHABLE

Eval_InvokeSubr:
	ld bc,0
	ld de,(evalNumArgs)
	call EnterSubr
Eval_ReturnValue:
	push hl
	 call Pop3OPS
	 ld (evalContext),bc
	 ld (evalNumArgs),de
	 ld (evalNextProc),hl
	 pop de
	ld hl,voidNode
	or a
	sbc hl,de
	ex de,hl
	jp nz,Eval_GotArg
	ld hl,(evalContext)
	bit 7,h
	jr z,Eval_BadVoid
	ld a,l
	cp CONTEXT_PAREN
	jr z,Eval_BadVoid
	cp CONTEXT_VOID
	jp z,Eval_Loop
	ld hl,CONTEXT_VOID
	ld (evalContext),hl
	jp Eval_Loop
Eval_BadVoid:	
	BCALL _ErrSyntax	; void return in non-void context
	;; UNREACHABLE

Eval_InvokeList:
	;; Invoke a user procedure
	call GetListFirstButfirst
	push de			  ; save butfirst (body of procedure)
	 push hl		  ; safe first (list of args)

	  ;; Move arguments over temporarily from OPS to FPS
	  ld bc,(evalNumArgs)
	  ld a,b
	  or c
	  jr z,Eval_InvokeList_NoArgs
	  sla c
	  rl b
	  ld hl,(OPS)
	  ld de,(FPS)
	  ldir
	  ld (OPS),hl
	  ld (FPS),de
Eval_InvokeList_NoArgs:

	  ;; Check for tail calls
	  ld hl,(evalProcTop)
	  ld a,h
	  or l
	  jr z,Eval_InvokeList_NotTailCall

	  ;; Check for void tail call at end of procedure
	  ld hl,(OPS)		; -> old evalContext
	  ld a,(hl)
	  inc hl
	  bit 7,(hl)
	  inc hl
	  inc hl
	  inc hl
	  ld c,(hl)		; BC = old evalNextProc
	  inc hl
	  ld b,(hl)
	  jr z,Eval_InvokeList_NotVoidContext
	  cp CONTEXT_PAREN
	  jr z,Eval_InvokeList_NotVoidContext

	  ;; Check for void tail call at end of procedure
	  ld hl,emptyNode
	  ld de,(evalList)
	  sbc hl,de
	  jr nz,Eval_InvokeList_NotAtEnd
	  ld hl,Eval_ExitProcedure
	  sbc hl,bc
	  jr nz,Eval_InvokeList_NotTailCall
	  jp Eval_InvokeList_TailCallVoid

Eval_InvokeList_NotAtEnd:
	  ;; Check for void tail call before STOP
	  ex de,hl
	  call GetListFirst
	  ld de,STOP_Node0
	  sbc hl,de
	  jr nz,Eval_InvokeList_NotTailCall
	  jp Eval_InvokeList_TailCallVoid

Eval_InvokeList_NotVoidContext:
	  ;; Check for nonvoid tail call
	  ld hl,OUTPUT_Node0
	  or a
	  sbc hl,bc
	  jp z,Eval_InvokeList_TailCallNonVoid
	  ld hl,OUTPUT_Node1
	  or a
	  sbc hl,bc
	  jp z,Eval_InvokeList_TailCallNonVoid

Eval_InvokeList_NotTailCall:
	  pop hl		; retrieve list of args
	 ld ix,(FPS)
Eval_InvokeList_ArgsLoop:
	 ;; Save old values of local variables and give them their new
	 ;; values
	 call IsList
	 jr c,Eval_InvokeList_Error
	 jr z,Eval_InvokeList_ArgsDone
	 call GetListFirstButfirst
	 call WordToSymbol
	 jr c,Eval_InvokeList_Error
	 push de
	  push hl
	   call PushOPS		; save name of variable
	   call GetSymbolVariable
	   call PushOPS		; save old value
	   pop hl
	  dec ix
	  ld d,(ix)		; get new value (currently in FPS)
	  dec ix
	  ld e,(ix)
	  ld (FPS),ix
	  call SetSymbolVariable
	  pop hl
	 jr Eval_InvokeList_ArgsLoop
Eval_InvokeList_Error:
	 BCALL _ErrInvalid	; invalid procedure definition
	 ;; UNREACHABLE

Eval_InvokeList_ArgsDone:
	 ld hl,(evalNumArgs)
	 call PushOPS		; save number of local variables
	 ld hl,(evalList)
	 call PushOPS		; save evalList
	 ld hl,(evalRunningProc)
	 call PushOPS		; save evalRunningProc
	 ld hl,(evalProcTop)
	 call PushOPS		; save evalProcTop
	 ld hl,(OPS)
	 ld de,(OPBase)
	 or a
	 sbc hl,de
	 ld (evalProcTop),hl
Eval_InvokeList_Finish:
	 pop hl			; retrieve body of procedure
	ld (evalList),hl
	ld hl,(evalNextProc)
	call IsWord
	jr c,Eval_InvokeList_Anonymous
	ld (evalRunningProc),hl
Eval_InvokeList_Anonymous:

	ld bc,CONTEXT_VOID
	call Eval_Run
Eval_ExitProcedure:
	push hl
	 call Pop3OPS
	 ld (evalProcTop),bc
	 ld (evalRunningProc),de
	 ld (evalList),hl
	 call PopOPS
Eval_InvokeList_RestoreVarsLoop:
	 ;; restore local variables
	 ld a,h
	 or l
	 jr z,Eval_InvokeList_RestoreVarsDone
	 dec hl
	 push hl
	  call Pop2OPS		; HL = name, DE = value
	  call SetSymbolVariable
	  pop hl
	 jr Eval_InvokeList_RestoreVarsLoop
Eval_InvokeList_RestoreVarsDone:
	 pop hl
	jp Eval_ReturnValue


Eval_InvokeList_TailCallVoid:
Eval_InvokeList_TailCallNonVoid:
	  ld hl,(evalNextProc)
	  ld de,(evalRunningProc)
	  or a
	  sbc hl,de
	  jr z,Eval_InvokeList_TailCallSelf
	
	  ;; Non-self tail call: We need to check which local
	  ;; variables are to be saved.

	  ld hl,(evalProcTop)
	  ld de,(OPBase)
	  add hl,de
	  ld (OPS),hl

	  call Pop3OPS
	  ld (evalProcTop),bc
	  ld (evalRunningProc),de
	  ld (evalList),hl
	  call PopOPS
	  ld (evalNumArgs),hl

	  pop hl		; retrieve list of args
	 ld ix,(FPS)
Eval_InvokeList_TailCall_ArgsLoop:
	 call IsList
	 jp c,Eval_InvokeList_Error
	 jp z,Eval_InvokeList_ArgsDone
	 call GetListFirstButfirst
	 call WordToSymbol
	 jp c,Eval_InvokeList_Error
	 push de
	  push hl
	   ;; Search for this symbol in the local vars list.
	   ;; If it's already in the list, we don't need to add it.
	   ld bc,(evalNumArgs)
	   ex de,hl
	   ld hl,(OPS)
Eval_InvokeList_TailCall_ArgsSearchLoop:
	   ld a,b
	   or c
	   jr z,Eval_InvokeList_TailCall_ArgsSearchFail
	   inc hl
	   inc hl
	   ld a,(hl)
	   inc hl
	   cp e
	   jr nz,Eval_InvokeList_TailCall_ArgsSearchSkip
	   ld a,(hl)
	   cp d
	   jr z,Eval_InvokeList_TailCall_ArgsSearchSuccess
Eval_InvokeList_TailCall_ArgsSearchSkip:
	   inc hl
	   dec bc
	   jr Eval_InvokeList_TailCall_ArgsSearchLoop
Eval_InvokeList_TailCall_ArgsSearchFail:
	   pop hl
	  push hl
	   call PushOPS
	   call GetSymbolVariable
	   call PushOPS
	   ld hl,(evalNumArgs)
	   inc hl
	   ld (evalNumArgs),hl
Eval_InvokeList_TailCall_ArgsSearchSuccess:
	   pop hl
	  dec ix
	  ld d,(ix)
	  dec ix
	  ld e,(ix)
	  call SetSymbolVariable
	  pop hl
	 jr Eval_InvokeList_TailCall_ArgsLoop


Eval_InvokeList_TailCallSelf:
	  ;; Self tail call is a special case: we know we don't need to
	  ;; save any new local variables.
	  pop hl		; retrieve list of args
	 ld ix,(FPS)
Eval_InvokeList_TailCallSelf_ArgsLoop:
	 call IsList
	 jp c,Eval_InvokeList_Error
	 jr z,Eval_InvokeList_TailCallSelf_ArgsDone
	 call GetListFirstButfirst
	 call WordToSymbol
	 jp c,Eval_InvokeList_Error
	 push de
	  dec ix
	  ld d,(ix)
	  dec ix
	  ld e,(ix)
	  ld (FPS),ix
	  call SetSymbolVariable
	  pop hl
	 jr Eval_InvokeList_TailCallSelf_ArgsLoop
Eval_InvokeList_TailCallSelf_NoArgs:
Eval_InvokeList_TailCallSelf_ArgsDone:
	 ld hl,(evalProcTop)
	 ld de,(OPBase)
	 add hl,de
	 ld (OPS),hl
	 jp Eval_InvokeList_Finish

