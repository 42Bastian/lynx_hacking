#
# Lynx 256 byte Demo: gol249 (Game Of Life)
#

# Author: 42Bastian
# Release: Outline 2020
# Source (after Outline 2020 is over): https://github.com/42Bastian/lynx_hacking
# Free space: 7 byte(s) (Lynx bootsector is limited to 249bytes)
# Tested on Lynx I and Lynx II with Flash, SRAM and SainT SD Card.

gol249.o: BLL/Handy file with header and setup (see gol249.asm) which is
           normally done by the boot ROM.

gol249.lnx: Flashable image (or for Handy).
