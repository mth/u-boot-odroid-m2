#!/bin/sh

set -e

if [ ! -f "$1" ] || [ -z "$2" ]; then
	echo "Usage: $0 build-odroid-m2-rk3588s/u-boot-rockchip.bin u-boot.img"
	exit 1
fi

fallocate -l 12MiB "$2"
# Size is 12288K - 32K (64 sectors)
/sbin/sfdisk --no-tell-kernel "$2" <<PARTITIONS
label: dos
64,12256K,a2,-
PARTITIONS
dd conv=notrunc if="$1" of="$2" seek=64

echo "Created U-Boot SD-card image $2"
