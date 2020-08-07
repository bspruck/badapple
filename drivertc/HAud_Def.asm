;****************************************************************
;								*
;	      HandyAudition Defines, ZP, and Globals		*
;								*
;****************************************************************
	
;****************************************************************
;			  BLL Macros				*
;****************************************************************
	
	
;****************************************************************
;			  Zeropage				*
;****************************************************************
BEGIN_ZP
;*************************
; Big, Important Globals *
;*************************
FrameCounter ds 1
FlipMode ds 1
FlipPressed ds 1
GLO_GenPointer ds 2
GLO_GameMode ds 1
GLO_GamePaused ds 1
GLO_PauseCount ds 1
GLO_LoadStage ds 1
GLO_LoadSFile ds 1
GLO_LoadScene ds 1
GLO_CurrentStage ds 1
;****************
; Hex Converter *
;****************
HEX_Value ds 1
HEX_XPos ds 1
HEX_YPos ds 1
AReg_YPos ds 1
AReg_Redir ds 2
;*********************
; Palette Operations *
;*********************
PAL_SrcPalLo ds 1
PAL_SrcPalHi ds 1
PAL_DestPalLo ds 1
PAL_DestPalHi ds 1
PAL_BrightnessAdjust ds 1
PAL_GreenAdjust ds 1
PAL_RedAdjust ds 1
PAL_BlueAdjust ds 1
;********************
; VSYNC/HSYNC Stuff *
;********************
FrameProcDone ds 1
VBlankProcDone ds 1
UserVBlank_EN ds 1
UserVBlank_Lo ds 1
UserVBlank_Hi ds 1
HBlank_FlipState ds 1
HBlank_OffX ds 1
HBlank_OffY ds 1
;***************************
; HandyMusic ZeroPage Vars *
;***************************
	
	include "HM_ZP.asm"
	
zeropage_pos	set $100-*
END_ZP

echo "Zeropage left: %Hzeropage_pos"
;****************************************************************
;			General Defines				*
;****************************************************************
;****************************************************************
;			     END				*
;****************************************************************
