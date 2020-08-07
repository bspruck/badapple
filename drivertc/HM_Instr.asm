;****************************************************************
;	HandyMusic- Instrument/SFX Script Decode Commands	*
;****************************************************************
;Command Descriptions-						*
;								*
;0: Stop Script Decoding					*
;	Format: [0] (1 byte)					*
;		Immediately stops the decoding of 		*
;		the sound script and frees the channel.		*
;1: Wait							*
;	Format: [1][Number of Frames] (2 bytes)			*
;		Pauses sound script decoding for the 		*
;		specified number of frames.			*
;								*
;2: Set Shift, Feedback, and Integrate Mode			*
;	Format: [2][ShiftReg Lo][ShiftReg Hi][Feedback Lo]	*
;		[Feedback Hi + Integrate Flag] (5 bytes)	*
;		Replaces the current shift and feedback 	*
;		register contents with the specified new 	*
;		values, stored in the same format as in the 	*
;		instrument/sfx header.				*
;								*
;3: Set Volume and Volume Adjustment				*
;	Format: [3][Volume][Volume Adjustment]			*
;		[Volume Adjustment Decimal] (4 bytes)		*
;		Replaces the current volume and volume		*
;		adjustment values with the specified new values.*
;								*
;4: Set Frequency Offset and Frequency Offset Adjustment	*
;	Format: [4][Frequency Offset Lo][Frequency Offset Hi]	*
;		[Frequency Offset Adjustment Lo]		*
;		[Frequency Offset Adjustment Hi]		*
;		[Frequency Offset Adjustment Decimal] (6 bytes)	*
;		Replaces the current frequency offset and 	*
;		frequency offset adjustment values with 	*
;		the specified new ones.				*
;								*
;5: Set Loop Point						*
;	Format: [5][Number of Times to Loop] (2 bytes)		*
;		Defines the location in the script following 	*
;		this command as a loop point which will be 	*
;		returned to the specified number of times. If 	*
;		a negative number is used, the loop will 	*
;		continue infinitely.				*
;								*
;6: Loop							*
;	Format: [6] (1 byte)					*
;		If the loop is not infinite, the loop counter 	*
;		is decremented and unless the counter has 	*
;		reached zero, the script decoder will continue 	*
;		decoding at the loop point.			*
;		Loops may be four-deep.				*
;****************************************************************
HandyMusic_SFX_CommandTableLo
	dc.b <HandyMusic_FreeChannel,<HandyMusic_SFX_Wait,<HandyMusic_SFX_SetSFB
	dc.b <HandyMusic_SFX_SetVolume,<HandyMusic_SFX_SetFrequency
	dc.b <HandyMusic_SFX_SetLoop,<HandyMusic_SFX_Loop
HandyMusic_SFX_CommandTableHi
	dc.b >HandyMusic_FreeChannel,>HandyMusic_SFX_Wait,>HandyMusic_SFX_SetSFB
	dc.b >HandyMusic_SFX_SetVolume,>HandyMusic_SFX_SetFrequency
	dc.b >HandyMusic_SFX_SetLoop,>HandyMusic_SFX_Loop
;****************************************************************
; HandyMusic_SFX_GetBytes::					*
;	Gets the next byte of the SFX script, returns in A.	*
;****************************************************************
HandyMusic_SFX_GetBytes::
	LDA (HandyMusic_Channel_DecodePointer)
	INC HandyMusic_Channel_DecodePointer
	bne .norollover
	INC HandyMusic_Channel_DecodePointer + 1
.norollover
	rts
;****************************************************************
; HandyMusic_SFX_Wait::						*
;	Sets a delay which is waited upon before decoding any	*
; other script commands.					*
;****************************************************************
HandyMusic_SFX_Wait::
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_DecodeDelay,X
	rts
