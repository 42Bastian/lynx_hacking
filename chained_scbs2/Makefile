chained_scbs.o: chained_scbs.asm
	lyxass -shex $<

.PHONY: send
send: chained_scbs.o
	sendobj -b 62500 -p com7 $<

.PHONY: sprites
.ONESHELL:
sprites:
	@cd sprites
	sprpck.exe -S016010 -r010010 ../phobyx.pcx
	rm -f sprites.inc
	echo "sprite_addr_lo:" > spriteaddrlo.inc
	echo "sprite_addr_hi:" > spriteaddrhi.inc
	for y in {0..9}; do
	  for x in {0..9}; do
	    echo "spr$$x$$y: ibytes \"phobyx00$${x}00$${y}.spr\"" >> sprites.inc
	    echo " .dc.b <spr$$x$$y" >> spriteaddrlo.inc
	    echo " .dc.b >spr$$x$$y" >> spriteaddrhi.inc
	  done
	done
