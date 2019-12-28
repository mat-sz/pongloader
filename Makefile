.DEFAULT_GOAL := all

clean:
	-rm -f *.o
	-rm -f *.bin

all: clean
	as -o pong.o pong.S
	ld -o pong.bin --oformat binary -e init pong.o