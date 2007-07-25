;;; -*- Text -*-
;;; AUTOMATICALLY GENERATED -- DO NOT EDIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Builtin Data
;;;

workspaceAppVarName:
	db AppVarObj, "logows", 0

workspaceTemplate:
	rorg 0
	db "LgWS", 0

	;; Static data

	dw 0			; appvarStart
	dw wst_userNodeStart-2	; userNodeStartMinus2
	dw workspaceTemplateSize; uninitNodeStart
	dw workspaceTemplateSize; uninitNodeEnd
	db 0			; currentGCFlag
	dw 0			; freeNodeList
	dw 0			; freeNodePairList
	dw 0			; freeNodeQuadList
	dw trueNode		; firstSymbol
	dw 0			; mainSP
	dw 0			; evalProcTop
	dw 0			; evalList
	dw 0			; evalRunningProc

	;; Object area

TRUE_Sym: SYMBOL voidNode, voidNode, voidNode, falseNode, "TRUE"
FALSE_Sym: SYMBOL voidNode, voidNode, voidNode, RUN_Node0, "FALSE"
RUN_Sym0: SYMBOL RUN_Subr, voidNode, voidNode, IF_Node0, "RUN"
IF_Sym0: SYMBOL IF_Subr, voidNode, voidNode, IFELSE_Node0, "IF"
IFELSE_Sym0: SYMBOL IFELSE_Subr, voidNode, voidNode, REPEAT_Node0, "IFELSE"
REPEAT_Sym0: SYMBOL REPEAT_Subr, voidNode, voidNode, STOP_Node0, "REPEAT"
STOP_Sym0: SYMBOL STOP_Subr, voidNode, voidNode, OUTPUT_Node0, "STOP"
OUTPUT_Sym0: SYMBOL OUTPUT_Subr, voidNode, voidNode, OUTPUT_Node1, "OUTPUT"
OUTPUT_Sym1: SYMBOL OUTPUT_Subr, voidNode, voidNode, FPUT_Node0, "OP"
FPUT_Sym0: SYMBOL FPUT_Subr, voidNode, voidNode, FIRST_Node0, "FPUT"
FIRST_Sym0: SYMBOL FIRST_Subr, voidNode, voidNode, BUTFIRST_Node0, "FIRST"
BUTFIRST_Sym0: SYMBOL BUTFIRST_Subr, voidNode, voidNode, BUTFIRST_Node1, "BUTFIRST"
BUTFIRST_Sym1: SYMBOL BUTFIRST_Subr, voidNode, voidNode, COUNT_Node0, "BF"
COUNT_Sym0: SYMBOL COUNT_Subr, voidNode, voidNode, ITEM_Node0, "COUNT"
ITEM_Sym0: SYMBOL ITEM_Subr, voidNode, voidNode, AND_Node0, "ITEM"
AND_Sym0: SYMBOL AND_Subr, voidNode, voidNode, OR_Node0, "AND"
OR_Sym0: SYMBOL OR_Subr, voidNode, voidNode, NOT_Node0, "OR"
NOT_Sym0: SYMBOL NOT_Subr, voidNode, voidNode, SUM_Node0, "NOT"
SUM_Sym0: SYMBOL SUM_Subr, voidNode, voidNode, DIFFERENCE_Node0, "SUM"
DIFFERENCE_Sym0: SYMBOL DIFFERENCE_Subr, voidNode, voidNode, PRODUCT_Node0, "DIFFERENCE"
PRODUCT_Sym0: SYMBOL PRODUCT_Subr, voidNode, voidNode, QUOTIENT_Node0, "PRODUCT"
QUOTIENT_Sym0: SYMBOL QUOTIENT_Subr, voidNode, voidNode, LESSP_Node0, "QUOTIENT"
LESSP_Sym0: SYMBOL LESSP_Subr, voidNode, voidNode, LESSP_Node1, "LESSP"
LESSP_Sym1: SYMBOL LESSP_Subr, voidNode, voidNode, GREATERP_Node0, "LESS?"
GREATERP_Sym0: SYMBOL GREATERP_Subr, voidNode, voidNode, GREATERP_Node1, "GREATERP"
GREATERP_Sym1: SYMBOL GREATERP_Subr, voidNode, voidNode, MAKE_Node0, "GREATER?"
MAKE_Sym0: SYMBOL MAKE_Subr, voidNode, voidNode, DEFINE_Node0, "MAKE"
DEFINE_Sym0: SYMBOL DEFINE_Subr, voidNode, voidNode, 0, "DEFINE"

	;; Node table

