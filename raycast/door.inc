;-*-asm-*-
door0:  ibytes "spr/door000000.spr"
door1:  ibytes "spr/door000001.spr"
door2:  ibytes "spr/door000002.spr"
door3:  ibytes "spr/door000003.spr"
door4:  ibytes "spr/door000004.spr"
door5:  ibytes "spr/door000005.spr"
door6:  ibytes "spr/door000006.spr"
door7:  ibytes "spr/door000007.spr"
door8:  ibytes "spr/door000008.spr"
door9:  ibytes "spr/door000009.spr"
door10: ibytes "spr/door000010.spr"
door11: ibytes "spr/door000011.spr"
door12: ibytes "spr/door000012.spr"
door13: ibytes "spr/door000013.spr"
door14: ibytes "spr/door000014.spr"
door15: ibytes "spr/door000015.spr"
door16: ibytes "spr/door000016.spr"
door17: ibytes "spr/door000017.spr"
door18: ibytes "spr/door000018.spr"
door19: ibytes "spr/door000019.spr"
door20: ibytes "spr/door000020.spr"
door21: ibytes "spr/door000021.spr"
door22: ibytes "spr/door000022.spr"
door23: ibytes "spr/door000023.spr"
door24: ibytes "spr/door000024.spr"
door25: ibytes "spr/door000025.spr"
door26: ibytes "spr/door000026.spr"
door27: ibytes "spr/door000027.spr"
door28: ibytes "spr/door000028.spr"
door29: ibytes "spr/door000029.spr"
door30: ibytes "spr/door000030.spr"
door31: ibytes "spr/door000031.spr"

ma	set door0
door_lo:
	rept 32
	dc.b <ma
ma	set ma+SPR_SIZE
	endr

ma	set door0
door_hi:
	rept 32
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
