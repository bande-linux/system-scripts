#!/bin/sh
# SPDX-License-Identifier: MIT

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -d /$(uname -r) ]; then
    info ":: Unbound: dev modules present, link them into system"
    ln -s /$(uname -r) /lib/modules/
fi
