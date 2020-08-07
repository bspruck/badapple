

PROJECT_NAME=apple_all


include $(LYNX_BASEDIR)/Makefile.base

apple_all : badapple.lnx apple.o

apple.o: badmusic.asm drivertc/HandyMusic.asm

badapple.lnx : badapple.mak title.puc apple.puc menu_lex.o
	$(LYNXDIR) badapple.mak

