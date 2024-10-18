DEMO=demo

ASFLAGS=-sh

$(DEMO).o: $(DEMO).asm world.inc sintab.inc deltatab.inc

%.o: %.asm
	@lyxass  $(ASFLAGS) $<

%.bin: %.asm
	@lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<


include ../Rules.launch

clean:
	@rm -f *.lnx *.lyx *.bin *~ *.equ

real-clean:
	@rm -f *.o
