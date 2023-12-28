DEMO=monalynx

all: lnx

$(DEMO).o: $(DEMO).asm

%.o: %.asm monalynx.var
	lyxass -v $<

bin: monaload.bin monalynx.bin

monaload.bin: monalynx.equ

%.equ %.bin: %.asm
	lyxass -d -sh -D LNX=1 -o $*.bin $*.asm

lnx: $(DEMO).lnx

%.lnx: %.asm monaload.bin monalynx.bin
	lynxenc monaload.bin monaload.enc
	cat monaload.enc $(DEMO).bin > $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin *.enc monaload.o

include ../Rules.launch
