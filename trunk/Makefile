TIPACK = tipack
TPASM = tpasm
TPASMFLAGS = -I $(HOME)/include/tpasm
OBJCOPY = objcopy

all: testmem.8xp

testmem.8xp: testmem.bin
	$(TIPACK) testmem.bin -p -o testmem.8xp

testmem.bin: testmem.asm
	$(TPASM) $(TPASMFLAGS) testmem.asm -o intel testmem.hex -l testmem.lst
	$(OBJCOPY) -I ihex testmem.hex -O binary testmem.bin

clean:
	rm -f testmem.bin testmem.hex testmem.lst testmem.8xp