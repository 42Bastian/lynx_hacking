;-*-asm-*-
smiley:
//->smiley0:  ibytes "spr/smiley000000.spr"
//->smiley1:  ibytes "spr/smiley000001.spr"
//->smiley2:  ibytes "spr/smiley000002.spr"
//->smiley3:  ibytes "spr/smiley000003.spr"
smiley4:  ibytes "spr/smiley000004.spr"
smiley5:  ibytes "spr/smiley000005.spr"
smiley6:  ibytes "spr/smiley000006.spr"
smiley7:  ibytes "spr/smiley000007.spr"
smiley8:  ibytes "spr/smiley000008.spr"
smiley9:  ibytes "spr/smiley000009.spr"
smiley10: ibytes "spr/smiley000010.spr"
smiley11: ibytes "spr/smiley000011.spr"
smiley12: ibytes "spr/smiley000012.spr"
smiley13: ibytes "spr/smiley000013.spr"
smiley14: ibytes "spr/smiley000014.spr"
smiley15: ibytes "spr/smiley000015.spr"
smiley16: ibytes "spr/smiley000016.spr"
smiley17: ibytes "spr/smiley000017.spr"
smiley18: ibytes "spr/smiley000018.spr"
smiley19: ibytes "spr/smiley000019.spr"
smiley20: ibytes "spr/smiley000020.spr"
smiley21: ibytes "spr/smiley000021.spr"
smiley22: ibytes "spr/smiley000022.spr"
smiley23: ibytes "spr/smiley000023.spr"
smiley24: ibytes "spr/smiley000024.spr"
smiley25: ibytes "spr/smiley000025.spr"
smiley26: ibytes "spr/smiley000026.spr"
smiley27: ibytes "spr/smiley000027.spr"
//->smiley28: ibytes "spr/smiley000028.spr"
//->smiley29: ibytes "spr/smiley000029.spr"
//->smiley30: ibytes "spr/smiley000030.spr"
//->smiley31: ibytes "spr/smiley000031.spr"

ma	set smiley
smiley_lo:
	dc.b 0,0,0,0

	rept 24
	dc.b <ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0

ma	set smiley
smiley_hi:
	dc.b 0,0,0,0
	rept 24
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
	dc.b 0,0,0,0
