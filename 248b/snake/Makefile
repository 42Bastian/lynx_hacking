DEMO=snake

all: $(DEMO).o

include ../Rules.launch

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

lnx_felix: $(DEMO).asm
	lyxass -d -D LNX=1 -D FELIX=1 -o $(DEMO)_felix.bin $<
	lynxenc $(DEMO)_felix.bin $(DEMO)_felix.lyx
	bzcat allff.lyx.bz2 >> $(DEMO)_felix.lyx
	make_lnx $(DEMO)_felix.lyx -b0 256K -o $(DEMO)_felix.lnx
	rm -f $(DEMO)_felix.lyx
	rm -f $(DEMO)_felix.bin
	@echo

lnx: $(DEMO).lnx

%.lnx: %.asm
	lyxass -d -D LNX=1 $(TJFLAGS) -o $(DEMO).bin $<
	lynxenc $(DEMO).bin $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	rm -f $(DEMO).lyx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.o
