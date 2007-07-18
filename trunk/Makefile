TIPACK = tipack
TPASM = tpasm
TPASMFLAGS = -I $(HOME)/programs/include/tpasm
OBJCOPY = objcopy
STACKER = ../stacker.pl -c

all: testmem.8xp testparse.8xp testeval.8xp

%.8xp: %.bin
	$(TIPACK) $< -p -o $@

testparse.8xp: testparse.bin
	$(TIPACK) testparse.bin -p -o testparse.8xp -n TESTPARS

%.bin: %.asm *.asm
	$(TPASM) $(TPASMFLAGS) $*.asm -o intel $*.hex -l $*.lst
	-$(STACKER) $*.asm
	$(OBJCOPY) -I ihex $*.hex -O binary $*.bin

clean:
	rm -f *.bin *.hex *.lst *.8xp
