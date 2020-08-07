;****************************************************************
;	    HandyMusic- Music Script Decode Commands		*
;****************************************************************
;Command Descriptions-						*
;								*
;0: Set Priority						*
;	Format: [0][Priority] (2 bytes)				*
;		Sets the priority of the track relative to 	*
;		the sound effects. Higher priorities win out 	*
;		when competing for channels, the same 		*
;		priorities should never be used between sound 	*
;		effects and instruments. A priority of zero 	*
;		stops the track from decoding.			*
;								*
;1: Set Panning							*
;	Format: [1][Panning] (2 bytes)				*
;		Sets the panning of the instruments 		*
;		played in the current channel.			*
;								*
;2: Note On							*
;	Format: [2][Instrument][Base Frequency Lo]		*
;		[Base Frequency Hi][Delay Lo] (5 bytes)		*
;		Plays a given instrument with the specified 	*
;		base frequency, then waits for the given 	*
;		one byte delay					*
;								*
;3: Note Off							*
;	Format: [3][Delay Lo] (2 bytes)				*
;		Forces the currently playing instrument into 	*
;		the note off portion of its script, then waits 	*
;		for the specified one byte delay.		*
;								*
;4: Set Base Frequency Adjustment				*
;	Format: [4][Base Frequency Adjustment Lo]		*
;		[Base Frequency Adjustment Hi]			*
;		[Base Frequency Adjustment Dec] (4 bytes)	*
;		Sets the Base Frequency Adjustment value, 	*
;		which can be used for pitch slides, etc. 	*
;		This value is initialized to zero on the 	*
;		start of a song.				*
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
;								*
;7: Wait							*
;	Format: [7][Delay Lo][Delay Hi] (3 bytes)		*
;		Stops decoding for the specified two byte delay.*
;								*
;8: Play Sample							*
;	Format: [8][Sample Number] (2 bytes)			*
;		Plays back the specified PCM sample in 		*
;		channel 0. Note that commands continue to 	*
;		process while the sample is played, so delays 	*
;		have to be added manually. Only call this	*
;		command in Track 0.				*
;								*
;9: Pattern Call						*
;	Format: [9][Address Lo][Address Hi] (3 Bytes)		*
;		Jumps to the address of the music script given,	*
;		and sets up the current position in the music	*
;		script as the destination for the Pattern	*
;		Return command.					*
;								*
;A: Pattern Return						*
;	Format: [A] (1 byte)					*
;		Returns to the portion of the music script	*
;		which was being played before the last Pattern	*
;		Call command.					*
;								*
;B: Short Note On						*
;	Format: [B][Base Frequency Lo][Base Frequency Hi]	*
;		[Delay Lo] (4 bytes)				*
;		Plays the last used instrument with the 	*
;		specifiedbase frequency, then waits for 	*
;		the given one byte delay.			*
;C: Pattern Break						*
;	Format: [C] (1 byte)					*
;		Returns all channels to the lowest return	*
;		address found in their pattern call stack.	*
;		This effectively returns all channels to the	*
;		main script (all of them- not just the		*
;		currently decoding channel).			*
;****************************************************************
HandyMusic_Mus_CommandTableLo
	dc.b <HandyMusic_Mus_SetPri,<HandyMusic_Mus_SetPan
	dc.b <HandyMusic_Mus_NoteOn,<HandyMusic_Mus_NoteOff
	dc.b <HandyMusic_Mus_SetFreqAdj,<HandyMusic_Music_SetLoop
	dc.b <HandyMusic_Mus_Loop,<HandyMusic_Mus_Wait
	dc.b <HandyMusic_Mus_Sampl,<HandyMusic_Mus_Call
	dc.b <HandyMusic_Mus_Ret,<HandyMusic_Mus_SNoteOn
	dc.b <HandyMusic_Mus_Break
HandyMusic_Mus_CommandTableHi
	dc.b >HandyMusic_Mus_SetPri,>HandyMusic_Mus_SetPan
	dc.b >HandyMusic_Mus_NoteOn,>HandyMusic_Mus_NoteOff
	dc.b >HandyMusic_Mus_SetFreqAdj,>HandyMusic_Music_SetLoop
	dc.b >HandyMusic_Mus_Loop,>HandyMusic_Mus_Wait
	dc.b >HandyMusic_Mus_Sampl,>HandyMusic_Mus_Call
	dc.b >HandyMusic_Mus_Ret,>HandyMusic_Mus_SNoteOn
	dc.b >HandyMusic_Mus_Break
;****************************************************************
; HandyMusic_Mus_GetBytes::					*
;	Gets the next byte of the SFX script, returns in A.	*
;****************************************************************
HandyMusic_Mus_GetBytes::
	LDA (HandyMusic_Music_DecodePointer)
	INC HandyMusic_Music_DecodePointer
	bne .norollover
	INC HandyMusic_Music_DecodePointer + 1
.norollover
	rts
;****************************************************************
; HandyMusic_Mus_SetPri::					*
;	Sets the priority of the music script to a new specified*
; value, takes effect immediately. A priority setting of zero	*
; will effectively disable the channel. Don't change the 	*
; priority of a channel in between a note on and off.		*
;****************************************************************
HandyMusic_Mus_SetPri::
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_Priority,X
	rts
