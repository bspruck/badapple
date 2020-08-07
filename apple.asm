
; XL   https://www.youtube.com/watch?v=BjNm04oCdYc
; 2600 https://www.youtube.com/watch?v=Ko9ZA50X71s
; ST   https://www.youtube.com/watch?v=wuOmoV5edRk
; ST   making of https://www.youtube.com/watch?v=_j66Nu7BoCE&list=PLgN_eM4h7HQNkdjhMHn5ca7VQLANrEc-i&index=6
; Speccy https://www.youtube.com/watch?v=09u_Ew2Zrh4&list=PLgN_eM4h7HQNkdjhMHn5ca7VQLANrEc-i
; C64  https://www.youtube.com/watch?v=OsDy-4L6-tQ
; Speccy https://www.youtube.com/watch?v=cd5iEeIe7L0&index=64&list=PLgN_eM4h7HQNkdjhMHn5ca7VQLANrEc-i
; Oszi https://www.youtube.com/watch?v=SlMxg7NEfEI&list=PLgN_eM4h7HQNkdjhMHn5ca7VQLANrEc-i&index=71
; Casio https://www.youtube.com/watch?v=fMJV8He9HCE&list=PLgN_eM4h7HQNkdjhMHn5ca7VQLANrEc-i&index=74

HALFX   set 1
HALFY   set 1
MONO    set 0
UNPACKED    set 1

; 0 ist LEX
; 1 ist main binary
FILE_TITLE_PIC  set        2
FILE_VIDEO      set        3

***************
* 
****************

;DEBUG			set 1
;BRKuser         set 1
Baudrate        set 9600
BlockSize       set 2048
NewDirOffset    set 203

SND_TIMER       set 7

    path
    path "drivertc"
    include "bsmac.mac"

    include <alles/hardware.asm>
****************
* macros
    path
    include <alles/help.mac>
    include <alles/if_while.mac>
    include <alles/mikey.mac>
    include <alles/suzy.mac>
    include <alles/irq.mac>
    include <alles/newkey.mac>
    include <alles/file.mac>
    include <alles/window.mac>
    include <alles/font.mac>

    MACRO SHOW
    LDAY \0
    jsr DrawSprite
    ENDM

    MACRO JSHOW
    LDAY \0
    jmp DrawSprite
    ENDM

****************
* variables

    include <alles/help.var>
    include <alles/mikey.var>
    include <alles/suzy.var>
    include <alles/file.var>
    include "krilldecr.var"
    include <alles/irq.var>
    include <alles/newkey.var>
;     include <alles/bcd.var>
    include <alles/window.var>
    include <alles/font.var>

****************

    path
    path "drivertc"
    include "HAud_Def.asm"

BEGIN_ZP

VBLsema         ds 1

vbl_count       ds  1
sprflag         ds  1
sprptr          ds  2
data1ready      ds  1
data2ready      ds  1
play            ds  1
startflag       ds  1
fnr             ds  1

END_ZP



BEGIN_MEM

irq_vektoren    ds  16

END_MEM

; /****************************************/
; /*              M  A  I  N              */
; /****************************************/

    run LOMEM
Start::
    START_UP             ; Start-Label needed for reStart

    CLEAR_ZP +STACK ; clear stack ($100) too
;    CLEAR_MEM

    jsr black

    INITMIKEY
    INITSUZY

    FRAMERATE 60
    INITIRQ irq_vektoren
;    INITFONT LITTLEFNT,WHITE,WHITE
    INITFONT SMALLFNT,WHITE,BLACK
    SET_MINMAX 0,0,160,102
    INITKEY ,_FIREA|_FIREB          ; repeat for A & B

    SETIRQ 2,VBL

;     MOVEI screen0, DestPtr
;     lda #FILE_TITLE_PIC
;     jsr MyReadFile
    
    
        php
        sei
        lda #%10011000|_31250Hz
        sta $fd01+SND_TIMER*4
        lda #135 ; 129 sind 240Hz
        sta $fd00+SND_TIMER*4           ; set up a 240Hz IRQ

        stz $fd20
        stz $fd28
        stz $fd30
        stz $fd38       ; all volumes zero

;         stz $fd44       ; all channels full volume / no attenuation
        lda #$ff
        stz $fd44       ; all channels with attenuation
        stz $fd50       ; all channels on

        lda #0 ; %01011000
        sta $fd20+5
        sta $fd28+5
        sta $fd30+5
        sta $fd38+5

        plp

        ;Setup HandyMusic SFX Pointers
