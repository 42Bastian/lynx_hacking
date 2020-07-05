#
# Lynx 256 byte Demo:
*   tuef - TUnnelEFect
#

# Author: 42Bastian
# Release: SOMMARHACK 2020
# Source (after compo is over): https://github.com/42Bastian/lynx_hacking
# Free space: 2+7 byte(s) (Lynx bootsector is limited to 249bytes)
# Tested on Lynx II with Flash and SRAM card.

tuef.bin: Raw binary, no headers

tuef.o: BLL/Handy file with header and setup (see tuef.asm) which is
           normally done by the boot ROM.

tuef.lnx: Flashable image (or for Handy).

tuef.pde: Processing source
