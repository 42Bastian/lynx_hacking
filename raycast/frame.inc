;-*-asm-*-
frame0:  ibytes "spr/frame000000.spr"
frame1:  ibytes "spr/frame000001.spr"
frame2:  ibytes "spr/frame000002.spr"
frame3:  ibytes "spr/frame000003.spr"
frame4:  ibytes "spr/frame000004.spr"
frame5:  ibytes "spr/frame000005.spr"
frame6:  ibytes "spr/frame000006.spr"
frame7:  ibytes "spr/frame000007.spr"
frame8:  ibytes "spr/frame000008.spr"
frame9:  ibytes "spr/frame000009.spr"
frame10: ibytes "spr/frame000010.spr"
frame11: ibytes "spr/frame000011.spr"
frame12: ibytes "spr/frame000012.spr"
frame13: ibytes "spr/frame000013.spr"
frame14: ibytes "spr/frame000014.spr"
frame15: ibytes "spr/frame000015.spr"
frame16: ibytes "spr/frame000016.spr"
frame17: ibytes "spr/frame000017.spr"
frame18: ibytes "spr/frame000018.spr"
frame19: ibytes "spr/frame000019.spr"
frame20: ibytes "spr/frame000020.spr"
frame21: ibytes "spr/frame000021.spr"
frame22: ibytes "spr/frame000022.spr"
frame23: ibytes "spr/frame000023.spr"
frame24: ibytes "spr/frame000024.spr"
frame25: ibytes "spr/frame000025.spr"
frame26: ibytes "spr/frame000026.spr"
frame27: ibytes "spr/frame000027.spr"
frame28: ibytes "spr/frame000028.spr"
frame29: ibytes "spr/frame000029.spr"
frame30: ibytes "spr/frame000030.spr"
frame31: ibytes "spr/frame000031.spr"

ma	set frame0
frame_lo:
	rept 32
	dc.b <ma
ma	set ma+SPR_SIZE
	endr

ma	set frame0
frame_hi:
	rept 32
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
