;****************************************************************
;		  HandyMusic- Main Driver Source		*
;****************************************************************
;HandyMusic lives from $3000-$76AF
;Music Data lives from $4000-$BFFF
;Sound effects may be placed anywhere, but are
;usually packed after the HandyMusic engine and before the music.
;ORG $3000
;**********************
; Some Useful Equates *
;**********************
Lynx_Audio_Ch0		EQU 0
Lynx_Audio_Ch1		EQU 8
Lynx_Audio_Ch2		EQU 16
Lynx_Audio_Ch3		EQU 24

Lynx_Audio_Volume	EQU $FD20
Lynx_Audio_FeedBackReg	EQU $FD21
Lynx_Audio_DirectVol	EQU $FD22
Lynx_Audio_ShiftRegLo	EQU $FD23
Lynx_Audio_TimerBack	EQU $FD24
Lynx_Audio_TimerCont	EQU $FD25
Lynx_Audio_AudioExtra	EQU $FD27

Lynx_Audio_Atten_0	EQU $FD40
Lynx_Audio_Atten_1	EQU $FD41
Lynx_Audio_Atten_2	EQU $FD42
Lynx_Audio_Atten_3	EQU $FD43
Lynx_Audio_Panning	EQU $FD44
Lynx_Audio_Stereo	EQU $FD50

;************************************
; Instrument Script Decode Commands *
;************************************
	include "HM_Instr.asm"
;*******************************
; Music Script Decode Commands *
;*******************************
	include "HM_Mus.asm"
;****************************************************************
; HandyMusic_Main::						*
;	The main entry point for the HandyMusic driver, this 	*
; should be called every time you want HandyMusic to process	*
; all music/sfx data and adjust the audio registers. The most	*
; convenient way is to simply tie the routine to VBlank and	*
; run the audio updates at 60Hz. You can also use any of the	*
; available Lynx timers and call HandyMusic through an IRQ.	*
; However, it should be noted that the composition software is	*
; all designed for the 60Hz (fast) mode.			*
;****************************************************************
HandyMusic_Main::
; Personal notes:
; HandyMusic expects A,X,Y, and P to be preserved before
; being called. Don't forget it!
	sei ; Quickly Disable IRQs

	LDA HandyMusic_Enable	; Is HandyMusic enabled?
	bne .HandyMusic_CActive ; If not, bail.
	rts
.HandyMusic_CActive
;         dec $FDA8
	LDA HandyMusic_Active	; Or is it already in a decode
	beq .HandyMusic_Decode00; procedure?
	rts
.HandyMusic_Decode00
	INC HandyMusic_Active	; We're in the decode procedure now.
	cli ; Re-enable interrupts so we don't miss anything.
;         inc $FDB8
;**********************
; Channel Update Call *
;**********************
.ChannelUpdates00 ; Update all of the channels (SFX/Instrument processing)
	LDX#3
.ChannelUpdates01
	jsr HandyMusic_UpdateChannel
	DEX
	bpl .ChannelUpdates01
;********************************************
; Check if a SFX was requested to be played *
;********************************************
.SFXPlayCheck00
	LDA HandyMusic_SFX_PlayRequest
	beq .SFXPlayCheck01
	STZ HandyMusic_SFX_PlayRequest
	jsr HandyMusic_EnqueueSFX
.SFXPlayCheck01
;********************
; Music Update Call *
;********************
.BGMPlayCheck00
	LDA HandyMusic_BGMPlaying
	beq .BGMPlayCheck10
	LDX#3
.BGMPlayCheck01
	jsr HandyMusic_DecodeMusic
	DEX
	bpl .BGMPlayCheck01
.BGMPlayCheck10
;*************
; Decode End *
;*************
	STZ HandyMusic_Active	; Done with decoding.
.HandyMusic_Exit
	rts ; We're done here




;****************************************************************
; HandyMusic_DecodeMusic::					*
;	Decodes the current music script for the channel number	*
; stored in X.							*
;****************************************************************
HandyMusic_DecodeMusic::
	LDA HandyMusic_Music_Priority,X ; is the channel enabled?
	beq .return
	LDA HandyMusic_Music_DecodeDelayLo,X
	ORA HandyMusic_Music_DecodeDelayHi,X ; Any Decoding Delays?
	beq .MusicDecode00
	LDA HandyMusic_Music_DecodeDelayHi,X
	bne .hidelayactive
	DEC HandyMusic_Music_DecodeDelayLo,X ; If so, wait for them.
	bne .return
	bra .MusicDecode00
