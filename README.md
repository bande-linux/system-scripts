# Bande Linux system scripts

Admin scripts for Bande Linux on Apple Silicon Macs. The `Makefile` installs them per
distribution (`install-debian`, `install-arch`, `install-fedora`); `debian/` packages them for
Bande, released by `v*` tags:

- `bande-scripts`: firmware loading in the initramfs (`initramfs-tools/`), firmware and
  bootloader updates on the EFI system partition (`bande-fwupdate`, `update-unboot` with its
  kernel hook `kernel/postinst.d/zz-update-unboot`), battery charge limits (`macsmc-battery/`)
  and a diagnostic dump (`bande-diagnose`).
- `bande-usb-gadget`: a USB-C network and serial link from the Mac to a development machine
  (`usb-gadget/`).

The dracut, mkinitcpio, `first-boot` and `update-grub` pieces are installed only by the Arch
and Fedora targets.

## License
The copyright holders are listed in [LICENSE](LICENSE). Distributed under the MIT
license.
