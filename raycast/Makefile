DEMO=demo

ASFLAGS=-sh

$(DEMO).o: $(DEMO).asm world.inc sintab.inc deltatab.inc mandel.inc phobyx.inc\
	wall1.inc door.inc

mandel.inc: spr/mandel000000.spr
	touch $@
wall1.inc: spr/wall1000000.spr
	touch $@
phobyx.inc: spr/phobyx000000.spr
	touch $@
door.inc: spr/door000000.spr
	touch $@


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

spr/phobyx000000.spr: phobyx.pcx
	sprpck -u -t3 -i064064 -S001064 -r064001 phobyx.pcx spr/phobyx

spr/wall1000000.spr: wall1.pcx
	sprpck -u -t3 -i064064 -S001064 -r064001 wall1.pcx spr/wall1

spr/door000000.spr: door.pcx
	sprpck -u -t3 -i064064 -S001064 -r064001 door.pcx spr/door
