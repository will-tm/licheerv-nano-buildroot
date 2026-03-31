#!/bin/sh

export PATH="/usr/sbin:$PATH"

BOARD_DIR="${BR2_EXTERNAL_LICHERVNANO_PATH}/board/licheervnano"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
FIPTOOL_DIR="${BOARD_DIR}/fiptool"

# Generate fip.bin from FSBL + OpenSBI + U-Boot
/usr/bin/python3 ${FIPTOOL_DIR}/fiptool \
  --fsbl ${FIPTOOL_DIR}/data/fsbl/cv181x.bin \
  --ddr_param ${FIPTOOL_DIR}/data/ddr_param.bin \
  --opensbi ${FIPTOOL_DIR}/data/opensbi.bin \
  --uboot ${BINARIES_DIR}/u-boot.bin \
  --rtos ${FIPTOOL_DIR}/data/cvirtos.bin \
  ${BINARIES_DIR}/fip.bin || exit 1

cp "${BOARD_DIR}/extlinux.conf" "${BINARIES_DIR}/"

${HOST_DIR}/bin/genimage \
  --rootpath "${TARGET_DIR}" \
  --tmppath "${BUILD_DIR}/genimage.tmp" \
  --inputpath "${BINARIES_DIR}" \
  --outputpath "${BINARIES_DIR}" \
  --config "${GENIMAGE_CFG}"
