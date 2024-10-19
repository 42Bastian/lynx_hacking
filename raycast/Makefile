DEMO=demo

ASFLAGS=-sh

$(DEMO).o: $(DEMO).asm world.inc sintab.inc deltatab.inc mandel.inc phobyx.inc

mandel.inc: spr/mandel000000.spr
phobyx.inc: spr/phobyx000000.spr

%.o: %.asm
	@lyxass  $(ASFLAGS) $<

%.bin: %.asm
	@lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<


include ../Rules.launch

clean:
	@rm -f *.lnx *.lyx *.bin *~ *.equ

real-clean:
	@rm -f *.o

spr/mandel000000.spr: mandel.sps
	sprpck -u -t2 -i064064 -S001064 -r064001 mandel.sps spr/mandel

spr/phobyx000000.spr: mandel.sps
	sprpck -u -t3 -i064064 -S001064 -r064001 phobyx.pcx spr/phobyx
