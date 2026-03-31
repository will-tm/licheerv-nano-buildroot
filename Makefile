BR2_EXTERNAL := $(CURDIR)
BUILDROOT_DIR := $(CURDIR)/buildroot
OUTPUT_DIR := $(CURDIR)/output
DEFCONFIG := licheerv_nano_we_defconfig

.PHONY: all defconfig build menuconfig linux-menuconfig clean distclean

all: build

defconfig:
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) O=$(OUTPUT_DIR) $(DEFCONFIG)

build: defconfig
	$(MAKE) -C $(BUILDROOT_DIR) O=$(OUTPUT_DIR)

menuconfig:
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) O=$(OUTPUT_DIR) menuconfig

linux-menuconfig:
	$(MAKE) -C $(BUILDROOT_DIR) O=$(OUTPUT_DIR) linux-menuconfig

clean:
	$(MAKE) -C $(BUILDROOT_DIR) O=$(OUTPUT_DIR) clean

distclean:
	rm -rf $(OUTPUT_DIR)
