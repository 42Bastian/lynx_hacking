DEMO=plasmosis

LNX=$(DEMO).lnx

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass $<

bin: $(DEMO).bin

%.bin: %.asm
	lyxass -d -D LNX=1  -o $*.bin $*.asm

lnx: $(LNX)

%.lnx: %.bin
	lynxenc $(DEMO).bin $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.equ *.o

include Rules.launch
