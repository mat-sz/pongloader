.DEFAULT_GOAL := all

clean:
	-rm -rf out

all: clean
	mkdir out
	as -o out/pong.o pong.S
	ld -Ttext 0x7C00 -o out/pong.elf out/pong.o
	objcopy -O binary out/pong.elf out/pong.bin