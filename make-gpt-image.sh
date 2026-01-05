#!/bin/sh

set -e

if [ ! -f "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 build-odroid-m2-rk3588s/u-boot-rockchip.bin u-boot.img"
	exit 1
fi

dd if=/dev/zero of="$2" bs=512 count=24576
parted $2 mklabel gpt
parted $2 --script mkpart primary 32KiB 12256KiB
parted $2 name 1 U-Boot
dd if="$1" of="$2" bs=512 seek=64 conv=notrunc
parted $2 print

echo "Created U-Boot SD-card image $2 with size 12MiB."
