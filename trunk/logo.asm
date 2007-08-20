;;; -*- TI-Asm -*-

 processor z80
 nolist
 include <ti83plus.inc>
 list

 include "defs.inc"

	org 4000h

	;; Flash App header

	db 80h,0Fh, 12h,34h,56h,78h 	; Application (length set when signing)

	 db 80h,12h			; App signing key ID
	  db 01h,04h			; = Freeware TI-83+/84+

	 db 80h,21h			; Major version number
	  db VERSION_MAJOR

	 db 80h,31h			; Minor version number
	  db VERSION_MINOR

	 db 80h,44h			; App name
	  db "Logo"

	 db 80h,81h			; Number of pages
	  db 1

	 db 80h,90h			; No default splash screen

	 db 80h,0A1h			; Maximum hardware compatibility
	  db 1

	 db 03h,26h			; Date stamp block
	  db 09h,04h
	   db 04h,6Fh,1Bh,80h

	 db 02h,0Dh, 40h		; Fake date stamp signature
	  db 0A1h, 06Bh, 099h, 0F6h, 059h, 0BCh, 067h, 0F5h
	  db 085h, 09Ch, 009h, 06Ch, 00Fh, 0B4h, 003h, 09Bh
	  db 0C9h, 003h, 032h, 02Ch, 0E0h, 003h, 020h, 0E3h
	  db 02Ch, 0F4h, 02Dh, 073h, 0B4h, 027h, 0C4h, 0A0h
	  db 072h, 054h, 0B9h, 0EAh, 07Ch, 03Bh, 0AAh, 016h
	  db 0F6h, 077h, 083h, 07Ah, 0EEh, 01Ah, 0D4h, 042h
	  db 04Ch, 06Bh, 08Bh, 013h, 01Fh, 0BBh, 093h, 08Bh
	  db 0FCh, 019h, 01Ch, 03Ch, 0ECh, 04Dh, 0E5h, 075h

	 db 80h,7Fh, 0,0,0,0		; Program image (length ignored)

	;; Start of App

	BCALL _RunIndicOn
	call OpenWorkspace

	ld hl,AppVecs
	BCALL _AppInit

	ld hl,0
	ld (errorMessage),hl

	ld hl,ErrorH
	call APP_PUSH_ERRORH

 	BCALL _ClrScrn
 	BCALL _HomeUp

	ld hl,Lib
	ld bc,LibSize
 	call ParseBuffer
	call EvalMain

 	ld hl,WelcomeStr
 	call PutS
Loop:
	BCALL _RunIndicOff
	ld a,LblockArrow
	call PutC

	ld hl,appBackUpScreen
	ld bc,768
	call GetS_Console
	jr c,Quit
	push hl
	 BCALL _RunIndicOn
	 BCALL _NewLine
	 pop hl
	BCALL _StrLength
	call ParseUserInput
	call IsTOLine
	jr nc,ReadTOProc
	call EvalMain
	ld de,voidNode
	or a
	sbc hl,de
	jr z,Loop
	add hl,de
	call Show
	BCALL _NewLine
	jr Loop

Quit:	call CleanUp
	BCALL _JForceCmdNoChar
	;; UNREACHABLE

ErrorH:
	in a,(4)
	and 8
	jr z,ErrorH
	res onInterrupt,(iy+onFlags)
	call SetReadConsole
	call PrintErrorMessage
	ld hl,ErrorH
	call APP_PUSH_ERRORH
	jr Loop

ReadTOProc:
	push hl			; save TO-line
	 ld hl,emptyNode
ReadTOProcLoop:
	 push hl
	  BCALL _RunIndicOff
	  ld a,Lblock
	  call PutC
	  ld hl,appBackUpScreen
	  ld bc,768
	  call GetS_Console
	  jr c,ReadTOProcAbort
	  push hl
	   BCALL _RunIndicOn
	   BCALL _NewLine
	   pop hl
	  BCALL _StrLength
	  call ParseUserInput
	  push hl
	   call IsENDLine
	   pop hl
	  jr nc,ReadTOProcDone
	  ex de,hl
	  pop hl
	 call ConcatenateLists
	 jr ReadTOProcLoop
ReadTOProcDone:
	  pop de
	 pop hl
	call ParseProcDefinition
	call Print
	ld hl,DefinedStr
	call PutS
	jp Loop

ReadTOProcAbort:
	  pop de
	 pop hl
	jp Loop


CleanUp:
	ld hl,workspaceAppVarName
	rst 20h
	BCALL _ChkFindSym
	jr c,CleanUp_NoWorkspace
	BCALL _DelVarArc
CleanUp_NoWorkspace:

	;; Clear homescreen, since we've scribbled on cmdShadow
	ld hl,cmdShadow
	ld de,cmdShadow+1
	ld (hl),20h
	ld bc,127
	ldir
	ld a,(winTop)
	ld h,0
	ld l,a
	ld (cmdShadCur),hl

	ld hl,prgmBangName
	rst 20h
	BCALL _ChkFindSym
	jr c,CleanUp_NoEntry
	BCALL _DelVarArc
	ld hl,prgmBangName
	rst 20h
	ld hl,0
	BCALL _CreateProg
CleanUp_NoEntry:
	BCALL _ReloadAppEntryVecs
AppMain:
AppRedisp:
AppSizeWind:
AppErrorEP:
	ret

AppPPutAway equ SaveWorkspace

AppPutAway:
	call CleanUp
	BJUMP _PutAway

AppVecs:
	dw AppMain
	dw AppPPutAway
	dw AppPutAway
	dw AppRedisp
	dw AppErrorEP
	dw AppSizeWind
	db (appWantIntrptF | appTextSaveF | appAutoScrollF)

prgmBangName:
	db ProgObj, '!', 0

WelcomeStr:
	db "Welcome to Logo", Lenter, 0

DefinedStr:
	db " defined", Lenter, 0

 include "logocore.asm"

Lib:
 incbin "logolib.bin"
LibSize equ $ - Lib
