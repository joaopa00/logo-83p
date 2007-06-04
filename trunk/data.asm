;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Miscellaneous Data
;;;

workspaceAppVarName:
	db AppVarObj, "logows", 0

workspaceTemplate:
	rorg 0
	db "LgWS", 0

	;; Static data
	dw 0			; appvarStart
	dw wst_userNodeStart-2	; userNodeStartMinus2
	dw wst_uninitNodeStart	; uninitNodeStart
	dw wst_uninitNodeEnd	; uninitNodeEnd
	db 0			; currentGCFlag
	dw 0			; freeNodeList
	dw 0			; freeNodePairList
	dw 0			; freeNodeQuadList

	;; Object area - empty for now

	;; Node table

wst_userNodeStart:
	db T_EMPTY<<2, 0, 0, 0
wst_uninitNodeStart:
wst_uninitNodeEnd:

workspaceTemplateSize:
	rorg $$

;;; Builtin nodes
builtinNodeStart:
	rorg $8000
voidNode:
	db T_VOID<<2, 0, 0, 0
	rorg $$