.hidelayactive
	LDA HandyMusic_Music_DecodeDelayLo,X
	bne .justdeclo
	DEC HandyMusic_Music_DecodeDelayHi,X
.justdeclo
	DEC HandyMusic_Music_DecodeDelayLo,X
.return
	rts
.MusicDecode00
	LDA HandyMusic_Music_DecodePointerLo,X
	STA HandyMusic_Music_DecodePointer
	LDA HandyMusic_Music_DecodePointerHi,X
	STA HandyMusic_Music_DecodePointer + 1 ; Copy last decode pointer
.MusicDecode01
	jsr HandyMusic_Mus_GetBytes ; Get current command byte
	TAY
	LDA HandyMusic_Mus_CommandTableLo,Y
	STA .MusicDecode12 + 1
	LDA HandyMusic_Mus_CommandTableHi,Y
	STA .MusicDecode12 + 2
.MusicDecode12
	jsr $0000 ; Process command (destination overwritten)
	LDA HandyMusic_Music_Priority,X ; is the channel enabled?
	beq .return
	LDA HandyMusic_Music_DecodeDelayLo,X ; Delay happen?
	ORA HandyMusic_Music_DecodeDelayHi,X
	beq .MusicDecode01 ; If not, get next command
HandyMusic_BackupDecodePointer::
	LDA HandyMusic_Music_DecodePointer
	STA HandyMusic_Music_DecodePointerLo,X
	LDA HandyMusic_Music_DecodePointer + 1
	STA HandyMusic_Music_DecodePointerHi,X ; Update decode pointer
	rts ; We're done

;****************************************************************
; HandyMusic_EnqueueSFX::					*
;	Attempts to enqueue a sound effect in an open channel	*
; or one occupied by a lower priority instrument/sfx.		*
;****************************************************************
HandyMusic_EnqueueSFX::
	LDY HandyMusic_SFX_EnqueueNext
	LDX#3
.checkzeroes
	LDA HandyMusic_Channel_Priority,X
	beq .foundchannel
	DEX
	bpl .checkzeroes
	LDX#3
	LDA (HandyMusic_SFX_AddressTablePriLo),Y
.checkpriorities
	CMP HandyMusic_Channel_Priority,X
	bcs .foundchannel
	DEX
	bpl .checkpriorities
	rts ; No available Channels
.foundchannel
	LDA (HandyMusic_SFX_AddressTablePriLo),Y ; Get requested SFX priority
	STA HandyMusic_Channel_Priority,X ; Channel found, initialize SFX
	LDA#$FF
	STA Lynx_Audio_Atten_0,X		; Force center panning
	STZ HandyMusic_Channel_LoopDepth,X ; Reset Loop Depth
	STZ HandyMusic_Channel_DecodeDelay,X ; And decode delay

	STZ HandyMusic_Channel_BaseFreqDec,X	; Also clear the base frequency
	STZ HandyMusic_Channel_BaseFreqLo,X	; and pitch adjustment, since those are instrument-only.
	STZ HandyMusic_Channel_BaseFreqHi,X
	STZ HandyMusic_Channel_BasePitAdjDec,X
	STZ HandyMusic_Channel_BasePitAdjLo,X
	STZ HandyMusic_Channel_BasePitAdjHi,X

	LDA (HandyMusic_SFX_AddressTableLoLo),Y ; Copy script pointer to work pointer
	STA HandyMusic_Channel_DecodePointer
	LDA (HandyMusic_SFX_AddressTableHiLo),Y
	STA HandyMusic_Channel_DecodePointer + 1
