# LicheeRV Nano WE Buildroot

Buildroot-based Linux image for the Sipeed LicheeRV Nano WE (WiFi + Ethernet) board, using mainline Linux 6.19 and U-Boot 2025.04.

## Features

- Mainline Linux 6.19 kernel (RISC-V)
- U-Boot 2025.04 with upstream LicheeRV Nano support
- OpenSBI
- 100Mbps Ethernet with DHCP
- AIC8800 WiFi 6 (SDIO) with wpa_supplicant
- USB CDC ACM serial gadget (kernel console + login shell)
- UART serial console on ttyS0 at 115200 baud

## Requirements

- Linux host (tested on Debian/Ubuntu)
- Standard build tools: `gcc`, `g++`, `make`, `patch`, `git`, `rsync`, `bc`, `bison`, `flex`, `unzip`, `python3`
- `dosfstools` and `mtools` for SD card image generation

## Building

Clone with Buildroot (included as a submodule pinned to 2026.02):

```
git clone --recurse-submodules https://github.com/sandreas/licheerv-nano-build.git
cd licheerv-nano-build
```

Build the image:

```
make
```

The first build takes a while as it compiles the cross-toolchain, kernel, bootloader, and root filesystem from source. Subsequent builds are incremental.

The output SD card image is at:

```
output/images/sdcard.img
```

## Flashing

Write the image to a microSD card:

```
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=1M status=progress
```

Replace `/dev/sdX` with your SD card device.

## WiFi Configuration

Edit `board/licheervnano/rootfs_overlay/etc/wpa_supplicant.conf` before building, or edit `/etc/wpa_supplicant.conf` on the rootfs partition after flashing:

```
network={
    ssid="YourSSID"
    psk="YourPassword"
}
```

WiFi connects automatically on boot with DHCP.

## Serial Console

- **UART**: ttyS0 at 115200 baud (hardware serial pins)
- **USB**: plug the USB-C port into a host PC, it appears as `/dev/ttyACM0`

Both provide kernel logs and a root login shell.

## Other Make Targets

| Target | Description |
|--------|-------------|
| `make` | Configure and build |
| `make menuconfig` | Buildroot configuration |
| `make linux-menuconfig` | Kernel configuration |
| `make clean` | Remove build output |
| `make distclean` | Full clean including config |
