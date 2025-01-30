# U-Boot image for Odroid-M2

Install build dependencies:

	./debian-deps.sh

Build the image:

	make

This U-Boot build includes Odroid-M2 device tree from the Linux 6.13 kernel sources,
that will be provided to the operating system booted with UEFI.

Write it to SD card (replace sdXX with device corresponding to the SD card):

	dd if=odroid-m2-rk3588s-uboot.img of=/dev/sdXX

If you can't bother to build it and really trust me, you may instead use a pre-built image:

	curl https://dot.planet.ee/dist/odroid-m2-rk3588s-uboot.img.xz | unxz > /dev/sdXX

1. Download your favorite UEFI Linux installer image for aarch64 and write it to USB stick.
2. Connect M.2 NVME to the board (optional).
3. Connect UART (serial) console to the boards UART.
4. Insert both the SD card and USB stick into your Odroid-M2. Set the boot switch to SD card.
5. Power on the board to boot the installer.
6. Install your Linux distribution.
7. Boot the Linux distribution.

You can copy the U-Boot to the internal eMMC when Linux system has booted on the board.
Please verify before that `/dev/mmcblk1` is the SD card and `/dev/mmcblk0` is the 64GB eMMC on the board.

	dd bs=12M count=1 if=/dev/mmcblk1 of=/dev/mmcblk0

This also copies (and overwrites) the partition table, which makes it easier to replace the u-boot later
(it will be on the `/dev/mmcblk0p1` which has the correct 64\*512 byte offset). The original HardKernel
firmware will be lost - you may want to back up it first.

If you install to the eMMC, then this copying must be done before partitioning the eMMC using the installer,
or alternatively you can ensure that first ~12MiB is not partitioned and use a bit different command:

	dd bs=32K count=330 if=/dev/mmcblk1p1 of=/dev/mmcblk0 seek=1

The actual u-boot is pretty small, but it consists of two parts that must be at right place on the device,
with second one starting at 8MiB offset.

## Connecting UART

The UART pins counted from the nearest board corner are *ground, TX, RX* and *+3.3V*.
This means that your serial adapter pins should be connected in the order *ground, RX* and *TX*
(which often is black, green, white). The serial adapter should be configured for 1500000
baud rate, for example by using `screen /dev/ttyUSB0 1500000`.

The UART uses 3.3V signalling, please don't attempt connecting anything like RS232 port directly
(those are specified for +/-12V signals, and would likely fry at least the SOCs UART).
USB serial adapters supporting 1500000 baud rate are suitable, for example those using
FT232R (FTDI), CH343, CH340 and some PL2303 variants (HX, GR, GE, GC, EA, TA).

## No HDMI output

The U-Boot 25.01 does not support HDMI output on the RK3588. The GRUB booted on it with EFI also has
no HDMI output, as is with Linux kernel versions prior to 6.13.

It is possible to have HDMI output on the installed Linux, provided that it uses at least 6.13 kernel
compiled with `CONFIG_ROCKCHIP_DW_HDMI_QP` enabled and video mode (for example video=1920x1080@60) is
given on kernel command line. The support in 6.13 is also limited to more standard video modes up to
4K resolution. This is likely to improve in future, but currently it means that you need UART console
to use some Linux distributions installer.
