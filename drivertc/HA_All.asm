;****************************************************************
;	    HandyAudition Display/Interaction Routines		*
;****************************************************************
; All of these functions use the following ZP Vars:		*
;	-HEX_Value						*
;	-HEX_XPos						*
;	-HEX_YPos						*
;	-AReg_YPos						*
;****************************************************************
;****************************************************************
; UserPlaySFX::							*
;****************************************************************
UserPlaySFX::
	SHOW SFX_Labl_SCB
	LDA#18
	STA HEX_XPos
	LDA#94
	STA HEX_YPos
	LDA CurrentSFX
	STA HEX_Value
	jsr DisplayHex
	jsr .dobuttons

	LDA Cursor
	CMP LastPress + 1
	bne .docursor
	rts
.docursor
	STA LastPress + 1
	CMP#$20 ; Left
	beq .decreasesfx
	CMP#$10 ; Right
	beq .increasesfx
	rts
.increasesfx
	LDA#(HandyMusic_NumberofSFX - 1)
	CMP CurrentSFX
	beq .return
	INC CurrentSFX
.return
	rts
.decreasesfx
	LDA CurrentSFX
	beq .return
	DEC
	STA CurrentSFX
	rts
.dobuttons
	LDA Button
	ROR
	AND#$F
	CMP LastPress
	bne .buttonsdiff
	rts
.buttonsdiff
	STA LastPress
	CMP#$1 ; A Button
	beq .playsfx
	CMP#$2 ; B Button
	beq .stopsfx
	CMP#$4 ; Option 2
	beq .stopbgm
	CMP#$8 ; Option 1
	beq .playbgm
	rts
.playsfx
	LDA CurrentSFX
	jmp HandyMusic_PlaySFX
.stopsfx
	LDA CurrentSFX
	TAY
	LDA (HandyMusic_SFX_AddressTablePriLo),Y
	jmp HandyMusic_StopSoundEffect
.playbgm
	jsr HandyMusic_StopMusic
	jmp HandyMusic_PlayMusic
.stopbgm
	jmp HandyMusic_StopMusic
;*******
; Vars *
;*******
CurrentSFX dc.b 0
LastPress dc.b 0,0
;******
; SCB *
;******
SFX_Labl_SCB    dc.b $85,$10,$07
                dc.w 0
SFX_Labl_TDAT   dc.w SFX_Labl_data
SFX_Labl_x      dc.w 0
SFX_Labl_y      dc.w 94,$100,$100
                dc.b $0B,$FA,$90
;****************************************************************
; DisplayAudRegs::						*
;	Displays all of the audio register contents.		*
;****************************************************************
DisplayAudRegs::
	LDA#72
	STA AReg_YPos
	LDX#3
.dloop
	jsr DisplayChRegs
	LDA AReg_YPos
	clc
	ADC#-24
	STA AReg_YPos
	DEX
	bpl .dloop
	rts
;****************************************************************
; DisplayChRegs::						*
;	Displays the register contents of audio channel X	*
; at coordinate AReg_YPos.					*
;****************************************************************
DisplayChRegs::
	LDA#$FD
	STA AReg_Redir+1 ; Use register redirection since HandyMusic already does

	LDA AReg_YPos
	STA HUD_REG_y
	SHOW HUD_REG_SCB

    cpx #3
    _IFEQ
    LDA #94
    STA HEX_YPos

    LDA $FD44
    STA HEX_Value
    LDA#72
    STA HEX_XPos
    jsr DisplayHex

    LDA $FD50
    STA HEX_Value
    LDA#84
    STA HEX_XPos
    jsr DisplayHex

    _ENDIF
;V,FB,DV,SH
	LDA AReg_YPos
	STA HEX_YPos
	LDA HandyMusic_Redirect_Volume,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	STA TempVol
	LDA#9
	STA HEX_XPos
	jsr DisplayHex

	LDA HandyMusic_Redirect_FeedBackReg,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	LDA#40
	STA HEX_XPos
	jsr DisplayHex

	LDA HandyMusic_Redirect_DirectVol,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	LDA#71
	STA HEX_XPos
	jsr DisplayHex

	LDA HandyMusic_Redirect_ShiftRegLo,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	LDA#101
	STA HEX_XPos
	jsr DisplayHex
;TB,TC,EX,PAN
	clc
	LDA AReg_YPos
	ADC#8
	STA HEX_YPos

	LDA HandyMusic_Redirect_TimerBack,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	STA TempFreqLo
	LDA#16
	STA HEX_XPos
	jsr DisplayHex

	LDA HandyMusic_Redirect_TimerCont,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	AND#7
	STA TempFreqHi
	LDA#50
	STA HEX_XPos
	jsr DisplayHex

	LDA HandyMusic_Redirect_AudioExtra,X
	STA AReg_Redir
	LDA (AReg_Redir)
	STA HEX_Value
	LDA#81
	STA HEX_XPos
	jsr DisplayHex

	LDA $FD40,X
	STA HEX_Value
	LDA#122
	STA HEX_XPos
	jsr DisplayHex