;         LDA#<HandyMusic_SFX_ATableLo
;         STA HandyMusic_SFX_AddressTableLoLo
;         LDA#>HandyMusic_SFX_ATableLo
;         STA HandyMusic_SFX_AddressTableLoHi
;         LDA#<HandyMusic_SFX_ATableHi
;         STA HandyMusic_SFX_AddressTableHiLo
;         LDA#>HandyMusic_SFX_ATableHi
;         STA HandyMusic_SFX_AddressTableHiHi
;         LDA#<HandyMusic_SFX_PTable
;         STA HandyMusic_SFX_AddressTablePriLo
;         LDA#>HandyMusic_SFX_PTable
;         STA HandyMusic_SFX_AddressTablePriHi
        ;Run the HandyMusic initializer
        jsr HandyMusic_Init

        lda #200
        sta HandyMusic_Music_Priority+0
        sta HandyMusic_Music_Priority+1
        sta HandyMusic_Music_Priority+2
        sta HandyMusic_Music_Priority+3

    cli
    SCRBASE screen0, screen0 ; screen1
    stz BG_Color
    lda #15
    sta FG_Color

    SWITCHBUF

    SETRGB pal
    
    SETIRQ SND_TIMER,SndIRQ
        


; .keyloop
; ;         lda test_play_delay
; ;         beq .start
;         jsr ReadKey
;         lda $FCB0
;         and #$03
;     beq .keyloop
; 
; .keyloop2
;         cmp $FCB0
;     beq .keyloop2
;     
;     SWITCHBUF
; 
; .keyloop3
; ;         lda test_play_delay
; ;         beq .start
;         jsr ReadKey
;         lda $FCB0
;     beq .keyloop3
; 
; .keyloop4
;         cmp $FCB0
;     beq .keyloop4
; 
; .loop
;         jsr ReadKey
;     bne .loop

startvideo
    stz startflag
    VSYNC
    SHOW CLSscb
    VSYNC

    jsr stop_music
    
    lda #FILE_VIDEO
    sta fnr
    jsr OpenFile

    stz play
    lda #1
    sta data1ready
    sta data2ready
    jsr MyReadChunk1    
    jsr MyReadChunk2
    
    jsr HandyMusic_PlayMusic

    MOVEI sprdata1, sprptr
    stz sprflag
    inc sprflag
    inc play

runloop
.runloop1
        jsr update_screen
        lda startflag
        bne startvideo
        lda data1ready
    beq .runloop1
    jsr MyReadChunk1

.runloop2
        jsr update_screen
        lda startflag
        bne startvideo
        lda data2ready
    beq .runloop2
    jsr MyReadChunk2

    bra runloop


update_screen::
    lda $FCB0
    bit #$02
     _IFEQ
         lda vbl_count
         cmp #5
         _IFCC
             rts
         _ENDIF
     _ELSE
         lda vbl_count
         _IFEQ ; wait at least one VBL
             rts
         _ENDIF
     _ENDIF

    lda play
    _IFEQ
        rts
    _ENDIF

    phx
    phy
    stz vbl_count

    ; Wait if next sprite is ready!
    ; Set X,Y
    
    lda (sprptr)  ; X
    cmp #$FF
    _IFEQ
        jmp switchnextbuffer ; before pre increase
    _ENDIF

    inc sprptr
    _IFEQ
        inc sprptr+1
    _ENDIF
    cmp #$FE
    _IFEQ
        jmp endofplay
    _ENDIF
IF HALFX
    asl
ENDIF
    sta dummyX

    lda (sprptr)  ; Y
    inc sprptr
    _IFEQ
        inc sprptr+1
    _ENDIF
    bit #$80
    _IFNE
        and #$7f
IF HALFY
        asl
ENDIF
        sta dummyY
IF HALFX
        inc dummyX
ENDIF
IF MONO
        lda #$26
ELSE
        lda #$66
ENDIF
    _ELSE
        asl
IF HALFY
        sta dummyY
ENDIF
IF MONO
        lda #$06
ELSE
        lda #$46
ENDIF
    _ENDIF
    sta dummySCB

;     lda dummySY+1
;     eor #$03
;     sta dummySY+1
    
;     stz vbl_count
;     VSYNC
         lda $FCB0
         and #$01
         _IFNE
            lda #$21
            sta dummy_color
            SHOW dummySCB
.kl
                lda $FCB0
            bne .kl
            SHOW dummySCB
            
            lda #$07
            sta dummy_color
            stz vbl_count
         _ENDIF
         
        MOVE sprptr, dummy_sprdata
        SHOW dummySCB

        ; Skip the sprite, adjust ptr to next
lineloop
        lda (sprptr)  ; Y
        inc sprptr
        _IFEQ
            inc sprptr+1
        _ENDIF
        tax
        beq endofsprite
        dec
        beq lineloop ; 1 would be change direction, this works by magic, too
        clc
        adc sprptr
        sta sprptr
        lda #0
        adc sprptr+1
        sta sprptr+1
    bra lineloop
endofsprite

    lda (sprptr)  ; Check, but dont increase ptr
    cmp #$FF
    _IFEQ
