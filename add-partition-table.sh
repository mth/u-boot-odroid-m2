#!/bin/sh

set -e

if [ ! -f "$1" ] || [ -n "$2" ]; then
	echo "$0 build-odroid-m2-rk3588s/u-boot-rockchip.bin u-boot.img"
	exit 1
fi

fallocate -l 16MiB $IMAGE_FILE
# Size is 16384K - 32K (64 sectors)
sfdisk --no-tell-kernel "$2" <<PARTITIONS
label: dos
64,16352K,a2,-
PARTITIONS
dd conv=notrunc if="$1" of="$2" seek=64

echo "Created U-Boot SD-card image $2"
