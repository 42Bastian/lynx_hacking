_256=rotz

$(_256).o: $(_256).asm

%.o: %.asm
	lyxass -v $<

%.bin: %.asm
	lyxass -d -D LNX=1 -o  $@ $<

.PHONY: send
send: $(_256).o
	sendobj -b 62500 -p com7 $<

.PHONY: lnx
.ONESHELL:
lnx: $(_256).bin
	lynxenc $< $(_256).lyx
	bzcat allff.lyx.bz2 >> $(_256).lyx
	make_lnx $(_256).lyx -b0 256K -o $(_256).lnx
	@echo

.PHONY: clean
clean:
	rm -f *.lyx *~

.PHONY: erase
erase:
	flash_up.exe -p com7 -e

.PHONY: flash
flash: lnx
	flash_up.exe -p com7 -f $(_256).lnx

.PHONY: sram
sram: lnx
	sram_up.exe -p com7 -w $(_256).lnx