; Disp Volume & Freq Bar
	clc
	LDA AReg_YPos
	ADC#16
	STA IntBar_y
	LDA TempVol
	ROR
	AND#$7F
	STA IntBar_scx+1
	LDA#$30
	STA IntBar_pal
	SHOW IntBar_SCB

; Freq Format-
; xxxxxPPP MLLLLLLL
; For P > 0, Output is (0PPPLLLL + 16)
; For P = 0, Output is 0PPPLLLL
	LDA TempFreqHi
	beq .nopreacc
	INC
.nopreacc
	LDY#3
.shifthi
	ROL
	DEY
	bpl .shifthi
	AND#$70
	STA IntBar_scx + 1

	LDA TempFreqLo
	ROR
	ROR
	ROR
	AND#15
	ORA IntBar_scx + 1
	STA IntBar_scx + 1
	
	LDA#$F0
	STA IntBar_pal
	LDA IntBar_y
	clc
	ADC#3
	STA IntBar_y
	JSHOW IntBar_SCB
;*******
; Vars *
;*******
TempVol dc.b 0
TempFreqLo dc.b 0
TempFreqHi dc.b 0
;******
; SCB *
;******
IntBar_SCB      dc.b $01,$10,$00
                dc.w 0
                dc.w ZPixel_data
IntBar_x        dc.w 0
IntBar_y        dc.w 0
IntBar_scx      dc.w $100
IntBar_scy      dc.w $100 * 2
IntBar_pal      dc.b $30

HUD_REG_SCB     dc.b $85,$10,$07
                dc.w 0
HUD_REG_TDAT    dc.w AREGLABL_data
HUD_REG_x       dc.w 0
HUD_REG_y       dc.w 0,$100,$100
                dc.b $0B,$FA,$90
;****************************************************************
; DisplayHex::							*
;	Displays the value of a byte in hex at the coordinates	*
; specified by HEX_XPos,HEX_YPos.				*
;****************************************************************
DisplayHex::
	LDA HEX_YPos
	STA HUD_NUM_y

	LDA HEX_Value
	ROR
	ROR
	ROR
	ROR
	AND#$F
	TAY
	jsr .DispHex
	LDA HEX_Value
	AND#$F
	TAY
	jmp .DispHex

.DispHex
	LDA HEX_XPos
	STA HUD_NUM_x
	LDA Hex_TileDatLo,Y
	STA HUD_NUM_TDAT
	LDA Hex_TileDatHi,Y
	STA HUD_NUM_TDAT+1
	PHY
	SHOW HUD_NUM_SCB
	PLY
	clc
	LDA HEX_XPos
	ADC Hex_Tilewidths,Y
	STA HEX_XPos
	rts
;****************
; Texture Table *
;****************
Hex_Tilewidths  dc.b 5,3,5,5,5,4,5,5,5,5,5,5,5,5,4,4
Hex_TileDatLo   dc.b <HUD_0_data,<HUD_1_data,<HUD_2_data,<HUD_3_data
		dc.b <HUD_4_data,<HUD_5_data,<HUD_6_data,<HUD_7_data
		dc.b <HUD_8_data,<HUD_9_data,<TXT_41_data,<TXT_42_data
		dc.b <TXT_43_data,<TXT_44_data,<TXT_45_data,<TXT_46_data
Hex_TileDatHi   dc.b >HUD_0_data,>HUD_1_data,>HUD_2_data,>HUD_3_data
		dc.b >HUD_4_data,>HUD_5_data,>HUD_6_data,>HUD_7_data
		dc.b >HUD_8_data,>HUD_9_data,>TXT_41_data,>TXT_42_data
		dc.b >TXT_43_data,>TXT_44_data,>TXT_45_data,>TXT_46_data
;******
; SCB *
;******
HUD_NUM_SCB     dc.b $85,$00,$07
                dc.w 0
HUD_NUM_TDAT    dc.w 0
HUD_NUM_x       dc.w 27
HUD_NUM_y       dc.w 0
                dc.b $0B,$F7,$60

HandyMusic_Redirect_Volume::		dc.b $20,$28,$30,$38
HandyMusic_Redirect_FeedBackReg::	dc.b $21,$29,$31,$39
HandyMusic_Redirect_DirectVol::		dc.b $22,$2A,$32,$3A
HandyMusic_Redirect_ShiftRegLo::	dc.b $23,$2B,$33,$3B
HandyMusic_Redirect_TimerBack::		dc.b $24,$2C,$34,$3C
HandyMusic_Redirect_TimerCont::		dc.b $25,$2D,$35,$3D
HandyMusic_Redirect_AudioExtra::	dc.b $27,$2F,$37,$3F

