
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
phobyx32: ibytes "spr/phobyx000032.spr"
phobyx33: ibytes "spr/phobyx000033.spr"
phobyx34: ibytes "spr/phobyx000034.spr"
phobyx35: ibytes "spr/phobyx000035.spr"
phobyx36: ibytes "spr/phobyx000036.spr"
phobyx37: ibytes "spr/phobyx000037.spr"
phobyx38: ibytes "spr/phobyx000038.spr"
phobyx39: ibytes "spr/phobyx000039.spr"
phobyx40: ibytes "spr/phobyx000040.spr"
phobyx41: ibytes "spr/phobyx000041.spr"
phobyx42: ibytes "spr/phobyx000042.spr"
phobyx43: ibytes "spr/phobyx000043.spr"
phobyx44: ibytes "spr/phobyx000044.spr"
phobyx45: ibytes "spr/phobyx000045.spr"
phobyx46: ibytes "spr/phobyx000046.spr"
phobyx47: ibytes "spr/phobyx000047.spr"
phobyx48: ibytes "spr/phobyx000048.spr"
phobyx49: ibytes "spr/phobyx000049.spr"
phobyx50: ibytes "spr/phobyx000050.spr"
phobyx51: ibytes "spr/phobyx000051.spr"
phobyx52: ibytes "spr/phobyx000052.spr"
phobyx53: ibytes "spr/phobyx000053.spr"
phobyx54: ibytes "spr/phobyx000054.spr"
phobyx55: ibytes "spr/phobyx000055.spr"
phobyx56: ibytes "spr/phobyx000056.spr"
phobyx57: ibytes "spr/phobyx000057.spr"
phobyx58: ibytes "spr/phobyx000058.spr"
phobyx59: ibytes "spr/phobyx000059.spr"
phobyx60: ibytes "spr/phobyx000060.spr"
phobyx61: ibytes "spr/phobyx000061.spr"
phobyx62: ibytes "spr/phobyx000062.spr"
phobyx63: ibytes "spr/phobyx000063.spr"

ma	set phobyx0
phobyx_lo:
	rept 64
	dc.b <ma
ma	set ma+129
	endr

ma	set phobyx0
phobyx_hi:
	rept 64
	dc.b >ma
ma	set ma+129
	endr
