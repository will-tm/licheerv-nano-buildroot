################################################################################
#
# aic8800-sdio-firmware
#
################################################################################

AIC8800_SDIO_FIRMWARE_VERSION = c56f910044cc854d6c553bcb9a644f3bca5a4c38
AIC8800_SDIO_FIRMWARE_SITE = $(call github,lxowalle,aic8800-sdio-firmware,$(AIC8800_SDIO_FIRMWARE_VERSION))
AIC8800_SDIO_FIRMWARE_LICENSE = PROPRIETARY

define AIC8800_SDIO_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/firmware/aic8800_sdio
	rsync -aHL $(@D)/ $(TARGET_DIR)/usr/lib/firmware/aic8800_sdio/
endef

$(eval $(generic-package))
