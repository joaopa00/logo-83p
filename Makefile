CC = gcc
CFLAGS = -g -O -W -Wall
TIPACK = tipack
TPASM = tpasm
TPASMFLAGS = -I $(HOME)/programs/include/tpasm
RABBITSIGN = rabbitsign
OBJCOPY = objcopy
STACKER = ../stacker.pl -c

primitive_files = p-cntrl.asm p-comm.asm p-data.asm p-logic.asm p-math.asm p-worksp.asm
logocore_files = logocore.asm assert.asm data.asm error.asm eval.asm files.asm float.asm gc.asm list.asm mem.asm nodes.asm objects.asm parse.asm proc.asm stack.asm text.asm types.asm word.asm $(primitive_files)

all: logo.8xk logoconv build-examples

logo.8xk: logo.hex
	$(RABBITSIGN) -gu logo.hex -o logo.8xk

logo.hex: logo.asm $(logocore_files) logolib.bin
	$(TPASM) $(TPASMFLAGS) $*.asm -o intel $*.hex -l $*.lst
	-$(STACKER) $*.asm

#%.8xp: %.bin
#	$(TIPACK) $< -p -o $@

#testparse.8xp: testparse.bin
#	$(TIPACK) testparse.bin -p -o testparse.8xp -n TESTPARS

#%.bin: %.asm $(logocore_files)
#	$(TPASM) $(TPASMFLAGS) $*.asm -o intel $*.hex -l $*.lst
#	-$(STACKER) $*.asm
#	$(OBJCOPY) -I ihex $*.hex -O binary $*.bin

data.asm: data.asm.in xprim $(primitive_files)
	./xprim $(primitive_files)

logolib.bin: logolib.lgo buildlib
	./buildlib logolib.lgo logolib.bin

xprim: xprim.c
	$(CC) $(CFLAGS) xprim.c -o xprim

buildlib: buildlib.c
	$(CC) $(CFLAGS) xprim.c -o xprim

logoconv: logoconv.c
	$(CC) $(CFLAGS) logoconv.c -o logoconv

clean:
	rm -f *.bin *.hex *.lst *.8xp
	rm -f xprim

extraclean: clean
	rm -f data.asm

build-examples:
	$(MAKE) -C examples

.PHONY: all clean extraclean build-examples
