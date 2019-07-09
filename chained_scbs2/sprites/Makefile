.PHONY: sprites
.ONESHELL:
sprites:
	@sprpck.exe -S016010 -r010010 phobyx.pcx
	rm -f sprites.inc
	echo "sprite_addr_lo:" > spriteaddrlo.inc
	echo "sprite_addr_hi:" > spriteaddrhi.inc
	for y in {0..9}; do
	  for x in {0..9}; do
	    echo "spr$$x$$y: ibytes \"sprites/phobyx00$${y}00$${x}.spr\"" >> sprites.inc
	    echo " .dc.b <spr$$x$$y" >> spriteaddrlo.inc
	    echo " .dc.b >spr$$x$$y" >> spriteaddrhi.inc
	  done
	done
