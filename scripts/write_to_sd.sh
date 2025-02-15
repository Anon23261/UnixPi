#!/bin/bash
# UnixPi SD Card Writer Script
# Writes the UnixPi image to an SD card

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /dev/sdX (where X is your SD card device letter)"
    exit 1
fi

SD_DEVICE=$1

# Verify device
echo "WARNING: This will erase all data on $SD_DEVICE"
echo "Please verify this is your SD card device!"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Write image
echo "Writing UnixPi image to $SD_DEVICE..."
dd if=unixpi-security.img of=$SD_DEVICE bs=4M status=progress conv=fsync

# Sync and wait
sync
echo "Image written successfully!"
echo "You can now boot your Raspberry Pi Zero W with this SD card."
