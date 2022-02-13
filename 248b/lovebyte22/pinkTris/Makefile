DEMO=pinktris
COM?=com7
BAUD?=1000000
HANDY?=0

$(DEMO).o: $(DEMO).asm

%.o: %.asm
	lyxass -v -D HANDY=$(HANDY) $<

bin: $(DEMO).bin micro_loader.bin

%.bin: %.asm
	lyxass -d -D LNX=1 -D HANDY=$(HANDY) -o $*.bin $*.asm

.PHONY: send
send: $(DEMO).o
	sendobj -b $(BAUD) -p $(COM) $<

lnx: $(DEMO).lnx

%.lnx: micro_loader.bin $(DEMO).bin
	lynxenc micro_loader.bin $(DEMO).lyx
	cat $(DEMO).bin >> $(DEMO).lyx
	bzcat allff.lyx.bz2 >> $(DEMO).lyx
	make_lnx $(DEMO).lyx -b0 256K -o $(DEMO).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~  *.enc *.equ

.PHONY: erase
erase:
	flash_up.exe  -b $(BAUD) -p $(COM) -e

.PHONY: flash
flash: lnx
	flash_up.exe -b $(BAUD) -p $(COM) -f $(DEMO).lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p $(COM) -b $(BAUD) -w $(DEMO).lnx
