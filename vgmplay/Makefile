DEMO=vgmplay

ASFLAGS=-sh

$(DEMO).o: $(DEMO).asm vgmplay.inc

%.o: %.asm
	@lyxass  $(ASFLAGS) $<

%.bin: %.asm
	@lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<


lnx: $(DEMO).lnx
$(DEMO).lnx: $(DEMO).asm vgmplay.inc x.v2l
	lyxass -d $(ASFLAGS) -D LNX=1 -o $@ $(DEMO).asm

include Rules.launch

clean:
	@rm -f *.lyx *.bin *~ *.equ

real-clean:
	@rm -f *.o *.lnx