wst_userNodeStart:

                rorg $8002
emptyNode:      NODE T_EMPTY, 0, 0
trueNode:       NODE T_SYMBOL, 0, TRUE_Sym
falseNode:      NODE T_SYMBOL, 0, FALSE_Sym
RUN_Node0: NODE T_SYMBOL, 0, RUN_Sym0
IF_Node0: NODE T_SYMBOL, 0, IF_Sym0
IFELSE_Node0: NODE T_SYMBOL, 0, IFELSE_Sym0
REPEAT_Node0: NODE T_SYMBOL, 0, REPEAT_Sym0
STOP_Node0: NODE T_SYMBOL, 0, STOP_Sym0
OUTPUT_Node0: NODE T_SYMBOL, 0, OUTPUT_Sym0
OUTPUT_Node1: NODE T_SYMBOL, 0, OUTPUT_Sym1
FPUT_Node0: NODE T_SYMBOL, 0, FPUT_Sym0
FIRST_Node0: NODE T_SYMBOL, 0, FIRST_Sym0
BUTFIRST_Node0: NODE T_SYMBOL, 0, BUTFIRST_Sym0
BUTFIRST_Node1: NODE T_SYMBOL, 0, BUTFIRST_Sym1
COUNT_Node0: NODE T_SYMBOL, 0, COUNT_Sym0
ITEM_Node0: NODE T_SYMBOL, 0, ITEM_Sym0
AND_Node0: NODE T_SYMBOL, 0, AND_Sym0
OR_Node0: NODE T_SYMBOL, 0, OR_Sym0
NOT_Node0: NODE T_SYMBOL, 0, NOT_Sym0
SUM_Node0: NODE T_SYMBOL, 0, SUM_Sym0
DIFFERENCE_Node0: NODE T_SYMBOL, 0, DIFFERENCE_Sym0
PRODUCT_Node0: NODE T_SYMBOL, 0, PRODUCT_Sym0
QUOTIENT_Node0: NODE T_SYMBOL, 0, QUOTIENT_Sym0
LESSP_Node0: NODE T_SYMBOL, 0, LESSP_Sym0
LESSP_Node1: NODE T_SYMBOL, 0, LESSP_Sym1
GREATERP_Node0: NODE T_SYMBOL, 0, GREATERP_Sym0
GREATERP_Node1: NODE T_SYMBOL, 0, GREATERP_Sym1
MAKE_Node0: NODE T_SYMBOL, 0, MAKE_Sym0
DEFINE_Node0: NODE T_SYMBOL, 0, DEFINE_Sym0
                rorg $$

workspaceTemplateSize equ $ - workspaceTemplate

;;; Builtin nodes
builtinNodeStart:
                  rorg $8000
voidNode:         NODE T_VOID, 0, 0
RUN_Subr: NODE T_SUBR, 0, p_RUN
IF_Subr: NODE T_SUBR, 0, p_IF
IFELSE_Subr: NODE T_SUBR, 0, p_IFELSE
REPEAT_Subr: NODE T_SUBR, 0, p_REPEAT
STOP_Subr: NODE T_SUBR, 0, p_STOP
OUTPUT_Subr: NODE T_SUBR, 0, p_OUTPUT
FPUT_Subr: NODE T_SUBR, 0, p_FPUT
FIRST_Subr: NODE T_SUBR, 0, p_FIRST
BUTFIRST_Subr: NODE T_SUBR, 0, p_BUTFIRST
COUNT_Subr: NODE T_SUBR, 0, p_COUNT
ITEM_Subr: NODE T_SUBR, 0, p_ITEM
AND_Subr: NODE T_SUBR, 0, p_AND
OR_Subr: NODE T_SUBR, 0, p_OR
NOT_Subr: NODE T_SUBR, 0, p_NOT
SUM_Subr: NODE T_SUBR, 0, p_SUM
DIFFERENCE_Subr: NODE T_SUBR, 0, p_DIFFERENCE
PRODUCT_Subr: NODE T_SUBR, 0, p_PRODUCT
QUOTIENT_Subr: NODE T_SUBR, 0, p_QUOTIENT
LESSP_Subr: NODE T_SUBR, 0, p_LESSP
GREATERP_Subr: NODE T_SUBR, 0, p_GREATERP
MAKE_Subr: NODE T_SUBR, 0, p_MAKE
DEFINE_Subr: NODE T_SUBR, 0, p_DEFINE
                  rorg $$
