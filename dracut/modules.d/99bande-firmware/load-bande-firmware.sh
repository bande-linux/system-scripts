#!/bin/sh
# SPDX-License-Identifier: MIT

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /vendorfw ]; then
    info ":: Bande: Vendor firmware was loaded by the bootloader"
    return 0
fi

if [ ! -e /proc/device-tree/chosen/bande,efi-system-partition ]; then
    info ":: Bande: Missing bande,efi-system-partition variable, firmware will not be loaded!"
    return 0
fi

info ":: Bande: Triggering early load of NVMe modules..."
modprobe apple-mailbox
modprobe nvme-apple

for i in $(seq 0 50); do
    [ -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ] && break
    sleep 0.1
done

if [ ! -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ]; then
    warn ":: Bande: Timed out waiting for NVMe device"
    return 1
fi

# If the above exists, hopefully the /dev device exists and this will work
info ":: Bande: Unpacking vendor firmware into initramfs..."

VENDORFW="/run/.system-efi/vendorfw/"

(
    . /usr/share/bande-scripts/functions.sh
    mount_sys_esp /run/.system-efi
)

if [ ! -e "$VENDORFW/firmware.cpio" ]; then
    warn ":: Bande: Vendor firmware not found in ESP."
    umount /run/.system-efi
    return 1
fi

( cd /; cpio --quiet -i < "$VENDORFW/firmware.cpio" )
info ":: Bande firmware unpacked successfully"
umount /run/.system-efi
