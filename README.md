# U-Boot image for Odroid-M2

Install build dependencies:

	./debian-deps.sh

Build the image:

	make

This U-Boot build includes Odroid-M2 device tree from the Linux 6.16 kernel sources,
that will be provided to the operating system booted with UEFI. The device tree is patched to
enable both on-board and HDMI audio output. It likely also works with other Linux kernel
versions, so you can upgrade your distribution kernels.

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

This also copies (and overwrites) the partition table, which makes it easier to replace the u-boot later (it will be on the `/dev/mmcblk0p1` which has the correct 64\*512 byte offset). The original HardKernel firmware will be lost - you may want to back up it first.

If you install to the eMMC, then this copying must be done before partitioning the eMMC using the installer, or alternatively you can ensure that first ~12MiB is not partitioned and use a bit different command:

	dd bs=32K count=330 if=/dev/mmcblk1p1 of=/dev/mmcblk0 seek=1

The actual u-boot is pretty small, but it consists of two parts that must be at right place on the device,
with second one starting at 8MiB offset.

## Connecting UART

<img align="right" src="https://mth.github.io/images/odroid-m2-uart.png">

The UART pins counted from the nearest board corner are *ground, TX, RX* and *+3.3V*.
This means that your serial adapter pins should be connected in the order *ground, RX* and *TX*
(which often is black, green, white). The serial adapter should be configured for 1500000
baud rate, for example by using `screen /dev/ttyUSB0 1500000`.

The UART uses 3.3V signalling, please don't attempt connecting anything like RS232 port directly
(those are specified for +/-12V signals, and would likely fry at least the SOCs UART).
USB serial adapters supporting 1500000 baud rate are suitable, for example those using
FT232R (FTDI), CH343, CH340 and some PL2303 variants (HX, GR, GE, GC, EA, TA).

## No HDMI output

The U-Boot 25.07 does not support HDMI output on the RK3588. The GRUB booted on it with EFI also has no HDMI output, as is with Linux kernel versions prior to 6.13. The HDMI audio output needs 6.15 kernel.

It is possible to have HDMI output on the installed Linux, provided that it uses at least 6.13 kernel compiled with `CONFIG_ROCKCHIP_DW_HDMI_QP` enabled and video mode (for example video=1920x1080@60) is given on kernel command line. You should use at least 6.15 kernel version, if you wish to use other video modes than 1920x1080.

You may need to install newer kernel, if your distributions default kernel is older than 6.13
(for example on the Debian you can install experimental kernel packages, or possibly use the
backports, when newer kernel versions have landed there).

Usable GUI also needs userland to have 24.x or newer version of the Mesa libraries.

Currently you need UART console to use Linux distributions installers.

## Browsers

Chromium based browsers run smoothly with good performance, but they contain some bug that causes frequent crashes when using Wayland directly. Possible workarounds are setting *Preferred Ozone platform* _#ozone-platform-hint_ to `X11` or enabling *Vulkan* _#enable-vulkan_ and *Default ANGLE Vulkan* _#default-angle-vulkan_ on the `chrome://flags` page.

Enabling *Vulkan* gives a bit better performance (probably due not using Xwayland) and has been tested with Mesa [25.1](https://github.com/mth/u-boot-odroid-m2/issues/2) and 25.2. Using ungoogled-chromium flatpak with Mesa 25.2 on Debian 13 I enabled *Override software rendering list* _\#ignore-gpu-blocklist_, *Vulkan* _\#enable-vulkan*, *Default ANGLE Vulkan* _\#default-angle-vulkan_, *Vulkan from ANGLE* _\#vulkan-from-angle_, *Trees in viz* _\#trees-in-viz_ and disabled *Wayland linux-drm-syncobj explicit sync* _\#wayland-linux-drm-syncobj_ and *GPU rasterization* _\#enable-gpu-rasterization_ (GPU rasterization with Vulkan seems to cause flickering on pages).

Firefox has acceptable performance with the Linux 6.15 kernel and is annoyingly laggy on the 6.13.

## Further tuning

There seems to be a bug that causes Linux kernel to log warnings `[CRTC:80:video_port0] vblank wait timed out` and if Wayland syncs with vblank, it hungs for a second or few. Workaround is to disable vblank syncing (avoiding the hickups), for example start Sway with environment variable `vblank_mode=0` set and add `output * allow_tearing yes` into `~/.config/sway/config` file.

Run the `util/cpu-affinity-m2.sh` script at startup for IRQ affinity and CPU scheduler tuning.

This script is inspired by Thomas Kaiser [comments about Radxa Rock 5B with BSP kernel](https://github.com/ThomasKaiser/Knowledge/blob/master/articles/Quick_Preview_of_ROCK_5B.md).

If you like Quake III, put `seta cl_renderer "opengl1"` into `~/.q3a/baseq3/q3config.cfg` (replacing previous `cl_renderer` value) for better ioquake3 performance. It is mostly fast and flawlessly playable, although with rare hiccups.

I'm using following additional kernel parameters in the Debians `/etc/default/grub` file:

* `coherent_pool=2M` to allocate 2MB contiguous memory for DMA (should avoid some UAS problems)
* `video=1920x1080@60` sets the video mode for display connected to the HDMI
* `drm.vblankoffdelay=50` seems to make `vblank wait timed out` warnings rarer
* `console=ttyS2 console=tty0` enables both serial and framebuffer console, with framebuffer as primary for entering LUKS password at boot
