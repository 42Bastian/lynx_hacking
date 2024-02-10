DEMO=lynxYARC512

all: $(DEMO).lnx

$(DEMO).o: $(DEMO).asm

%.o: %.asm line.inc
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

loader.lyx: loader.bin
	lynxenc $< $@

lnx: $(DEMO).lnx

$(DEMO).lnx: $(DEMO).lyx
	make_lnx $< -b0 256K -o $@
	@echo

$(DEMO).lyx: $(DEMO).bin loader.lyx
	cat loader.lyx > $@
	cat $(DEMO).bin >> $@
	bzcat ../../allff.lyx.bz2 >> $@
	truncate -s 256K $@

.PHONY: clean
clean:
	rm -f *.lyx *~ *.o

include ../../Rules.launch
