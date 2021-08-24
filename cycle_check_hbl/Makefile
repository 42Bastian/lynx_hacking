cycle_check.o: cycle_check.asm my_irq.inc
	lyxass -shex $<

.PHONY: send
send: cycle_check.o
	sendobj -b 62500 -p com7 $<
