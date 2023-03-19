LZ4=1
EXO=0

XX=$(wildcard tmp/xx*.asm)
XXB=$(XX:.asm=.bin)

all: x.asm bin

.PHONY: bin

$(XXB): x.asm

.ONESHELL:
bin: $(XXB)
ifeq ($(LZ4),1)
	@t=0
	for i in tmp/xx*.bin.lz4; do
	   s=$$(stat -c "%s" $$i)
	   t=$$((t+s))
	done;
	echo "lz4: $$t free $$((512*1024-t))"
endif
#	@t=0
#	for i in xx*.bin.upk; do
#	   s=$$(stat -c "%s" $$i)
#	   t=$$((t+s))
#	done;
#	echo "upkr: $$t $$((512*1024-t))"
#	t=0
#	for i in tmp/xx*.pck; do
#	   s=$$(stat -c "%s" $$i)
#	   t=$$((t+s))
#	done;
#	echo "tp $$t $$((512*1024-t))"
ifeq ($(EXO),1)
	t=0
	for i in tmp/xx*.exo; do
	   s=$$(stat -c "%s" $$i)
	   t=$$((t+s))
	done;
	echo "exo $$t $$((512*1024-t))"
endif

tmp/%.asm: x.asm

tmp/%.bin: tmp/%.asm
ifeq ($(LZ4),1)
	@if [ ! -e scene.bin.lz4 ]; then
	  touch scene.bin.lz4
	fi
endif
ifeq ($(EXO),1)
	@if [ ! -e scene.bin.exo ]; then
	  touch scene.bin.exo
	fi
endif
	@lyxass -d -tl -x 0x1000 -o $@ $<

#	s=$$(stat -c "%s" $@)
#	sl=$$((s & 0xff))
#	sh=$$((s >> 8))
#	sl=$$((sl ^ 255))
#	sh=$$((sh ^ 255))
#	printf "%02x" $$sl | xxd -p -r -s 0 >$@.a
#	printf "%02x" $$sh | xxd -p -r -s 0 >>$@.a
#	cat $@ >> $@.a
#	mv $@.a $@

ifeq ($(LZ4),1)
	lz4 -12 -f --no-frame-crc -l $@
	dd bs=1 skip=8 if=$@.lz4 of=$@.lz4.a
	s=$$(stat -c "%s" $@.lz4.a)
	sl=$$((s & 0xff))
	sh=$$((s >> 8))
	sl=$$((sl ^ 255))
	sh=$$((sh ^ 255))
	printf "%02x" $$sl | xxd -p -r >$@.lz4
	printf "%02x" $$sh | xxd -p -r >>$@.lz4
	cat $@.lz4.a >> $@.lz4
	rm -f $@.lz4.a
	cat $@.lz4 >> scene.bin.lz4
endif
ifeq ($(EXO),1)
	exomizer.exe raw -B -P-32 $@ -o $@.exo
	cat $@.exo >> scene.bin.exo
endif
#	tp +l $@ -o $@.pck
#	dd bs=1 skip=8 if=$@.pck of=$@.pck.a
#	s=$$(stat -c "%s" $@.pck.a)
#	sl=$$((s & 0xff))
#	sh=$$((s >> 8))
#	sl=$$((sl ^ 255))
#	sh=$$((sh ^ 255))
#	printf "%02x" $$sl | xxd -p -r >$@.pck
#	printf "%02x" $$sh | xxd -p -r >>$@.pck
#	cat $@.pck.a >> $@.pck
#	rm  $@.pck.a

.ONESHELL:
x.asm: scene2lynx
	scene2lynx > x.asm
	rm -f sence/xx*.asm
	csplit -s -z -f tmp/xx -b "%02d.asm" x.asm "/--- split/" '{*}'
	# last frame gets 0xff pre-last 0xfc as end marker
	a=(tmp/*.asm)
	b=$$(($${#a[@]}-2))
	sed -i "/end of file/s/fe/fc/" $${a[$$b]}

clean:
	rm -f x.asm
	rm -f xx*
	rm -f tmp/*.asm
	rm -f tmp/*.bin*
