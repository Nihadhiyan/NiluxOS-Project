#!/bin/sh

# This script automates the build process for NiluxOS.

# --- Configuration ---
OS_NAME="niluxos"
IMAGE_DIR="disk_images"
FLOPPY_IMG="$IMAGE_DIR/$OS_NAME.flp"
ISO_IMG="$IMAGE_DIR/$OS_NAME.iso"
BOOTLOADER_SRC="Bootloaders/bootload.asm"
BOOTLOADER_BIN="Bootloaders/bootload.bin"
KERNEL_SRC="kernel.asm"
KERNEL_BIN="KERNEL.BIN"

# --- Setup Directories ---
mkdir -p "$IMAGE_DIR" Bootloaders

# --- Assemble Bootloader ---
echo ">>> Assembling bootloader ($BOOTLOADER_SRC)..."
nasm -f bin -o "$BOOTLOADER_BIN" "$BOOTLOADER_SRC" || { echo "Error: Bootloader assembly failed."; exit 1; }

# --- Assemble Kernel ---
echo ">>> Assembling kernel ($KERNEL_SRC)..."
nasm -f bin -o "$KERNEL_BIN" "$KERNEL_SRC" || { echo "Error: Kernel assembly failed."; exit 1; }

# --- Create Floppy Image ---
echo ">>> Creating floppy image ($FLOPPY_IMG)..."
rm -f "$FLOPPY_IMG"
mkdosfs -C "$FLOPPY_IMG" 1440 || { echo "Error: Floppy image creation failed."; exit 1; }

# --- Write Bootloader to Floppy ---
echo ">>> Writing bootloader to floppy image..."
dd status=noxfer conv=notrunc if="$BOOTLOADER_BIN" of="$FLOPPY_IMG" || { echo "Error: Writing bootloader to floppy failed."; exit 1; }

# --- Copy Kernel to Floppy ---
echo ">>> Copying kernel to floppy image ($KERNEL_BIN -> ::/)..."
mcopy -i "$FLOPPY_IMG" "$KERNEL_BIN" ::/ || { echo "Error: Copying kernel to floppy failed."; exit 1; }

# --- Create ISO Image ---
echo ">>> Creating CD-ROM ISO image ($ISO_IMG)..."
rm -f "$ISO_IMG"
mkisofs -quiet -V "$OS_NAME" -input-charset iso8859-1 -o "$ISO_IMG" -b "$(basename "$FLOPPY_IMG")" "$IMAGE_DIR/" || { echo "Error: ISO creation failed."; exit 1; }

echo '>>> Build process completed successfully!'