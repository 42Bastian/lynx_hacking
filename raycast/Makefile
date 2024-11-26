DEMO=raycast


#ASFLAGS=-sh

$(DEMO).o: $(DEMO).asm world.inc sintab.inc deltatab.inc mandel.inc phobyx.inc\
	wall1.inc door.inc frame.inc smiley.inc smileyl.inc smileyr.inc\
	smileyb.inc monster.inc monsterb.inc scr_frame_left.spr

lnx: $(DEMO).lnx

mandel.inc: spr/mandel000000.spr
	touch $@
wall1.inc: spr/wall1000000.spr
	touch $@
phobyx.inc: spr/phobyx000000.spr
	touch $@
door.inc: spr/door000000.spr
	touch $@
frame.inc: spr/frame000000.spr
	touch $@
smiley.inc: spr/smiley000000.spr
	touch $@
smileyl.inc: spr/smiley_left000000.spr
	touch $@
smileyr.inc: spr/smiley_right000000.spr
	touch $@
smileyb.inc: spr/smiley_back000000.spr
	touch $@
monster.inc: spr/monster000000.spr
	touch $@
monsterb.inc: spr/monster_back000000.spr
	touch $@



%.o: %.asm
	@lyxass  $(ASFLAGS) $<

%.bin: %.asm
	@lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<

%.lnx: %.asm
	@lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<

include ../Rules.launch

clean:
	@rm -f *.lnx *.lyx *.bin *~ *.equ

real-clean:
	@rm -f *.o *.lnx

scr_frame_left.spr: scr_frame_left.pcx
	sprpck -c -t3 -s2 $<

spr/mandel000000.spr: mandel.sps
	sprpck -u -t2 -i032032 -S001032 -r032001 -a000016 $< spr/$(basename $<)

spr/phobyx000000.spr: phobyx.pcx
	sprpck -u -t3 -i032032 -S001032 -r032001 -a000016 $< spr/$(basename $<)

spr/wall1000000.spr: wall1.pcx
	sprpck -u -t3 -i032032 -S001032 -r032001 -a000016 $< spr/$(basename $<)

spr/door000000.spr: door.pcx
	sprpck -u -t3 -i032032 -S001032 -r032001 -a000016 $< spr/$(basename $<)

spr/frame000000.spr: frame.pcx
	sprpck -u -t3 -i032032 -S001032 -r032001 -a000016 $< spr/$(basename $<)

spr/smiley000000.spr: smiley.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)
spr/smiley_left000000.spr: smiley_left.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)
spr/smiley_right000000.spr: smiley_right.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)
spr/smiley_back000000.spr: smiley_back.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)

spr/monster000000.spr: monster.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)

spr/monster_back000000.spr: monster_back.pcx
	sprpck -u -t3 -i032032 -S001032 -o004000 -r024001 -a000016 $< spr/$(basename $<)
