;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Evaluating
;;;

;; EvalMain:
;;
;; Evaluate a parsed expression (like RUN.)  Note that this routine
;; may not return.
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
	ex de,hl
	ld hl,(evalList)
	call PushOPS
	ld (evalList),de
	ld hl,0
	ld (evalNumArgs),hl
	ld (evalCurrentProc),hl
	ld hl,CONTEXT_OPTIONAL+1
Eval_DecRemainingArgs:
	dec hl
Eval_SetRemainingArgs:
	ld (evalRemainingArgs),hl

Eval_Loop:
	ld hl,(evalRemainingArgs)
	ld a,h
	or l
	jp z,Eval_GotAllArgs

	ld hl,(evalList)
	call IsList
	jp c,TypeAssertionFailed
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
; 	cp T_STRING
; 	jr z,Eval_String
; 	cp T_CHAR
; 	jr z,Eval_Char

	;; All other types are implicit arguments
Eval_GotArg:
	;; Add an argument to the stack
	call PushOPS
	ld hl,(evalNumArgs)
	inc hl
	ld (evalNumArgs),hl

	ld hl,(evalRemainingArgs)
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
	call GetSymbolVariable
	ld de,voidNode
	or a
	sbc hl,de
	add hl,de
	jr nz,Eval_GotArg	
Eval_ProcedureUndefined:
	BCALL _ErrUndefined
	;; UNREACHABLE

Eval_Symbol:
	push hl
	 ld hl,(evalCurrentProc)
	 call PushOPS
	 ld hl,(evalNumArgs)
	 call PushOPS
	 ld hl,(evalRemainingArgs)
	 call PushOPS
	 pop hl
	ld (evalCurrentProc),hl
	call GetSymbolProcedure
	ld de,voidNode
	or a
	sbc hl,de
	add hl,de
	jr z,Eval_ProcedureUndefined
	call GetProcedureDefaultArity
	ld (evalRemainingArgs),hl
	ld hl,0
	ld (evalNumArgs),hl
	jp Eval_Loop

Eval_GotAllArgs:
	ld hl,(evalCurrentProc)
	call GetSymbolProcedure
	call GetType
	cp T_SUBR
	jr z,Eval_InvokeSubr
;	cp T_LIST
;	jr z,Eval_InvokeList
	BCALL _ErrDataType
	;; UNREACHABLE

Eval_InvokeSubr:
	ld de,Eval_ReturnFromSubr
	push de			; SETRETURN
	call GetNodeContents
	ld de,5
	add hl,de
	push hl			; SETRETURN
	ld hl,(evalNumArgs)
	ret
Eval_ReturnFromSubr:
	push hl
	 call PopOPS
	 ld (evalRemainingArgs),hl
	 call PopOPS
	 ld (evalNumArgs),hl
	 call PopOPS
	 ld (evalCurrentProc),hl
	 pop de
	ld hl,voidNode
	or a
	sbc hl,de
	ex de,hl
	jp nz,Eval_GotArg
	ld hl,(evalRemainingArgs)
	bit 7,h
	jr z,Eval_BadVoid
	ld a,l
	cp CONTEXT_PAREN
	jr z,Eval_BadVoid
	cp CONTEXT_VOID
	jp z,Eval_Loop
	ld hl,CONTEXT_VOID
	ld (evalRemainingArgs),hl
	jp Eval_Loop

Eval_BadVoid:	
	BCALL _ErrSyntax	; void return in non-void context
	;; UNREACHABLE

Eval_EOF:
	ld hl,(evalCurrentProc)
	ld a,h
	or l
	jr nz,Eval_NotEnoughArgs
	ld hl,(evalNumArgs)
	ld a,h
	or l
	ld de,voidNode
	jr z,Eval_EOF_Void
	call PopOPS
	ex de,hl
Eval_EOF_Void:
	call PopOPS
	ld (evalList),hl
	ex de,hl
	ret

Eval_NotEnoughArgs:
	BCALL _ErrSyntax
	;; UNREACHABLE
