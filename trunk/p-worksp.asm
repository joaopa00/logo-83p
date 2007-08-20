;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Workspace Management Primitives
;;;


;; MAKE:
;;
;; MAKE word thing
;;
;; Store the given :thing in the variable named by :word.  Keep in
;; mind that a variable's name is not the same as its value!  You
;; almost always want to say
;;
;;   MAKE "FOO 42
;;
;; rather than
;;
;;   MAKE :FOO 42
;;
;; (The former assigns a value to the variable FOO, while the latter
;; uses the value of FOO as the name of a variable to create.)

p_MAKE:
	BUILTIN_PRIMITIVE 2, 2, 2, "S$"
	call Pop2OPS
	call SetSymbolVariable
	jp ReturnVoid


;; THING:
;;
;; THING word
;;
;; Output the value of the variable named by :word.  Note that you can
;; also use the notation :FOO as shorthand for THING "FOO.
;;
;; Also note the difference between THING "FOO and THING :FOO -- the
;; latter does not output the value of FOO, but rather the value of
;; the variable whose name is the value of FOO.

p_THING:
	BUILTIN_PRIMITIVE 1, 1, 1, "S$"
	call PopOPS
	call GetSymbolVariable
	ld de,voidNode
	or a
	sbc hl,de
	add hl,de
	ret nz
	BCALL _ErrUndefined


;; DEFINE:
;;
;; DEFINE word list
;;
;; Define a procedure called :word.  The first element of :list must
;; be a list of words, which are the names of the procedure's inputs.
;; The remaining elements of :list make up the procedure's body.

p_DEFINE:
	BUILTIN_PRIMITIVE 2, 2, 2, "Sn$"
	call Pop2OPS
	call SetSymbolProcedure
	jp ReturnVoid
 warning "FIXME: needs more error checking"


;; GC:
;;
;; GC
;;
;; Run the garbage collector, checking for memory that is no longer
;; being used by the interpreter.  You don't need to call the garbage
;; collector explicitly (garbage will be collected automatically when
;; necessary) but it may be possible to improve a program's
;; performance by judicious use of this primitive.

p_GC:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	call GCRun
	jp ReturnVoid


;; LOAD:
;;
;; LOAD word
;;
;; Read the file named by :word, and evaluate the instructions in that
;; file.

p_LOAD:
	BUILTIN_PRIMITIVE 1, 1, 1, "w$"
	call PopOPS
	push hl
	 call GetWordSize
	 ld a,h
	 or a
	 jr nz,LOAD_NameTooLong
	 ld a,l
	 cp 9
	 jr nc,LOAD_NameTooLong
	 pop hl
	push hl
	 ld de,OP1+1
	 call GetWordChars
	 xor a
	 ld (de),a
	 ld a,AppVarObj
	 ld (OP1),a

	 ld hl,0
	 call SetReadFileTIOS
	 pop de
	jr c,LOAD_FileError
	call SetReadConsole
LOAD_Loop:
	ld hl,appBackUpScreen
	ld bc,768
	call GetS_FileReadTIOS
	jr c,LOAD_Done
	BCALL _StrLength
	call ParseFileInput
	call IsTOLine
	jr nc,LOAD_ReadTOProc
	call EvalRecursiveVoid
	jr LOAD_Loop
LOAD_Done:
	jp ReturnVoid

LOAD_ReadTOProc:
	push hl			; save TO-line
	 ld hl,emptyNode
LOAD_ReadTOProcLoop:
	 push hl
	  ld hl,appBackUpScreen
	  ld bc,768
	  call GetS_FileReadTIOS
	  jr c,LOAD_ReadTOProcAbort
	  BCALL _StrLength
	  call ParseFileInput
	  push hl
	   call IsENDLine
	   pop hl
	  jr nc,LOAD_ReadTOProcDone
	  ex de,hl
	  pop hl
	 call ConcatenateLists
	 jr LOAD_ReadTOProcLoop
LOAD_ReadTOProcDone:
	  pop de
	 pop hl
	call ParseProcDefinition
	jr LOAD_Loop

LOAD_ReadTOProcAbort:
	  ld hl,EMsg_TOWithoutEND
	  ld a,E_Syntax
	  call ThrowError
	  ;; UNREACHABLE

LOAD_NameTooLong:
	 pop de
	jp ThrowBadInputError

LOAD_FileError:
	ld hl,EMsg_BadFile
	ld a,E_Invalid
	jp ThrowError


;; TO:
;;
;; TO name :var1 :var2 ...  (special form)
;;
;; TO begins the definition of a procedure.  The name of the procedure
;; and the names of its inputs follow TO on the command line, but are
;; not quoted.  Lines after the TO line form the body of the
;; procedure, until a line consisting of the single word END is read.
;;
;; TO may not be used within a procedure; it may only be typed
;; directly at the command prompt or within a file being loaded with
;; LOAD.

p_TO:
	BUILTIN_PRIMITIVE 0, 0, 0, ""
	ld hl,EMsg_NotInsideProcedure
	ld de,(evalNextProc)
	jp ThrowError

