# Specify the program name
TARGET := program

# Specify src and build directories
SRC_DIR   := src
BUILD_DIR := build

# This is the Nix cross compiler
CROSS ?= riscv32-none-elf

# Alias Compiler / Assembler / Binutils
CC      := $(CROSS)-gcc
OBJCOPY := $(CROSS)-objcopy
OBJDUMP := $(CROSS)-objdump

# Set Compiler / Assembler / Linker flags
ARCH    := -march=rv32i -mabi=ilp32
ASFLAGS := $(ARCH) -mno-relax -mcmodel=medany
LDFLAGS := -nostdlib -nostartfiles -T $(SRC_DIR)/link.ld

# Rules for finding source files and naming their objects
SRCS := $(wildcard $(SRC_DIR)/*.s)
OBJS := $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(SRCS))

# Rules for naming the build artifacts
ELF  := $(BUILD_DIR)/$(TARGET).elf
DUMP := $(BUILD_DIR)/$(TARGET).dump
BIN  := $(BUILD_DIR)/$(TARGET).bin
MEM  := $(BUILD_DIR)/$(TARGET).mem

# all, clean, and dump are phony targets
.PHONY: all clean dump

# "make all" builds all the things
all: $(ELF) $(DUMP) $(BIN) $(HEX) $(MEM)

# "make clean" deletes the build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Rule to create the build directory
$(BUILD_DIR):
	mkdir -p $@

# Rule to build object files from source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	$(CC) $(ASFLAGS) -c -o $@ $<

# Rule for linking object files into an ELF
$(ELF): $(OBJS) $(SRC_DIR)/link.ld
	$(CC) $(ARCH) $(LDFLAGS) -o $@ $(OBJS)

# Rule for dumping the contents of ELF for inspection
$(DUMP): $(ELF)
	$(OBJDUMP) -D -S $< > $@

# Rule for copying the text and data sections from the ELF
$(BIN): $(ELF)
	$(OBJCOPY) -O binary --only-section=.text --only-section=.data $< $@

# Rule for converting the copied text and data sections to hex (for $readmemh)
$(MEM): $(BIN)
	hexdump -v -e '"%08x\n"' $< > $@

