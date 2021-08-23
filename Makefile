CA65_BINARY=ca65
LD65_BINARY=ld65
MINIPRO_BINARY=minipro

FIRMWARE_CFG=beneater.cfg

CA65_FLAGS=--cpu 65C02
LD65_FLAGS=-C $(FIRMWARE_CFG)
MINIPRO_FLAGS=-p AT28C256

TARGET=dual-hello-cc65

default: $(TARGET).bin

%.bin: %.o
	$(LD65_BINARY) $(LD65_FLAGS) -o $@ $<
%.o: %.s
	$(CA65_BINARY) $(CA65_FLAGS) -o $@ $<

clean:
	/bin/rm -f *.o *.bin

burn:
	$(MINIPRO_BINARY) $(MINIPRO_FLAGS) -w $(TARGET).bin