HandyMusic_Enqueue_IS
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_NoteOffPLo,X
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_NoteOffPHi,X ; Copy note off pointer

	jsr HandyMusic_SFX_SetSFB
	jsr HandyMusic_SFX_SetVolume
	jsr HandyMusic_SFX_SetFrequency ; Get Shift, Feedback, Volume and Frequency
	LDA HandyMusic_Channel_DecodePointer
	STA HandyMusic_Channel_DecodePointerLo,X
	LDA HandyMusic_Channel_DecodePointer + 1
	STA HandyMusic_Channel_DecodePointerHi,X ; Update decode pointer
	rts ; We're done

;****************************************************************
; HandyMusic_UpdateChannel::					*
;	Performs the general frame updates on the channel	*
; specified by X, such as script decoding, frequency envelopes,	*
; and volume envelopes. A channel is skipped if its priority is	*
; zero.	A is trashed in this routine.				*
;****************************************************************
HandyMusic_UpdateChannel::
	LDA HandyMusic_Channel_Priority,X ; is the channel enabled?
	bne .doupdates00
.return
	LDY HandyMusic_Redirect_ChOffs,X
	STA Lynx_Audio_TimerCont,Y
	rts
.doupdates00
	LDA HandyMusic_Channel_DecodeDelay,X ; Any decode delays active?
	beq .doupdates10
	DEC
	STA HandyMusic_Channel_DecodeDelay,X ; If so, decrement and process envelopes
	bra .processenvelopes
.doupdates10
	LDA HandyMusic_Channel_DecodePointerLo,X
	STA HandyMusic_Channel_DecodePointer
	LDA HandyMusic_Channel_DecodePointerHi,X
	STA HandyMusic_Channel_DecodePointer + 1 ; Copy last decode pointer
.doupdates11
	jsr HandyMusic_SFX_GetBytes ; Get current command byte
	TAY
	LDA HandyMusic_SFX_CommandTableLo,Y
	STA .doupdates12 + 1
	LDA HandyMusic_SFX_CommandTableHi,Y
	STA .doupdates12 + 2
.doupdates12
	jsr $0000 ; Process command (destination overwritten)
	LDA HandyMusic_Channel_Priority,X ; is the channel enabled?
	beq .return
	LDA HandyMusic_Channel_DecodeDelay,X ; Delay happen?
	beq .doupdates11 ; If not, get next command

	LDA HandyMusic_Channel_DecodePointer
	STA HandyMusic_Channel_DecodePointerLo,X
	LDA HandyMusic_Channel_DecodePointer + 1
	STA HandyMusic_Channel_DecodePointerHi,X ; Update decode pointer

.processenvelopes
;Base Frequency Update
	clc
	LDA HandyMusic_Channel_BaseFreqDec,X
	ADC HandyMusic_Channel_BasePitAdjDec,X
	STA HandyMusic_Channel_BaseFreqDec,X
	LDA HandyMusic_Channel_BaseFreqLo,X
	ADC HandyMusic_Channel_BasePitAdjLo,X
	STA HandyMusic_Channel_BaseFreqLo,X
	LDA HandyMusic_Channel_BaseFreqHi,X
	ADC HandyMusic_Channel_BasePitAdjHi,X
	STA HandyMusic_Channel_BaseFreqHi,X

;Frequency Offset Update
	clc
	LDA HandyMusic_Channel_FreqOffsetDec,X
	ADC HandyMusic_Channel_OffsetPitAdjDec,X
	STA HandyMusic_Channel_FreqOffsetDec,X
	LDA HandyMusic_Channel_FreqOffsetLo,X
	ADC HandyMusic_Channel_OffsetPitAdjLo,X
	STA HandyMusic_Channel_FreqOffsetLo,X
	LDA HandyMusic_Channel_FreqOffsetHi,X
	ADC HandyMusic_Channel_OffsetPitAdjHi,X
	STA HandyMusic_Channel_FreqOffsetHi,X

;Volume Update
	clc
	LDA HandyMusic_Channel_VolumeDec,X
	ADC HandyMusic_Channel_VolumeAdjustDec,X
	STA HandyMusic_Channel_VolumeDec,X
	LDA HandyMusic_Channel_Volume,X
	ADC HandyMusic_Channel_VolumeAdjust,X
	STA HandyMusic_Channel_Volume,X

