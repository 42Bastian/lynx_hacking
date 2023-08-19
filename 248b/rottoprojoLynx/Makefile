DEMO=rottoprojoLynx

$(DEMO).o: $(DEMO).asm

include ../Rules.launch

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
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin *.o
