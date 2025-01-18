UBOOT=v2025.01
LINUX=linux-6.13-rc7.tar.gz
CONFIG=odroid-m2-rk3588s
BUILD_DIR=$(shell pwd)/build-$(CONFIG)
ENV=BL31=../rkbin/rk3588_bl31_v1.47.elf ROCKCHIP_TPL=../rkbin/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin DTC=/usr/bin/dtc O=$(BUILD_DIR)

$(CONFIG)-uboot.img: build/u-boot-rockchip.bin
	./add-partition-table.sh $< $@

build/u-boot-rockchip.bin: build/generated_defconfig
	$(MAKE) $(ENV) -C $(UBOOT) -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu-

# https://docs.u-boot.org/en/latest/develop/bootstd/overview.html#controlling-ordering
build-$(CONFIG)/generated_defconfig: $(UBOOT)/Makefile
	echo boot_targets=mmc0 nvme mmc1 usb pxe dhcp > u-boot/board/hardkernel/odroid_m2/odroid_m2.env
	$(MAKE) $(ENV) -C $(UBOOT) $(CONFIG)_defconfig

$(UBOOT)/Makefile: $(UBOOT).tar.gz $(LINUX)
	mkdir -p $(UBOOT)
	tar xzf $< -C $(UBOOT) --strip-components 1 
	tar xzf $(LINUX) -C $(UBOOT)/dts/upstream/src/arm64/ arch/arm64/boot/dts/rockchip --strip-components 5
	echo CONFIG_LTO=y >> $(UBOOT)/configs/$(CONFIG)_defconfig

$(UBOOT).tar.gz:
	wget https://github.com/u-boot/u-boot/archive/refs/tags/$@

$(LINUX):
	wget https://git.kernel.org/torvalds/t/$@

menuconfig:
	$(MAKE) $(ENV) -C $(UBOOT) menuconfig

clean:
	rm -rf build-$(CONFIG) $(UBOOT)

.PHONY: clean menuconfig