;Now Calculate the final frequency
	clc
	LDA HandyMusic_Channel_BaseFreqLo,X
	ADC HandyMusic_Channel_FreqOffsetLo,X
	STA HandyMusic_Channel_FinalFreqLo
	LDA HandyMusic_Channel_BaseFreqHi,X
	ADC HandyMusic_Channel_FreqOffsetHi,X
	STA HandyMusic_Channel_FinalFreqHi

	LDA HandyMusic_Channel_NoWriteBack,X ; Writing disabled?
	beq .doWriteback
	rts
.doWriteback
	LDY HandyMusic_Redirect_ChOffs,X
	LDA HandyMusic_Channel_Volume,X
	STA Lynx_Audio_Volume,Y			; Write volume value

	LDA HandyMusic_Channel_ForceUpd,X
	bne .updatelastfreq
	LDA HandyMusic_Channel_FinalFreqLo
	CMP HandyMusic_Channel_LastFreqLo,X
	bne .updatelastfreq
	LDA HandyMusic_Channel_FinalFreqHi	; Check to see if we need to
	CMP HandyMusic_Channel_LastFreqHi,X	; update the counter at all...
	bne .updatelastfreq
	rts
.updatelastfreq
;And perform the register writes
	STZ HandyMusic_Channel_ForceUpd,X
	LDA HandyMusic_Channel_FinalFreqLo
	STA HandyMusic_Channel_LastFreqLo,X
	LDA HandyMusic_Channel_FinalFreqHi
	STA HandyMusic_Channel_LastFreqHi,X

	LDA Lynx_Audio_TimerCont,Y		; Y is set from the volume write above
	AND#%10100000				; Preserve Feedback and Integrate mode switches.
	STA Lynx_Audio_TimerCont,Y		; But shut off channel

	LDA HandyMusic_Channel_FinalFreqHi ; are we using a 1us prescale?
	AND#3
	bne .not1usclock

	LDA HandyMusic_Channel_FinalFreqLo
	STA Lynx_Audio_TimerBack,Y		; Write straight frequency divider value
	LDA Lynx_Audio_TimerCont,Y
	ORA#%00011000
	STA Lynx_Audio_TimerCont,Y		; Write prescale and turn channel back on.
	rts
.not1usclock
	LDA HandyMusic_Channel_FinalFreqLo  ; Truncate to 7-bits if > 1us prescale
	ORA#$80
	STA Lynx_Audio_TimerBack,Y		; Write frequency divider value

	LDA HandyMusic_Channel_FinalFreqLo
	ROL
	LDA HandyMusic_Channel_FinalFreqHi
	ROL
	DEC
	AND#7
	ORA Lynx_Audio_TimerCont,Y
	ORA#%00011000
	STA Lynx_Audio_TimerCont,Y		; Write prescale and turn channel back on.
	rts

;****************************************************************
; HandyMusic_PlaySFX::						*
;	Set a sound effect to be played on the next audio frame.*
; Sound effect number in A.					*
;****************************************************************
HandyMusic_PlaySFX::
	PHX
	PHY
	TAX
	LDA HandyMusic_SFX_PlayRequest
	beq .SFXisOK
	LDY HandyMusic_SFX_EnqueueNext
	LDA (HandyMusic_SFX_AddressTablePriLo),Y
	PHX
	PLY
	CMP (HandyMusic_SFX_AddressTablePriLo),Y
	bcs .BadPriority
.SFXisOK
	STX HandyMusic_SFX_EnqueueNext
	INC HandyMusic_SFX_PlayRequest
.BadPriority
	PLY
	PLX
	rts

;****************************************************************
; HandyMusic_StopSoundEffect::					*
;	Finds the first sound effect with a matching priority	*
; and disables it, it could even be a note! Make sure to use	*
; varying priorities in your notes and sound effects to keep	*
; this routine useful. A contains the priority of the sound	*
; effect or note to disable, X is preserved.			*
;****************************************************************
HandyMusic_StopSoundEffect::
	PHX
	LDX#3
.StopSFX00
	sei ; Disable interrupts only for a bit.
	CMP HandyMusic_Channel_Priority,X
	bne .StopSFX10
	jsr HandyMusic_FreeChannel
	cli
	bra .exit
.StopSFX10
	cli ; Now they can be turned back on.
	DEX
	bpl .StopSFX00
.exit
	PLX
	rts

