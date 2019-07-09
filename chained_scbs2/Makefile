chained_scbs.o: chained_scbs.asm sprites/*.inc
	lyxass -shex $<

.PHONY: send
send: chained_scbs.o
	sendobj -b 62500 -p com7 $<

.PHONY: sprites
sprites:
	$(MAKE) -C sprites sprites
