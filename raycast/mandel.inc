;-*-asm-*-
mandel0:  ibytes "spr/mandel000000.spr"
mandel1:  ibytes "spr/mandel000001.spr"
mandel2:  ibytes "spr/mandel000002.spr"
mandel3:  ibytes "spr/mandel000003.spr"
mandel4:  ibytes "spr/mandel000004.spr"
mandel5:  ibytes "spr/mandel000005.spr"
mandel6:  ibytes "spr/mandel000006.spr"
mandel7:  ibytes "spr/mandel000007.spr"
mandel8:  ibytes "spr/mandel000008.spr"
mandel9:  ibytes "spr/mandel000009.spr"
mandel10: ibytes "spr/mandel000010.spr"
mandel11: ibytes "spr/mandel000011.spr"
mandel12: ibytes "spr/mandel000012.spr"
mandel13: ibytes "spr/mandel000013.spr"
mandel14: ibytes "spr/mandel000014.spr"
mandel15: ibytes "spr/mandel000015.spr"
mandel16: ibytes "spr/mandel000016.spr"
mandel17: ibytes "spr/mandel000017.spr"
mandel18: ibytes "spr/mandel000018.spr"
mandel19: ibytes "spr/mandel000019.spr"
mandel20: ibytes "spr/mandel000020.spr"
mandel21: ibytes "spr/mandel000021.spr"
mandel22: ibytes "spr/mandel000022.spr"
mandel23: ibytes "spr/mandel000023.spr"
mandel24: ibytes "spr/mandel000024.spr"
mandel25: ibytes "spr/mandel000025.spr"
mandel26: ibytes "spr/mandel000026.spr"
mandel27: ibytes "spr/mandel000027.spr"
mandel28: ibytes "spr/mandel000028.spr"
mandel29: ibytes "spr/mandel000029.spr"
mandel30: ibytes "spr/mandel000030.spr"
mandel31: ibytes "spr/mandel000031.spr"

ma	set mandel0
mandel_lo:
	rept 32
	dc.b <ma
ma	set ma+SPR_SIZE
	endr

ma	set mandel0
mandel_hi:
	rept 32
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
