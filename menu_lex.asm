echo " "
echo " Loader and Depacker"
echo " "

BlockSize       set	2048
NewDirOffset	set	203
NEWHEAD		set	1
;;AUDIN_SWITCH	set	1 ;; not needed as I only load from frist bank

MENUX_FILE	set	1

;;USE_EXPLODER	set	1	; Size ~ $1F8 + 44 ZP
USE_PUCRUNCH	set	1	; Size ~ $1F8 + 44 ZP

* Macros

*				include "hardware.asm"
                include <macros/help.mac>
                include <macros/if_while.mac>
                include <macros/mikey.mac>
                include <macros/suzy.mac>
;                 include <macros/irq.mac>
                include <macros/file.mac>
;                 include <macros/debug.mac>
* Variablen
                include <vardefs/mikey.var>
                include <vardefs/suzy.var>
;                 include <vardefs/irq.var>
                include <vardefs/file.var>
;                 include <vardefs/debug.var>
;                 include <vardefs/serial.var>

IFD USE_EXPLODER
	include <vardefs/explod14.var>
ENDIF
IFD USE_PUCRUNCH
	include <vardefs/lynx_puc.var>
ENDIF

                
LoadFileUser	set 1

	run $E000
BlackAndReloadMenu
echo "RUN %HBlackAndReloadMenu"
        sei
	ldx #32-1
.ll
		stz $FDA0,x
		dex
	bpl .ll
	lda #MENUX_FILE
LoadAndDepackExecAuto
echo "LoadAndDepackExecAuto: %HLoadAndDepackExecAuto"
	stz DestPtr
	stz DestPtr+1
LoadAndDepackExec
echo "LoadAndDepackExec: %HLoadAndDepackExec"
	jsr LoadAndDepack
	jmp (entry+DestAddr)
LoadAndDepack::
echo "LoadAndDepack: %HLoadAndDepack"
	jsr OpenFile
;;IFD USE_PUCRUNCH
          lda entry+ExecFlag
	  cmp #"P"
	  _IFEQ
	      ldx entry+DestAddr
	      ldy entry+DestAddr+1
	      jmp pucrunch
	  _ELSE
;;ENDIF
              ldx entry+FileLen
              ldy entry+FileLen+1
	      jsr ReadBytes
;;IFD USE_PUCRUNCH
	  _ENDIF
;;ENDIF
IFD USE_EXPLODER
          lda entry+ExecFlag
	  cmp #"I"
	  _IFEQ
		ldx entry+DestAddr
		ldy entry+DestAddr+1
		stx Expl_a0
		sty Expl_a0+1
		jsr Explode_Data
	  _ENDIF
ENDIF
 	rts

       
IFD USE_EXPLODER
	include <alles/explod14.inc>
ENDIF
IFD USE_PUCRUNCH
	include <alles/lynx_puc.inc>
ENDIF
    include <includes/file.inc>

here equ  *
echo "Ende: %Hhere"