;****************************************************************
; HandyMusic_Mus_SetPan::					*
;	Sets the stereo panning of the current channel, taking	*
; effect when the next note on command is reached. Format of	*
; panning is LLLLRRRR where 0000 is silent and 1111 is max.	*
;****************************************************************
HandyMusic_Mus_SetPan::
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Channel_Panning,X
	rts
;****************************************************************
; HandyMusic_Mus_NoteOn::					*
; HandyMusic_Mus_SNoteOn::					*
;	Plays a note on a given instrument at the specified 	*
; base frequency with the previously given panning and		*
; frequency adjustment values. Then waits on a one byte delay.	*
;****************************************************************
HandyMusic_Mus_NoteOn::
	jsr HandyMusic_Mus_GetBytes ; Get instrument # in A,Y
	STA HandyMusic_Music_LastInstrument,X
HandyMusic_Mus_SNoteOn::
	LDA HandyMusic_Music_LastInstrument,X
	TAY
	LDA HandyMusic_Music_Priority,X ; See if music is still in control of
	CMP HandyMusic_Channel_Priority,X ; the channel. If so, play the note.
	bcs .playnote00
	jsr HandyMusic_Mus_GetBytes ; Otherwise skip the playing and just set up
	jsr HandyMusic_Mus_GetBytes ; the delay.
	bra .playnote10
.playnote00
	STA HandyMusic_Channel_Priority,X ; Set channel priority to music priority
	STZ HandyMusic_Channel_LoopDepth,X ; Reset Loop Depth
	STZ HandyMusic_Channel_DecodeDelay,X ; And decode delay
	STZ HandyMusic_Channel_BaseFreqDec,X
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Channel_BaseFreqLo,X
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Channel_BaseFreqHi,X ; Copy passed frequency

	LDA HandyMusic_Music_BasePitAdjLo,X
	STA HandyMusic_Channel_BasePitAdjLo,X
	LDA HandyMusic_Music_BasePitAdjHi,X
	STA HandyMusic_Channel_BasePitAdjHi,X
	LDA HandyMusic_Music_BasePitAdjDec,X
	STA HandyMusic_Channel_BasePitAdjDec,X ; Then set up frequency adjustment value

	LDA (HandyMusic_Instrument_AddrTableLoLo),Y ; Copy script pointer to work pointer
	STA HandyMusic_Channel_DecodePointer
	LDA (HandyMusic_Instrument_AddrTableHiLo),Y
	STA HandyMusic_Channel_DecodePointer + 1

	jsr HandyMusic_Enqueue_IS ; Shared NoteOff, SFB, Vol, Freq in HandyMusic_EnqueueSFX

	LDA HandyMusic_Channel_NoWriteBack,X ; Writing disabled?
	bne .playnote10
	LDA HandyMusic_Channel_Panning,X
	STA Lynx_Audio_Atten_0,X ; Set up panning
.playnote10
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_DecodeDelayLo,X
	STZ HandyMusic_Music_DecodeDelayHi,X ; Set up one byte delay
	rts ; We're done
;****************************************************************
; HandyMusic_Mus_NoteOff::					*
;	Forces a note into the note off portion of its script	*
; if it still has control of the channel, then waits for a	*
; one byte delay. If the note has lost control of the channel	*
; only the delay is instated.					*
;****************************************************************
HandyMusic_Mus_NoteOff::
	LDA HandyMusic_Music_Priority,X ; See if music is still in control of
	CMP HandyMusic_Channel_Priority,X ; the channel. If not, just instate delay.
	bne .instatedelay
	LDA HandyMusic_Channel_NoteOffPLo,X
	STA HandyMusic_Channel_DecodePointerLo,X
	LDA HandyMusic_Channel_NoteOffPHi,X
	STA HandyMusic_Channel_DecodePointerHi,X ; Relocate decode pointer to note off
	STZ HandyMusic_Channel_DecodeDelay,X	; Force decode to happen
.instatedelay
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_DecodeDelayLo,X
	STZ HandyMusic_Music_DecodeDelayHi,X ; Set up one byte delay
	rts
;****************************************************************
; HandyMusic_Mus_SetFreqAdj::					*
;	Sets the frequency adjustment value for the current	*
; music track. This is useful for pitch bends, etc.		*
;****************************************************************
HandyMusic_Mus_SetFreqAdj::
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_BasePitAdjLo,X
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_BasePitAdjHi,X
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_BasePitAdjDec,X
	rts
;****************************************************************
; HandyMusic_Music_SetLoop::					*
;	Sets the current script decoding address as a loop	*
; point, increases the current loop depth, and copies the loop	*
; count.							*
;****************************************************************
HandyMusic_Music_SetLoop::
	INC HandyMusic_Music_LoopDepth,X ; Increase loop depth
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X ; Calculate depth into loop arrays
	ADC HandyMusic_Music_LoopDepth,X
	TAY
	jsr HandyMusic_Mus_GetBytes ; Get the number of times to loop
