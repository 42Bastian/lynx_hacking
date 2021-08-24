#
# Lynx 256 byte Demo:
*   rotz! - ROToZoomer (with sound)!
#

# Author: 42Bastian
# Release: SOMMARHACK 2020
# Source (after compo is over): https://github.com/42Bastian/lynx_hacking
# Free space: 7 byte(s) (Lynx bootsector is limited to 249bytes)
# Tested on Lynx II with Flash and SRAM card.

rotz.bin: Raw binary, no headers

rotz.o: BLL/Handy file with header and setup (see rotz.asm) which is
           normally done by the boot ROM.

rotz.lnx: Flashable image (or for Handy).
