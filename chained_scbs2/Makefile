DEMO=chained_scbs

chained_scbs.o: chained_scbs.asm sprites/sprites.inc
	lyxass -shex $<

sprites/sprites.inc:
	$(MAKE) -C sprites sprites

include ../Rules.launch
