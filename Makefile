UBOOT=v2025.04
LINUX=linux-6.15
LINUX_TAR=$(LINUX).tar.xz
CONFIG=odroid-m2-rk3588s
BUILD_DIR=$(shell pwd)/build-$(CONFIG)
ENV=BL31=../rkbin/rk3588_bl31_v1.47.elf ROCKCHIP_TPL=../rkbin/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin DTC=/usr/bin/dtc O=$(BUILD_DIR)
DEFCONFIG_FILE=$(UBOOT)/configs/$(CONFIG)_defconfig

$(CONFIG)-uboot.img: build-$(CONFIG)/u-boot-rockchip.bin
	./add-partition-table.sh $< $@

build-$(CONFIG)/u-boot-rockchip.bin: build-$(CONFIG)/generated_defconfig
	$(MAKE) $(ENV) -C $(UBOOT) -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu-

# https://docs.u-boot.org/en/latest/develop/bootstd/overview.html#controlling-ordering
build-$(CONFIG)/generated_defconfig: $(DEFCONFIG_FILE)
	# mmc1 is sd card and mmc0 is the internal eMMC device
	echo boot_targets=mmc1 nvme mmc0 usb pxe dhcp > $(UBOOT)/board/hardkernel/odroid_m2/odroid_m2.env
	$(MAKE) $(ENV) -C $(UBOOT) $(CONFIG)_defconfig

$(DEFCONFIG_FILE): $(UBOOT).tar.gz $(LINUX_TAR)
	mkdir -p $(UBOOT)
	tar xzf $< -C $(UBOOT) --strip-components 1 
	tar xf $(LINUX_TAR) -C $(UBOOT)/dts/upstream/src/arm64/ $(LINUX)/arch/arm64/boot/dts/rockchip --strip-components 5
	for i in patches/*.patch; do patch -d $(UBOOT)/dts/upstream/src/arm64/rockchip -p6 < $i; done
	echo CONFIG_LTO=y >> $(UBOOT)/configs/$(CONFIG)_defconfig

$(UBOOT).tar.gz:
	wget https://github.com/u-boot/u-boot/archive/refs/tags/$@

$(LINUX_TAR):
	wget https://cdn.kernel.org/pub/linux/kernel/v6.x/$@
	# wget https://git.kernel.org/torvalds/t/$@

menuconfig:
	$(MAKE) $(ENV) -C $(UBOOT) menuconfig

clean:
	rm -rf build-$(CONFIG) $(UBOOT)

.PHONY: clean menuconfig