;****************************************************************
; HandyMusic_StopAll::						*
;	Stops all playing music tracks and sound effects.	*
;****************************************************************
HandyMusic_StopAll::
	jsr HandyMusic_StopMusic ; Stop music
	PHX
	LDX#3
.Stopall0
	sei ; Disable interrupts only for a bit.
	jsr HandyMusic_FreeChannel ; Force all channels to free
	STZ HandyMusic_SFX_PlayRequest ; Kill SFX Play Request
	cli ; Now they can be turned back on.
	DEX
	bpl .Stopall0
	PLX
	rts

;****************************************************************
; HandyMusic_LoadPlayBGM::					*
;	Loads and Plays the new BGM from the cart in A.		*
;****************************************************************
;HandyMusic_LoadPlayBGM::
;	PHA
;	jsr HandyMusic_StopMusic	; Stop Current BGM
;.waitsampledone
;	LDA Sample_Playing
;	bne .waitsampledone
;	PLA
;	clc
;	ADC#FileNum_MusicBase
;	jsr LoadFile			; Load the new BGM, and fall into PlayMusic
;****************************************************************
; HandyMusic_PlayMusic::					*
;	Starts playing the current song loaded into $B000-$BFFF.*
; Make sure to stop playing a song before you load another one.	*
;****************************************************************
HandyMusic_PlayMusic::
	PHX	; X should be preserved,
	LDX#3	; who knows where we'll be coming from.
.PlayMusic00
	LDA HandyMusic_Song_Priorities,X	; Copy Song Header Data
	STA HandyMusic_Music_Priority,X
	LDA HandyMusic_Song_TrackAddrLo,X
	STA HandyMusic_Music_DecodePointerLo,X
	LDA HandyMusic_Song_TrackAddrHi,X
	STA HandyMusic_Music_DecodePointerHi,X
	STZ HandyMusic_Music_LoopDepth,X
	STZ HandyMusic_Music_DecodeDelayLo,X
	STZ HandyMusic_Music_DecodeDelayHi,X
	STZ HandyMusic_Music_BasePitAdjLo,X
	STZ HandyMusic_Music_BasePitAdjHi,X
	STZ HandyMusic_Music_BasePitAdjDec,X
	DEX
	bpl .PlayMusic00
	PLX
	LDA HandyMusic_Song_InstrLoLo
	STA HandyMusic_Instrument_AddrTableLoLo
	LDA HandyMusic_Song_InstrLoHi
	STA HandyMusic_Instrument_AddrTableLoHi
	LDA HandyMusic_Song_InstrHiLo
	STA HandyMusic_Instrument_AddrTableHiLo
	LDA HandyMusic_Song_InstrHiHi
	STA HandyMusic_Instrument_AddrTableHiHi
	INC HandyMusic_BGMPlaying	; Turn on decoder
	rts

;****************************************************************
; HandyMusic_StopMusic::					*
;	Stops the current music track from decoding, freeing	*
; any channels it may have been using in the process.		*
; A is trashed, X is preserved.					*
;****************************************************************
HandyMusic_StopMusic::
	STZ HandyMusic_BGMPlaying
	PHX
	LDX#3
.StopMusic00
	sei ; Disable interrupts only for a bit to free the channel
	LDA HandyMusic_Music_Priority,X ; If the priorities are identical, it's a note
	CMP HandyMusic_Channel_Priority,X
	bne .StopMusic10
	jsr HandyMusic_FreeChannel
.StopMusic10
	STZ HandyMusic_Music_Priority,X
	cli ; Now they can be turned back on.
	DEX
	bpl .StopMusic00
	PLX
	rts

;****************************************************************
; HandyMusic_FreeChannel::					*
;	Frees the channel specified by the X register so it may	*
; be available for future notes and instruments. A is trashed.	*
;****************************************************************
HandyMusic_FreeChannel::
	STZ HandyMusic_Channel_Priority,X ; Zero priority, also stops decoding.

	LDY HandyMusic_Redirect_ChOffs,X
	LDA#0
	STA Lynx_Audio_TimerCont,Y
	STA Lynx_Audio_Volume,Y
	STA Lynx_Audio_DirectVol,Y
	DEC
	STA Lynx_Audio_Atten_0,X		; Reset the panning register to $FF
	rts

