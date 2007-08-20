;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Extra OS definitions
;;;

_HomeUp equ 4558h
_DispErrorScreen equ 49DEh
_LoadAIndPaged equ 8051h

localizeHookPtr equ 9BCCh
_EnableLocalizeHook equ 4F93h
_DisableLocalizeHook equ 4F96h
_CallLocalizeHook equ 4006h
localizeHookActive equ 1
localizeHookFlag equ 35h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Macros
;;;

BCALL macro addr
	nolist
	rst 28h
	;; UNREACHABLE
	dw addr
	list
	.endm

BJUMP macro addr
	nolist
	call 50h
	;; UNREACHABLE
	dw addr
	list
	.endm

NO_BYTE_CARRY macro startaddr
	nolist
	if ($ / 256) != (startaddr / 256)
	error "NO_BYTE_CARRY zone violated.  Try rearranging data."
	endif
	list
	.endm

SYMBOL macro proc,var,plist,next,name
	dw proc,var,plist,next,(.strlen. name)
	db name
	.endm

NODE macro type,page,addr
	db type<<2, page
	dw addr
	.endm

BUILTIN_PRIMITIVE macro dflt,min,max,typestr
	db 1, dflt, min, max
	dw 0
 if (.strlen. typestr) > 0
	call CheckInputTypes
	;; UNREACHABLE
	db typestr
 endif
	.endm


NO_PAGED_MEM equ 1

 ifdef NO_PAGED_MEM

ADD_BHL_DE macro
	add hl,de
	.endm

LOAD_A_iBHL macro
	ld a,(hl)
	.endm

LOAD_HL_iBHL macro
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	.endm

LOAD_DE_iBHL macro
	ld e,(hl)
	inc hl
	ld d,(hl)
	.endm

LOAD_iBHL_DE macro
	ld (hl),e
	inc hl
	ld (hl),d
	.endm

INC_BHL macro
	inc hl
	.endm

FLASH_TO_RAM macro
	ldir
	.endm

 else

ADD_BHL_DE macro
	call Add_BHL_DE
	.endm

LOAD_A_iBHL macro
	call Load_A_iBHL
	.endm

LOAD_HL_iBHL macro
	call Load_HL_iBHL
	.endm

LOAD_DE_iBHL macro
	call Load_DE_iBHL
	.endm

LOAD_iBHL_DE macro
	call Load_iBHL_DE
	.endm

INC_BHL macro
	call Inc_BHL
	.endm

FLASH_TO_RAM macro
	call FlashToRAM
	.endm

 endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; RAM Areas
;;;

 org cmdShadow

savedData:

appvarStart:		ds 2
userNodeStartMinus2:	ds 2
uninitNodeStart:	ds 2
uninitNodeEnd:		ds 2
gcGenState:		ds 1
freeNodeList:		ds 2
freeNodePairList:	ds 2
freeNodeQuadList:	ds 2
firstSymbol:		ds 2
getCharFunc:		ds 2
getSFunc:		ds 2
mainSP:			ds 2
evalProcTop:		ds 2

refDataStart:

evalList:		ds 2
evalRunningProc:	ds 2

savedDataSize equ $ - savedData

parseParent:		ds 2
parseCurrent:		ds 2
symbolSearchLen:
newSymbol:		ds 2
evalNextProc:		ds 2
evalNumArgs:		ds 2
evalContext:		ds 2
currentSubr:		ds 2
errorParam1:		ds 2
errorParam2:		ds 2

refDataSize equ $ - refDataStart

errorMessage:		ds 2
subrStartAddr:		ds 2

gcDeepPanicSP:		ds 2
gcDeepTempSP:		ds 2
gcFinishState:		ds 1

equalOPS:		
getSBuffer:		ds 2
getSBufferEnd:		ds 2
parseCallback:		ds 2

fileReadOffset:		ds 2
fileReadSize:		ds 2
fileReadPage:		ds 1
NFBuffer:		ds 24

;STACK_DEBUG equ 1
;minOPS:		ds 2
	
 if $ > cmdShadow+128
 error "Data does not fit in saferam"
 endif

appvarStartMPtr		equ iMathPtr1 ; global
insertionMPtr		equ iMathPtr2 ; used when inserting memory
newObjectMPtr		equ iMathPtr3 ; used when creating object
parseBufferMPtr		equ iMathPtr4 ; used by parser
symbolSearchMPtr	equ iMathPtr5 ; used when creating symbols
fileReadStartMPtr	equ asm_data_ptr1

subrExecMem		equ appBackUpScreen

gcDeepMemStart	equ saveSScreen
gcDeepMemEnd 	equ saveSScreen+768


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Types
;;;

;;; Note: even-numbered types have data sections.  Odd-numbered types
;;; don't.

;;; Pseudo-types
T_FREE		equ 1		; Free node (not a valid data type)
T_VOID		equ 3		; Void (procedure didn't output, or
				; an undefined variable/procedure)

;;; Internal types
T_SUBR		equ 4		; Subroutine object

;;; List types
T_LIST		equ 5		; Nonempty list, [a ...]
T_EMPTY		equ 7		; The empty list, []

;;; Array types
T_ARRAY		equ 8		; Standard array, {1 2 3}
T_ARRAY_OFFSET	equ 10		; Array with offset, {1 2 3}@0

;;; Non-numeric word types
T_SYMBOL	equ 16		; Symbol (interned word)
T_CHAR		equ 17		; Character (uninterned)
T_STRING	equ 18		; String (uninterned)
T_QUOTE		equ 19		; Word with quote, "foo
T_COLON		equ 21		; Word with colon, :foo

;;; Numeric types
T_COMPLEX	equ 25		; Complex floating-point
T_REAL		equ 27		; Real floating-point
T_INT		equ 29		; Integer


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Miscellaneous
;;;

VERSION_MAJOR equ 0
VERSION_MINOR equ 0

NODE_MEM_INCREMENT equ 256

;;; Evaluation contexts

;;; Note: the evaluator assumes that these three are the only special
;;; contexts.  Also, EvalTail assumes that VOID & OPTIONAL = VOID.

CONTEXT_OPTIONAL  equ -1	; Single value allowed, or void
CONTEXT_VOID      equ -2	; Only void procedures allowed
CONTEXT_PAREN     equ -3	; Inside parentheses

;;; Backspace character

Ldelete equ 0FFh