switchnextbuffer
        lda sprflag
        _IFEQ
            inc
            sta data2ready
            lda data1ready
            _IFEQ
                MOVEI sprdata1, sprptr
                inc sprflag
            _ENDIF
        _ELSE
            sta data1ready
            lda data2ready
            _IFEQ
                MOVEI sprdata2, sprptr
                stz sprflag
            _ENDIF
        _ENDIF
    _ELSE
        cmp #$FE
        _IFEQ
endofplay
            lda play
            _IFNE
                inc startflag
                stz play
            _ENDIF
        _ENDIF
    _ENDIF

    ply
    plx
    rts
    

black::
    ldx #32-1
.black
        stz $FDA0,x
        dex
    bpl .black
    rts


stop_music::
    jsr HandyMusic_StopAll
    ldx #3
.off
        phx
        sei
        jsr HandyMusic_Mus_NoteOff
        cli
        plx
        dex
    bpl .off
    rts


waitnokey::
.keyloop3
        jsr ReadKey
        bne .keyloop3
        lda $FCB0
    bne .keyloop3
    rts

MyReadChunk1::
; Load File A to DestPtr
;     lda fnr
;     jsr OpenFile
;     inc fnr
    MOVEI sprdata1, zp_dest_lo
	jsr decrunch
    stz data1ready
	rts

MyReadChunk2::
; Load File A to DestPtr
;     lda fnr
;     jsr OpenFile
;     inc fnr
    MOVEI sprdata2, zp_dest_lo
	jsr decrunch
    stz data2ready
	rts

get_crunched_byte:
    php
    phx
    phy
    jsr update_screen
    jsr ReadByte
    ply
    plx
    plp
	rts

VBL::
    lda #$ff
    tsb VBLsema
    _IFEQ
        cli
        jsr Keyboard                    ; read buttons
        stz VBLsema
    _ENDIF
    inc vbl_count
    END_IRQ


CLSscb         db $00,$10,00
                dw 0
                dw CLSdata
                dw 0,0
                dw 10*$100,102*$100
.CLScolor       db $00
CLSdata        db 2,%01111100,0


dummySCB:
IF MONO
    dc.b $06
ELSE
    dc.b $46
ENDIF
IF UNPACKED
    dc.b $90,$00
ELSE
    dc.b $10,$00
ENDIF
    dc.w 0
dummy_sprdata
    dc.w sprdata1
dummyX
    dc.w 0
dummyY
    dc.w 0
dummySX
IF HALFX
    dc.w $200
ELSE
    dc.w $100
ENDIF
dummySY
IF HALFY
    dc.w $200
ELSE
    dc.w $100
ENDIF
dummy_color:
IF MONO
    dc.b $0F
ELSE
    dc.b $07,$8F
ENDIF

; data: 5*1 pixel
dummy_data
    dc.b 2,$24,0

pal:
	dc.b $00, $02, $06, $06, $02, $02, $06, $05
	dc.b $0C, $04, $0F, $0F, $04, $04, $0F, $0F
	dc.b $00, $26, $22, $26, $62, $66, $62, $55,
	dc.b $CC, $4F, $44, $4F, $F4, $FF, $F4, $FF
;  	dc.b $00, $00, $00, $00, $00, $00, $00, $00
;  	dc.b $00, $00, $00, $00, $00, $00, $00, $0F
;  	dc.b $00, $00, $00, $00, $00, $00, $00, $00,
;  	dc.b $00, $00, $00, $00, $00, $00, $00, $FF


;**************************
; HandyAudition Functions *
;**************************
;All of them...
;	include "HA_All.asm"
****************************************

****************
* INCLUDES

    path
    include <alles/newkey.inc>
    include <alles/irq.inc>
    include <alles/file.inc>
    include <alles/window2.inc>
    include <alles/font.inc>
    include <alles/font2.hlp>
    include "krilldecr.inc"
    path "drivertc"
;Main Driver Source
    include "HandyMusic.asm"


****************

    path
;     include "instruments.asm"
badmusic:: ;; MUSIC_TRACK_HEADER
	include "badmusic.asm"
HandyMusic_Song_Priorities	set badmusic + 0
HandyMusic_Song_TrackAddrLo	set badmusic + 4
HandyMusic_Song_TrackAddrHi	set badmusic + 8
HandyMusic_Song_InstrLoLo	set badmusic + 12
HandyMusic_Song_InstrLoHi	set badmusic + 13
HandyMusic_Song_InstrHiLo	set badmusic + 14
HandyMusic_Song_InstrHiHi	set badmusic + 15

sprdata1

screen0 set $E000

left    set(screen0-sprdata1)

sprdata2 set sprdata1+(left/2)

echo "Sprite Data starting at %Hsprdata1"
echo "Sprite Data starting at %Hsprdata2"
echo "Sprite Data max is half of $%Hleft / %dleft"