;****************************************************************
; HandyMusic_Pause::						*
;	Pauses HandyMusic, and mutes all channels. There is 	*
; checking to ensure HandyMusic is not "double paused."		*
;****************************************************************
HandyMusic_Pause::
	LDA HandyMusic_Enable ; Is HandyMusic already disabled?
	beq .return
	PHX
	PHY
	LDX#3
	sei ; Disable interrupts only for a bit
	STZ HandyMusic_Enable
.backupregs
	LDY HandyMusic_Redirect_ChOffs,X
	LDA Lynx_Audio_TimerCont,Y
	STA HandyMusic_Pause_TimerBack,X	; Back up Timers, shutting each off
	LDA Lynx_Audio_Volume,Y
	STA HandyMusic_Pause_VolumeBack,X	; Do the same for the volume registers
	LDA#0
	STA Lynx_Audio_Volume,Y
	STA Lynx_Audio_TimerCont,Y
	DEX
	bpl .backupregs
	cli ; Interrupts back on
	PLX
	PLY
.return
	rts

;****************************************************************
; HandyMusic_UnPause::						*
;	UnPauses HandyMusic, restoring all channels. There is 	*
; checking to ensure HandyMusic is not "double unpaused."	*
;****************************************************************
HandyMusic_UnPause::
	LDA HandyMusic_Enable ; Is HandyMusic already enabled?
	bne .return
	PHX
	PHY
	LDX#3
	sei ; Disable IRQs for a bit
.restoreregs
	LDY HandyMusic_Redirect_ChOffs,X
	LDA HandyMusic_Pause_VolumeBack,X
	STA Lynx_Audio_Volume,Y			; Restore Volumes
	LDA HandyMusic_Pause_TimerBack,X
	STA Lynx_Audio_TimerCont,Y		; Restore Timers
	DEX
	bpl .restoreregs
	INC HandyMusic_Enable ; HandyMusic and IRQs on
	STZ HandyMusic_SFX_PlayRequest		; Kill any SFX requests during pause
	cli
	PLX
	PLY
.return
	rts

;****************************************************************
; HandyMusic_Init::						*
;	Initialize HandyMusic and the audio hardware to a known	*
; state with stereo sound enabled and no channels active.	*
;****************************************************************
HandyMusic_Init::
; Personal Note : The hardware is initialized
; with all channels off, so we're essentially just going to
; enable stereo and get HandyMusic ready to go.
	jsr HandyMusic_StopAll			; Make sure all channels are open.
	LDA#$FF   ; Enable attenuation on all channels,
	STA Lynx_Audio_Panning			; I'm guessing the write is just lost on the Lynx 1 (ed- I checked, open bus)
	STZ Lynx_Audio_Stereo			; Enable output in both L&R
	STA HandyMusic_Enable ; Now enable HandyMusic.
	rts


SndIRQ::
echo "Sound Engine IRQ Address: %HSoundIRQ"
        PHY
        jsr HandyMusic_Main
        PLY
        END_IRQ

;****************************************************************
;			  General Vars				*
;****************************************************************
;***************
; For Channels *
;***************
HandyMusic_Channel_BaseFreqLo	ds 4
HandyMusic_Channel_BaseFreqHi	ds 4
HandyMusic_Channel_BaseFreqDec	ds 4
; The base frequency for each channel stored in 16.8 precision, 
; this is set to zero when playing a sound effect, but is used
; for the note frequency on instruments.
; Each frame this value is adjusted by: BaseFrequency+=BasePitchAdjust

HandyMusic_Channel_BasePitAdjLo	ds 4
HandyMusic_Channel_BasePitAdjHi	ds 4
HandyMusic_Channel_BasePitAdjDec	ds 4
; The adjustment frequency for each channel stored in 16.8 precision,
; this is unused in SFX, but is used to alter the current note
; frequency in instruments (i.e. Pitch Bends).

HandyMusic_Channel_FreqOffsetLo	ds 4
HandyMusic_Channel_FreqOffsetHi	ds 4
HandyMusic_Channel_FreqOffsetDec	ds 4
; The offset from the base frequency stored in 16.8 precision,
; this is used in both notes and sound effects to calculate the
; final frequency, which is performed each frame as follows:
; Output Frequency = (FrequencyOffset+=OffsetPitchAdjust)+(BaseFrequency+=BasePitchAdjust)

