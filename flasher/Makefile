ifeq ($(OS),Windows_NT)
CC = x86_64-w64-mingw32-gcc
DST=bin/mingw
EXT=.exe
else
CC = gcc
DST=.
EXT=#
endif

CFLAGS=-Os -fomit-frame-pointer

.SUFFIXES: .asc .obj .S .asm

%.o: %.asm
	lyxass  $<

.obj.asc:
	bin2asc < $*.obj >$@

.c.o:
	$(CC) $(CFLAGS) -c $<
.S.o:
	$(CC) -c $< -o $@

all: $(DST)/flash_up$(EXT)

flash_code.o: flash_code.S flashcard.o

$(DST)/flash_up$(EXT): flash_up.o flash_code.o
	$(CC) flash_up.o flash_code.o -o $@
	upx -9 $@

clean:
	rm -f *.o
	rm -f *~
