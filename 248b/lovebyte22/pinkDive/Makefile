DEMO=pinkDive
BAUD?=1000000

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

.PHONY: send
send: $(DEMO).o
	sendobj -b $(BAUD) -p com7 $<

lnx: $(DEMO).lnx

%.lnx: %.asm
	lyxass -d -D LNX=1 -o $(DEMO).bin $<
	lynxenc $(DEMO).bin $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~

.PHONY: erase
erase:
	flash_up.exe -b $(BAUD) -p com7 -e

.PHONY: flash
flash: lnx
	flash_up.exe -b $(BAUD) -p com7 -f $(DEMO).lnx

.PHONY: sram
sram: lnx
	sram_up.exe -b $(BAUD) -p com7 -w $(DEMO).lnx