HandyMusic_Channel_OffsetPitAdjLo	ds 4
HandyMusic_Channel_OffsetPitAdjHi	ds 4
HandyMusic_Channel_OffsetPitAdjDec	ds 4
; The adjustment frequency for each offset frequency stored in 16.8 precision,
; this is used in both SFX and notes to generate additional
; frequency changes such as pitch slides or vibrato.

HandyMusic_Channel_LastFreqLo	ds 4
HandyMusic_Channel_LastFreqHi	ds 4
; The previous frequency written to the channel, used to determine 
; if a channel should have its frequency register
; updated during its processing time.

HandyMusic_Channel_ForceUpd	ds 4
; Will force an update to the channel's timer at the end of
; processing if nonzero.

HandyMusic_Channel_Volume	ds 4
HandyMusic_Channel_VolumeDec	ds 4
; The volume for each channel stored in 8.8 precision,
; each frame this value is adjusted as: Volume+=VolumeAdjust

HandyMusic_Channel_VolumeAdjust	ds 4
HandyMusic_Channel_VolumeAdjustDec	ds 4
; The volume adjustment for each channel stored in 8.8 precision,
; this is used by both instruments and sound effects to generate
; volume envelopes.

HandyMusic_Channel_Panning	ds 4
; The panning of the current channel, this is only usable by
; notes. Sound effects have a constant panning of $FF (center),
; and ignore this value. Format is LLLLRRRR.

HandyMusic_Channel_DecodePointerLo	ds 4
HandyMusic_Channel_DecodePointerHi	ds 4
; The current instrumet/sfx script decode pointer.

HandyMusic_Channel_DecodeDelay	ds 4
; Delays the decoding of the current channel's instrument/sfx script.
; All volume/frequency envelope processing is still continued, however.

HandyMusic_Channel_NoteOffPLo	ds 4
HandyMusic_Channel_NoteOffPHi	ds 4
; Specifically for instruments, contains the pointer to the "note off"
; portion of a script.  Unused by sound effects.

HandyMusic_Channel_LoopAddrLo	ds 16
HandyMusic_Channel_LoopAddrHi	ds 16
HandyMusic_Channel_LoopCount	ds 16
HandyMusic_Channel_LoopAddrDepth	dc.b 0,4,8,12
; The address buffers used for script looping
;********************
; For Music Scripts *
;********************
HandyMusic_Music_DecodePointerLo	ds 4
HandyMusic_Music_DecodePointerHi	ds 4
; The current music script decode pointer.

HandyMusic_Music_DecodeDelayLo	ds 4
HandyMusic_Music_DecodeDelayHi	ds 4
; Delays the decoding of the next music script action by a
; 16 bit value.

HandyMusic_Music_LoopAddrLo	ds 16
HandyMusic_Music_LoopAddrHi	ds 16
HandyMusic_Music_LoopCount	ds 16
; The address buffers used for script looping

HandyMusic_Music_BasePitAdjLo	ds 4
HandyMusic_Music_BasePitAdjHi	ds 4
HandyMusic_Music_BasePitAdjDec	ds 4
; Mirrors of the values in the channel region, only copied in
; when a note is played.

HandyMusic_Music_LastInstrument	ds 4
; The last instrument used by the music script.
;*********
; Extras *
;*********
HandyMusic_Disable_Samples	ds 1
; Sample playback in both music and user requests will be
; dropped when this is nonzero, preferably should be set
; when loading from the cartridge.
;********************
; Redirection Table *
;********************
HandyMusic_Redirect_ChOffs::		dc.b 0,8,16,24
; These set of values are used to redirect the audio hardware
; addreses to an order which is "much more pleasing" to the programmer.
; This way they may be quickly accessed through ,X or ,Y addressing.
;HandyMusic_Note dc.b "No more room!"
;************************
; HandyMusic Space Left *
;************************
; SDLeft set $76AF-*
; echo "HandyMusic Memory left: %HSDLeft"
*
* EOF
*
