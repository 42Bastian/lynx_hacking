;-*-asm-*-
phobyx0:  ibytes "spr/phobyx000000.spr"
phobyx1:  ibytes "spr/phobyx000001.spr"
phobyx2:  ibytes "spr/phobyx000002.spr"
phobyx3:  ibytes "spr/phobyx000003.spr"
phobyx4:  ibytes "spr/phobyx000004.spr"
phobyx5:  ibytes "spr/phobyx000005.spr"
phobyx6:  ibytes "spr/phobyx000006.spr"
phobyx7:  ibytes "spr/phobyx000007.spr"
phobyx8:  ibytes "spr/phobyx000008.spr"
phobyx9:  ibytes "spr/phobyx000009.spr"
phobyx10: ibytes "spr/phobyx000010.spr"
phobyx11: ibytes "spr/phobyx000011.spr"
phobyx12: ibytes "spr/phobyx000012.spr"
phobyx13: ibytes "spr/phobyx000013.spr"
phobyx14: ibytes "spr/phobyx000014.spr"
phobyx15: ibytes "spr/phobyx000015.spr"
phobyx16: ibytes "spr/phobyx000016.spr"
phobyx17: ibytes "spr/phobyx000017.spr"
phobyx18: ibytes "spr/phobyx000018.spr"
phobyx19: ibytes "spr/phobyx000019.spr"
phobyx20: ibytes "spr/phobyx000020.spr"
phobyx21: ibytes "spr/phobyx000021.spr"
phobyx22: ibytes "spr/phobyx000022.spr"
phobyx23: ibytes "spr/phobyx000023.spr"
phobyx24: ibytes "spr/phobyx000024.spr"
phobyx25: ibytes "spr/phobyx000025.spr"
phobyx26: ibytes "spr/phobyx000026.spr"
phobyx27: ibytes "spr/phobyx000027.spr"
phobyx28: ibytes "spr/phobyx000028.spr"
phobyx29: ibytes "spr/phobyx000029.spr"
phobyx30: ibytes "spr/phobyx000030.spr"
phobyx31: ibytes "spr/phobyx000031.spr"

ma	set phobyx0
phobyx_lo:
	rept 32
	dc.b <ma
ma	set ma+SPR_SIZE
	endr

ma	set phobyx0
phobyx_hi:
	rept 32
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
