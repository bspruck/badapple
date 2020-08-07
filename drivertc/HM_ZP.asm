;****************************************************************
;		HandyMusic- Memory Layout/Defines		*
;****************************************************************
; All of the ZeroPage Variables for HandyMusic are listed
; below with a description of their function.
;****************************************************************
;			  Zeropage Vars				*
;****************************************************************
;***********************
; General/Flow Control *
;***********************
HandyMusic_Enable	ds 1
; Enable (!0) HandyMusic processing.
; This is enabled after initialization, and disabled during pause.

HandyMusic_Active	ds 1
; HandyMusic is currently processing data if this is non-zero.
; Used to check for double-entry into the driver.

HandyMusic_BGMPlaying	ds 1
; Simple boolean flag to indicate if the background music
; is playing or not.
;***************
; Pause Backup *
;***************
HandyMusic_Pause_TimerBack	ds 4
HandyMusic_Pause_VolumeBack	ds 4
; Backup values of the timer and volume registers used
; when HandyMusic is paused or unpaused.
;***************
; For Channels *
;***************
HandyMusic_Channel_NoWriteBack 	ds 4
; Disables writing any data to the respective channel
; if non-zero. All frequency calculations, etc. are 
; still performed, but writes are disabled until the
; setting is zeroed again. Useful for grabbing channels
; for sample playback, etc.

HandyMusic_SFX_AddressTableLoLo	ds 1
HandyMusic_SFX_AddressTableLoHi	ds 1
HandyMusic_SFX_AddressTableHiLo	ds 1
HandyMusic_SFX_AddressTableHiHi	ds 1
HandyMusic_SFX_AddressTablePriLo	ds 1
HandyMusic_SFX_AddressTablePriHi	ds 1
; The pointers to three tables, each respectively 
; containing the low address, high address, and priority
; of the sound effect scipts

HandyMusic_SFX_EnqueueNext	ds 1
HandyMusic_SFX_PlayRequest	ds 1
; If a sound effect needs to be added on the next frame,
; its number will be located here.

HandyMusic_Channel_DecodePointer	ds 2
; The 16-bit pointer used to decode instruments and sound
; effects. This is shared by any Instruments or SFX playing
; as each takes a turn being decoded by the driver.

HandyMusic_Channel_Priority 	ds 4
; The current priorty of the four audio channels in the
; Lynx. A priority of 0 is considered inactive (no sound),
; if a sound effect is playing on the channel, its current priority
; will be respectively stored here, if the channel is in use by 
; the background music driver, the current Instrument's
; priority will be stored here.
; Please note that if a SFX or Instrument sets its priority to zero
; it will never play, as this flag is also used during channel update
; decoding.

HandyMusic_Channel_LoopDepth	ds 4
; The current depth into the sound effect and instrument loop points.

HandyMusic_Channel_FinalFreqLo	ds 1
HandyMusic_Channel_FinalFreqHi	ds 1
; A temporary variable used to hold the final calculated frequency
;********************
; For Music Scripts *
;********************
HandyMusic_Instrument_AddrTableLoLo	ds 1
HandyMusic_Instrument_AddrTableLoHi	ds 1
HandyMusic_Instrument_AddrTableHiLo	ds 1
HandyMusic_Instrument_AddrTableHiHi	ds 1
; The pointers to three tables, each respectively 
; containing the low address, high address, and priority
; of the instrument scipts

HandyMusic_Music_DecodePointer	ds 2
; The 16-bit pointer used to decode the music script. This
; is shared by the four music tracks, each takes a turn
; running through the script, copying its own current decode
; address here.

HandyMusic_Music_Priority 	ds 4
; The current priorty of the four music tracks, used to check
; if the note still has control of the channel. A value of zero
; indicates that decoding has stopped for this channel.

HandyMusic_Music_LoopDepth	ds 4
; The current depth into the music track loop points.

*
* EOF
*
