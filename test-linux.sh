#!/bin/sh

# This script automates testing NiluxOS in QEMU.

# --- Configuration ---
OS_NAME="niluxos"
IMAGE_DIR="disk_images"
FLOPPY_IMG="$IMAGE_DIR/$OS_NAME.flp"

echo ">>> Launching QEMU with $FLOPPY_IMG..."
# Launch QEMU, booting from the created floppy image
qemu-system-i386 -drive format=raw,file=$FLOPPY_IMG,index=0,if=floppy