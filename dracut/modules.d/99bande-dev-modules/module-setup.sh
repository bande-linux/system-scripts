#!/bin/sh
# SPDX-License-Identifier: MIT

# called by dracut
check() {
    if [ -n "$hostonly" ] && [ ! -e /proc/device-tree/chosen/bande,efi-system-partition ]; then
       return 0
    elif [ -z "$hostonly" ]; then
        return 0
    else
       return 255
    fi
}

# called by dracut
depends() {
    echo fs-lib
    return 0
}

# called by dracut
install() {
    inst_multiple cp ln mkdir mount
    inst_hook pre-udev 99 "${moddir}/link-bande-dev-modules.sh"
    inst_hook pre-pivot 99 "${moddir}/install-bande-dev-modules.sh"
}
