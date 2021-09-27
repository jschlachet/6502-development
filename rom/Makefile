# to build: make
# to burn a specific rom: make ROM=romfilename
#

CA65_BINARY=ca65
LD65_BINARY=ld65
MINIPRO_BINARY=minipro

FIRMWARE_CFG=../beneater.cfg

CA65_FLAGS=--cpu 65C02
LD65_FLAGS=-C $(FIRMWARE_CFG)
MINIPRO_FLAGS=-p AT28C256

SOURCE_DIR=../src
BUILD_DIR=../build
INCLUDE_DIR=../include
ROM_DIR=.

all: 6522-timers dualvia-serial dual-hello-4bit

$(ROM_DIR)/%: $(BUILD_DIR)/%.o
	$(LD65_BINARY) $(LD65_FLAGS) -o $(ROM_DIR)/$@ $<
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.s
	$(CA65_BINARY) $(CA65_FLAGS) -o $(BUILD_DIR)/$@ $<
clean:
	/bin/rm -f $(BUILD_DIR)/*.o && \
  /usr/bin/find $(ROM_DIR) -type f ! -name Makefile ! -name README.md -delete \\
	/usr/bin/find $(BUILD_DIR) -type f ! -name Makefile ! -name README.md -delete


burn:
	$(MINIPRO_BINARY) $(MINIPRO_FLAGS) -w $(ROM_DIR)/$(ROM)
