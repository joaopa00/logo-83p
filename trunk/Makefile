CC = gcc
CFLAGS = -g -O -W -Wall
TIPACK = tipack
TPASM = tpasm
TPASMFLAGS = -I $(HOME)/programs/include/tpasm
OBJCOPY = objcopy
STACKER = ../stacker.pl -c

primitive_files = p-cntrl.asm p-data.asm p-logic.asm p-math.asm p-worksp.asm
logocore_files = assert.asm data.asm eval.asm float.asm gc.asm list.asm mem.asm nodes.asm objects.asm parse.asm proc.asm stack.asm types.asm word.asm $(primitive_files)

all: testmem.8xp testparse.8xp testeval.8xp

%.8xp: %.bin
	$(TIPACK) $< -p -o $@

testparse.8xp: testparse.bin
	$(TIPACK) testparse.bin -p -o testparse.8xp -n TESTPARS

%.bin: %.asm $(logocore_files)
	$(TPASM) $(TPASMFLAGS) $*.asm -o intel $*.hex -l $*.lst
	-$(STACKER) $*.asm
	$(OBJCOPY) -I ihex $*.hex -O binary $*.bin

data.asm: data.asm.in xprim $(primitive_files)
	./xprim $(primitive_files)

xprim: xprim.c
	$(CC) $(CFLAGS) xprim.c -o xprim

clean:
	rm -f *.bin *.hex *.lst *.8xp
	rm -f xprim

extraclean: clean
	rm -f data.asm
