plasma.o: plasma.asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

.PHONY: send
send: plasma.o
	sendobj -b 62500 -p com7 $<

.PHONY: lnx
lnx: plasma.bin
	lynxenc $< plasma.lyx
	make_lnx plasma.lyx -b0 256K -o plasma.lnx

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin
