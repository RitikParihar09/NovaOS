# Makefile for Nova OS

# Assembler settings
ASM = nasm
ASMFLAGS = -f bin

# QEMU settings
QEMU = qemu-system-i386
QEMUFLAGS = -drive format=raw,file=nova_os.img

# Source files
BOOTLOADER_SRC = bootloader.asm
KERNEL_SRC = kernel.asm

# Output files
BOOTLOADER_BIN = bootloader.bin
KERNEL_BIN = kernel.bin
OS_IMAGE = nova_os.img

# Default target
all: $(OS_IMAGE)

# Build the bootloader
$(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

# Build the kernel
$(KERNEL_BIN): $(KERNEL_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

# Create the OS image
$(OS_IMAGE): $(BOOTLOADER_BIN) $(KERNEL_BIN)
	# Create a blank disk image (1.44MB floppy)
	dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	# Write the bootloader to the first sector
	dd if=$(BOOTLOADER_BIN) of=$(OS_IMAGE) conv=notrunc
	# Write the kernel to the second sector
	dd if=$(KERNEL_BIN) of=$(OS_IMAGE) bs=512 seek=1 conv=notrunc

# Run the OS in QEMU
run: $(OS_IMAGE)
	$(QEMU) $(QEMUFLAGS)

# Display OS content in terminal without running QEMU
terminal: $(OS_IMAGE)
	@echo "Nova OS Content:"
	@echo "----------------"
	@hexdump -C $(OS_IMAGE) | head -20
	@echo "..."
	@echo "Boot sector signature check:"
	@hexdump -C -s 510 -n 2 $(OS_IMAGE)
	@echo "----------------"
	@echo "Kernel content (first 20 lines):"
	@hexdump -C -s 512 -n 512 $(OS_IMAGE) | head -20
	@echo "..."
	@echo "To run the full OS, use 'make run'"

# Clean up
clean:
	rm -f $(BOOTLOADER_BIN) $(KERNEL_BIN) $(OS_IMAGE)

.PHONY: all run terminal clean