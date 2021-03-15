# TAON - The Art Of Noise

Compo: Low-end 256 byte
Platform: Atari Lynx (Emulator will do but may not sound correctly)
Size: 249
Author/Group: 42Bastian
Release: L<3vebyte Party 2021 #34/35

## Files

taon.lnx - Ready for handy or mednafen or to be flashed
taon.asm - source
song.lb  - LynxBeat song

## LynxBeat/ByteBeat interpreter.

ByteBeat code:
// Lynxbeat uses 16bit t
q = t & 0xffff,
(((q>>8) & 0x8))*(q & 7)
|
((((q >> 13) ^ (q >> 5))) & 97)
|
(((q>>13) & 0x5))*(q & 8)
