################################################################################
#
# aic8800-sdio-driver
#
################################################################################

AIC8800_SDIO_DRIVER_VERSION = 33d6c97b14acb095ebc7e786a3605f1a07634d60
AIC8800_SDIO_DRIVER_SITE = $(call github,radxa-pkg,aic8800,$(AIC8800_SDIO_DRIVER_VERSION))
AIC8800_SDIO_DRIVER_LICENSE = GPL-2.0
AIC8800_SDIO_DRIVER_SUBDIR = src/SDIO/driver_fw/driver/aic8800

AIC8800_SDIO_DRIVER_DEPENDENCIES = linux

# Fix kernel API compatibility for v6.19+
define AIC8800_SDIO_DRIVER_PATCH_COMPAT
	$(BR2_EXTERNAL_LICHERVNANO_PATH)/package/aic8800-sdio-driver/fix-compat-6.19.sh \
		$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)
endef
AIC8800_SDIO_DRIVER_POST_EXTRACT_HOOKS += AIC8800_SDIO_DRIVER_PATCH_COMPAT

define AIC8800_SDIO_DRIVER_BUILD_CMDS
	$(MAKE) -C $(LINUX_DIR) \
		$(LINUX_MAKE_FLAGS) \
		M=$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)/aic8800_bsp \
		modules
	$(MAKE) -C $(LINUX_DIR) \
		$(LINUX_MAKE_FLAGS) \
		M=$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)/aic8800_fdrv \
		KBUILD_EXTRA_SYMBOLS=$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)/aic8800_bsp/Module.symvers \
		modules
endef

define AIC8800_SDIO_DRIVER_INSTALL_TARGET_CMDS
	$(MAKE) -C $(LINUX_DIR) \
		$(LINUX_MAKE_FLAGS) \
		M=$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)/aic8800_bsp \
		INSTALL_MOD_PATH=$(TARGET_DIR) \
		modules_install
	$(MAKE) -C $(LINUX_DIR) \
		$(LINUX_MAKE_FLAGS) \
		M=$(@D)/$(AIC8800_SDIO_DRIVER_SUBDIR)/aic8800_fdrv \
		INSTALL_MOD_PATH=$(TARGET_DIR) \
		modules_install
endef

$(eval $(generic-package))
