DEMO=warp4.2

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

.PHONY: send
send: $(DEMO).o
	sendobj -b 62500 -p com7 $<

lnx: $(DEMO).lnx

%.lnx: %.asm
	lyxass -d -D LNX=1 -o $(DEMO).bin $<
	lynxenc $(DEMO).bin $(DEMO).lyx_
	bzcat allff.lyx.bz2 >> $(DEMO).lyx_
	dd if=$(DEMO).lyx_ of=$(DEMO).lyx bs=1024 count=256
	rm -f $(DEMO).lyx_
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~ *.bin

.PHONY: erase
erase:
	flash_up.exe -p com7 -e

.PHONY: flash
flash: lnx
	flash_up.exe -p com7 -f $(DEMO).lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p com7 -w $(DEMO).lnx
