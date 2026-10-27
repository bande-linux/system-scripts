#!/bin/sh
# SPDX-License-Identifier: MIT

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -e /vendorfw ]; then
    info ":: Unbound: Vendor firmware was loaded by the bootloader"
    return 0
fi

if [ ! -e /proc/device-tree/chosen/unbound,efi-system-partition ]; then
    info ":: Unbound: Missing unbound,efi-system-partition variable, firmware will not be loaded!"
    return 0
fi

info ":: Unbound: Triggering early load of NVMe modules..."
modprobe apple-mailbox
modprobe nvme-apple

for i in $(seq 0 50); do
    [ -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ] && break
    sleep 0.1
done

if [ ! -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ]; then
    warn ":: Unbound: Timed out waiting for NVMe device"
    return 1
fi

# If the above exists, hopefully the /dev device exists and this will work
info ":: Unbound: Unpacking vendor firmware into initramfs..."

VENDORFW="/run/.system-efi/vendorfw/"

(
    . /usr/share/unbound-scripts/functions.sh
    mount_sys_esp /run/.system-efi
)

if [ ! -e "$VENDORFW/firmware.cpio" ]; then
    warn ":: Unbound: Vendor firmware not found in ESP."
    umount /run/.system-efi
    return 1
fi

( cd /; cpio --quiet -i < "$VENDORFW/firmware.cpio" )
info ":: Unbound firmware unpacked successfully"
umount /run/.system-efi
