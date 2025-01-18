# U-Boot image for Odroid-M2

Install build dependencies:

	./debian-deps.sh

Build the image:

	make

Write it to SD card:

	dd if=odroid-m2-rk3588s-uboot.img of=/dev/sdXX

1. Download your favorite UEFI linux installer image for aarch64 and write it to USB stick.
2. Connect M.2 NVME to the board (optional).
3. Connect serial console to the boards UART.
4. Insert both the SD card and USB stick into your Odroid-M2. Set the boot switch to SD card.
5. Power on the board to boot the installer.
6. Install your linux distribution.
7. Boot the linux distribution.

You can copy the U-Boot to internal eMMC when Linux system has booted on the board.

	dd bs=12M count=1 if=/dev/mmcblk0 of=/dev/mmcblk1

This also copies (and overwrites) the partition table, with makes it easier later to replace the u-boot
(it will be on the /dev/mmcblk1p1 which has the correct 64\*512 byte offset).

If you install to the eMMC, then this must be done before partitioning the eMMC using the installer,
or alternatively you can ensure that first ~12MiB is not partitioned and use a bit different command:

	dd bs=32K count=330 if=/dev/mmcblk0 of=/dev/mmcblk1 seek=1

The actual u-boot is pretty small, but it consists of two parts that must be at right place on the device,
with second one starting at 8MiB offset.
