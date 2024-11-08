;-*-asm-*-
wall10:  ibytes "spr/wall1000000.spr"
wall11:  ibytes "spr/wall1000001.spr"
wall12:  ibytes "spr/wall1000002.spr"
wall13:  ibytes "spr/wall1000003.spr"
wall14:  ibytes "spr/wall1000004.spr"
wall15:  ibytes "spr/wall1000005.spr"
wall16:  ibytes "spr/wall1000006.spr"
wall17:  ibytes "spr/wall1000007.spr"
wall18:  ibytes "spr/wall1000008.spr"
wall19:  ibytes "spr/wall1000009.spr"
wall110: ibytes "spr/wall1000010.spr"
wall111: ibytes "spr/wall1000011.spr"
wall112: ibytes "spr/wall1000012.spr"
wall113: ibytes "spr/wall1000013.spr"
wall114: ibytes "spr/wall1000014.spr"
wall115: ibytes "spr/wall1000015.spr"
wall116: ibytes "spr/wall1000016.spr"
wall117: ibytes "spr/wall1000017.spr"
wall118: ibytes "spr/wall1000018.spr"
wall119: ibytes "spr/wall1000019.spr"
wall120: ibytes "spr/wall1000020.spr"
wall121: ibytes "spr/wall1000021.spr"
wall122: ibytes "spr/wall1000022.spr"
wall123: ibytes "spr/wall1000023.spr"
wall124: ibytes "spr/wall1000024.spr"
wall125: ibytes "spr/wall1000025.spr"
wall126: ibytes "spr/wall1000026.spr"
wall127: ibytes "spr/wall1000027.spr"
wall128: ibytes "spr/wall1000028.spr"
wall129: ibytes "spr/wall1000029.spr"
wall130: ibytes "spr/wall1000030.spr"
wall131: ibytes "spr/wall1000031.spr"

ma	set wall10
wall1_lo:
	rept 32
	dc.b <ma
ma	set ma+SPR_SIZE
	endr

ma	set wall10
wall1_hi:
	rept 32
	dc.b >ma
ma	set ma+SPR_SIZE
	endr
