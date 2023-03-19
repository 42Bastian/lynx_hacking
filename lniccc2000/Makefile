DEMO=lniccc2000

$(DEMO).o: $(DEMO).asm

$(DEMO).bin $(DEMO).o: poly8.inc unlz4_fast.inc abcmusic.inc

%.o: %.asm
	lyxass -v $(ASFLAGS) $<

%.bin: %.asm
	lyxass -d $(ASFLAGS) -D LNX=1 -o  $@ $<

.PHONY: lnx
lnx: $(DEMO).lnx

EXT=.lz4
$(DEMO).lnx: $(DEMO).bin
	@cat ml512.enc $< >$*.lyx
	bzcat allff.lyx.bz2 >> $*.lyx
	truncate -s 8K  $*.lyx
	cat scene.bin$(EXT) >>$*.lyx
	bzcat allff.lyx.bz2 >> $*.lyx
	make_lnx $*.lyx -b0 512K -o $@
	rm -f $*.lyx
	chmod 644 $@

include Rules.launch

clean:
	rm -f  *.lyx *.o *.bin