;****************************************************************
; HandyMusic_SFX_SetSFB::					*
;	Sets the shift and feedback registers, the channel is	*
; also shut off during this time. But it will be turned back	*
; on during the frequency/volume envelope calculation period.	*
;****************************************************************
HandyMusic_SFX_SetSFB::
	LDY HandyMusic_Redirect_ChOffs,X
	LDA#0
	STA Lynx_Audio_TimerCont,Y		; Disable Counter
	DEC
	STA HandyMusic_Channel_ForceUpd,X	; Force update channel.

	jsr HandyMusic_SFX_GetBytes
	STA Lynx_Audio_ShiftRegLo,Y		; Copy low bits of shift register
	jsr HandyMusic_SFX_GetBytes
	STA Lynx_Audio_AudioExtra,Y		; Copy high bits of shift register
	jsr HandyMusic_SFX_GetBytes
	STA Lynx_Audio_FeedBackReg,Y		; Copy feedback bits
	jsr HandyMusic_SFX_GetBytes
	STA Lynx_Audio_TimerCont,Y		; Copy Feedback bit 7 and integrate

	rts ; That's all, folks. The channel is off for a bit, but that should be ok.
;****************************************************************
; HandyMusic_SFX_SetVolume::					*
;	Sets the Volume and Volume Envelope for the channel.	*
;****************************************************************
HandyMusic_SFX_SetVolume::
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_Volume,X
	STZ HandyMusic_Channel_VolumeDec,X ; Copy Volume, clear decimal

	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_VolumeAdjust,X
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_VolumeAdjustDec,X ; Copy Volume Adjustment & Decimal
	rts
;****************************************************************
; HandyMusic_SFX_SetFrequency::					*
;	Sets the Frequency and Frequency Envelope for the	*
; channel.							*
;****************************************************************
HandyMusic_SFX_SetFrequency::
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_FreqOffsetLo,X
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_FreqOffsetHi,X
	STZ HandyMusic_Channel_FreqOffsetDec,X ; Copy frequency Lo/Hi, clear decimal

	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_OffsetPitAdjLo,X
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_OffsetPitAdjHi,X
	jsr HandyMusic_SFX_GetBytes
	STA HandyMusic_Channel_OffsetPitAdjDec,X ; Copy frequency Adjustment Lo,Hi,Dec

	LDA#$FF
	STA HandyMusic_Channel_ForceUpd,X	; Force update channel.
	rts
;****************************************************************
; HandyMusic_SFX_SetLoop::					*
;	Sets the current script decoding address as a loop	*
; point, increases the current loop depth, and copies the loop	*
; count.							*
;****************************************************************
HandyMusic_SFX_SetLoop::
	INC HandyMusic_Channel_LoopDepth,X ; Increase loop depth
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X ; Calculate depth into loop arrays
	ADC HandyMusic_Channel_LoopDepth,X
	TAY
	jsr HandyMusic_SFX_GetBytes ; Get the number of times to loop
	STA HandyMusic_Channel_LoopCount-1,Y ; Store in the loop count (offset by -1)
	LDA HandyMusic_Channel_DecodePointer
	STA HandyMusic_Channel_LoopAddrLo-1,Y
	LDA HandyMusic_Channel_DecodePointer + 1
	STA HandyMusic_Channel_LoopAddrHi-1,Y ; Store the current decode pointer
	rts ; That's it.
;****************************************************************
; HandyMusic_SFX_Loop::						*
;	Checks to see if a loop condition is valid, and loops	*
; if it is.							*
;****************************************************************
HandyMusic_SFX_Loop::
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X ; Calculate depth into loop arrays
	ADC HandyMusic_Channel_LoopDepth,X
	TAY
	LDA HandyMusic_Channel_LoopCount-1,Y ; If negative, this is an infinite loop
	bmi .loop
	DEC
	STA HandyMusic_Channel_LoopCount-1,Y ; Decrement count, if zero, the loop fails
	beq .noloop
.loop
	LDA HandyMusic_Channel_LoopAddrLo-1,Y
	STA HandyMusic_Channel_DecodePointer
	LDA HandyMusic_Channel_LoopAddrHi-1,Y
	STA HandyMusic_Channel_DecodePointer + 1 ; Pull old decode address
	rts
.noloop
	DEC HandyMusic_Channel_LoopDepth,X ; Decrement loop depth, we're done.
	rts


*
* EOF
*
