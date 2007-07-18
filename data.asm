;;; -*- TI-Asm -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Miscellaneous Data
;;;
	
SYMBOL macro proc,var,plist,next,name
	dw proc,var,plist,next,(.strlen. name)
	db name
	.endm

NODE macro type,page,addr
	db type<<2, page
	dw addr
	.endm

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
	dw aNode		; firstSymbol
	dw 0			; evalList
	dw 0			; evalCurrentProc
	dw 0			; evalNumArgs
	dw 0			; evalRemainingArgs

	;; Object area

a_sym:          SYMBOL voidNode, 42, voidNode, sumNode, "A"
sum_sym:        SYMBOL sumSubrNode, voidNode, voidNode, diffNode, "SUM"
diff_sym:       SYMBOL diffSubrNode, voidNode, voidNode, productNode, "DIFFERENCE"
product_sym:    SYMBOL productSubrNode, voidNode, voidNode, quotientNode, "PRODUCT"
quotient_sym:   SYMBOL quotientSubrNode, voidNode, voidNode, fputNode, "QUOTIENT"
fput_sym:       SYMBOL fputSubrNode, voidNode, voidNode, firstNode, "FPUT"
first_sym:      SYMBOL firstSubrNode, voidNode, voidNode, butfirstNode, "FIRST"
butfirst_sym:   SYMBOL bfSubrNode, voidNode, voidNode, bfNode, "BUTFIRST"
bf_sym:         SYMBOL bfSubrNode, voidNode, voidNode, countNode, "BF"
count_sym:      SYMBOL countSubrNode, voidNode, voidNode, itemNode, "COUNT"
item_sym:       SYMBOL itemSubrNode, voidNode, voidNode, 0, "ITEM"

	;; Node table

wst_userNodeStart:

                rorg $8002
emptyNode:      NODE T_EMPTY, 0, 0
aNode:          NODE T_SYMBOL, 0, a_sym
sumNode:        NODE T_SYMBOL, 0, sum_sym
diffNode:       NODE T_SYMBOL, 0, diff_sym
productNode:    NODE T_SYMBOL, 0, product_sym
quotientNode:   NODE T_SYMBOL, 0, quotient_sym
fputNode:       NODE T_SYMBOL, 0, fput_sym
firstNode:      NODE T_SYMBOL, 0, first_sym
butfirstNode:   NODE T_SYMBOL, 0, butfirst_sym
bfNode:         NODE T_SYMBOL, 0, bf_sym
countNode:      NODE T_SYMBOL, 0, count_sym
itemNode:       NODE T_SYMBOL, 0, item_sym
                rorg $$

workspaceTemplateSize equ $ - workspaceTemplate

;;; Builtin nodes
builtinNodeStart:
                  rorg $8000
voidNode:         NODE T_VOID, 0, 0
sumSubrNode:      NODE T_SUBR, 0, p_SUM
diffSubrNode:     NODE T_SUBR, 0, p_DIFFERENCE
productSubrNode:  NODE T_SUBR, 0, p_PRODUCT
quotientSubrNode: NODE T_SUBR, 0, p_QUOTIENT
fputSubrNode:     NODE T_SUBR, 0, p_FPUT
firstSubrNode:    NODE T_SUBR, 0, p_FIRST
bfSubrNode:       NODE T_SUBR, 0, p_BUTFIRST
countSubrNode:    NODE T_SUBR, 0, p_COUNT
itemSubrNode:     NODE T_SUBR, 0, p_ITEM
                  rorg $$
