chained_scbs.o: chained_scbs.asm
	lyxass -shex $<

.PHONY: send
send: chained_scbs.o
	sendobj -b 62500 -p com7 $<
