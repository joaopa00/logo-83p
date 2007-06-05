;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Macros
;;;

BCALL macro addr
	nolist
	rst 28h
	dw addr
	list
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
currentGCFlag:		ds 1
freeNodeList:		ds 2
freeNodePairList:	ds 2
freeNodeQuadList:	ds 2

savedDataSize equ $ - savedData

appvarStartMPtr		equ iMathPtr1
newObjectMPtr		equ iMathPtr2


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

NODE_MEM_INCREMENT equ 256