HandyMusic_Music_LoopPush
	STA HandyMusic_Music_LoopCount-1,Y ; Store in the loop count (offset by -1)
	LDA HandyMusic_Music_DecodePointer
	STA HandyMusic_Music_LoopAddrLo-1,Y
	LDA HandyMusic_Music_DecodePointer + 1
	STA HandyMusic_Music_LoopAddrHi-1,Y ; Store the current decode pointer
	rts ; That's it.
;****************************************************************
; HandyMusic_Mus_Loop::						*
;	Checks to see if a loop condition is valid, and loops	*
; if it is.							*
;****************************************************************
HandyMusic_Mus_Loop::
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X ; Calculate depth into loop arrays
	ADC HandyMusic_Music_LoopDepth,X
	TAY
	LDA HandyMusic_Music_LoopCount-1,Y ; If negative, this is an infinite loop
	bmi .loop
	DEC
	STA HandyMusic_Music_LoopCount-1,Y ; Decrement count, if zero, the loop fails
	beq .noloop
.loop
	LDA HandyMusic_Music_LoopAddrLo-1,Y
	STA HandyMusic_Music_DecodePointer
	LDA HandyMusic_Music_LoopAddrHi-1,Y
	STA HandyMusic_Music_DecodePointer + 1 ; Pull old decode address
	rts
.noloop
	DEC HandyMusic_Music_LoopDepth,X ; Decrement loop depth, we're done.
	rts
;****************************************************************
; HandyMusic_Mus_Wait::						*
;	Waits on a two byte delay.				*
;****************************************************************
HandyMusic_Mus_Wait::
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_DecodeDelayLo,X
	jsr HandyMusic_Mus_GetBytes
	STA HandyMusic_Music_DecodeDelayHi,X
	rts
;****************************************************************
; HandyMusic_Mus_Sampl::					*
;	Grabs Channel 0 and plays back the selected sample.	*
; Note that commands continue to process while the sample is	*
; played, so delays have to be added manually.			*
;****************************************************************
HandyMusic_Mus_Sampl::
	PHX
	jsr HandyMusic_Mus_GetBytes
;	jsr PlayPCMSample
	PLX
	rts
;****************************************************************
; HandyMusic_Mus_Call::						*
;	"JSR" to the specified location in the sound script.	*
; Note that this is logged as an infinite loop.			*
;****************************************************************
HandyMusic_Mus_Call::
	jsr HandyMusic_Mus_GetBytes ; Fetch Pattern Address Lo
	PHA
	jsr HandyMusic_Mus_GetBytes ; Fetch Pattern Address Hi
	PHA
	INC HandyMusic_Music_LoopDepth,X ; Increase loop depth
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X ; Calculate depth into loop arrays
	ADC HandyMusic_Music_LoopDepth,X
	TAY
	LDA#$80
	jsr HandyMusic_Music_LoopPush

	PLA
	STA HandyMusic_Music_DecodePointer + 1
	PLA
	STA HandyMusic_Music_DecodePointer ; Set decode pointer to pattern address
	rts
;****************************************************************
; HandyMusic_Mus_Ret::						*
;	"rts" from the current location in the sound script.	*
;****************************************************************
HandyMusic_Mus_Ret::
	jsr HandyMusic_Mus_Loop ; "Loop" to return address
	DEC HandyMusic_Music_LoopDepth,X ; But force loop depth to decrement
	rts
;****************************************************************
; HandyMusic_Mus_Break::					*
;	Pattern break, returning all channels to the main	*
; track (lowest CALL found, based upon $80 tags, if any).	*
;****************************************************************
HandyMusic_Mus_Break::
	jsr HandyMusic_BackupDecodePointer ; Temporary decode pointer will get trashed.
	PHX
	LDX#3
.checkNextTrack
	clc
	LDA HandyMusic_Channel_LoopAddrDepth,X
	TAY
	ADC HandyMusic_Music_LoopDepth,X
	STA .checkLoopPoint + 1
.checkLoopPoint
	CPY#0		; Comparison value modified by STA above to stack top
	beq .trackDone
	LDA HandyMusic_Music_LoopCount,Y
	INY
	CMP#$80		; Any loop count of $80 is a special tag for calls
	beq .foundBase	; So if we found one from the bottom up, that's our base call
	bra .checkLoopPoint ; Otherwise, check the next entry in the stack
.foundBase
	TYA
	sec
	SBC HandyMusic_Channel_LoopAddrDepth,X
	STA HandyMusic_Music_LoopDepth,X
	jsr HandyMusic_Mus_Ret ; Force a RET on the lowest CALL
	STZ HandyMusic_Music_DecodeDelayLo,X
	STZ HandyMusic_Music_DecodeDelayHi,X ; Also force the track to proceed immediately.
	jsr HandyMusic_BackupDecodePointer ; Then back up the decode pointer
.trackDone
	DEX
	bpl .checkNextTrack
	PLX
	LDA HandyMusic_Music_DecodePointerLo,X
	STA HandyMusic_Music_DecodePointer
	LDA HandyMusic_Music_DecodePointerHi,X
	STA HandyMusic_Music_DecodePointer + 1 ; Restore the temporary decode pointer
	rts
*
* EOF
*
