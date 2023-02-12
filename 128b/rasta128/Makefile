DEMO=rasta128

all: $(DEMO).o

include ../Rules.launch

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

lnx: $(DEMO).lnx

%.lnx: %.asm
	lyxass -d -D LNX=1 -o $(DEMO).bin $<
	lynxenc $(DEMO).bin $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	rm -f $(DEMO).lyx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~
