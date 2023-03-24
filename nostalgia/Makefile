DEMO=nostalgia

$(DEMO).o: $(DEMO).asm

$(DEMO).bin $(DEMO).o: poly8.inc

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
	cat SCENE_v1.dat >>$*.lyx
	bzcat allff.lyx.bz2 >> $*.lyx
	make_lnx $*.lyx -b0 512K -o $@
	rm -f $*.lyx
	chmod 644 $@

test.lnx:
	cat $(BLL_ROOT)/uBLL/bll_1st_stage_enc.bin  $(BLL_ROOT)/uBLL/bll_2nd_stage.bin >$*.lyx
	bzcat allff.lyx.bz2 >> $*.lyx
	truncate -s 6K  $*.lyx
	cat SCENE_v1.dat >>$*.lyx
	bzcat allff.lyx.bz2 >> $*.lyx
	make_lnx $*.lyx -b0 512K -o $@
	rm -f $*.lyx
	chmod 644 $@

include Rules.launch

clean:
	rm -f *.lyx *.o *.bin
