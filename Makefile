PREFIX=/usr/local
SYS_PREFIX=$(PREFIX)
CONFIG_DIR=/etc/default
BIN_DIR=$(PREFIX)/bin
SCRIPTS=unbound-diagnose unbound-fwupdate update-unboot
ARCH_SCRIPTS=update-grub first-boot
UNITS=first-boot.service
MULTI_USER_WANTS=first-boot.service
DRACUT_CONF_DIR=$(PREFIX)/lib/dracut/dracut.conf.d
DRACUT_MODULES_DIR=$(PREFIX)/lib/dracut/modules.d
SYSTEMD_UNIT_DIR=$(PREFIX)/lib/systemd/system
UDEV_RULES_DIR=$(PREFIX)/lib/udev/rules.d
UDEV_HWDB_DIR=$(PREFIX)/lib/udev/hwdb.d
NETWORKD_DIR=$(PREFIX)/lib/systemd/network
BUILD_SCRIPTS=$(addprefix build/,$(SCRIPTS))
BUILD_ARCH_SCRIPTS=$(addprefix build/,$(ARCH_SCRIPTS))

all: $(BUILD_SCRIPTS) $(BUILD_ARCH_SCRIPTS)

build/%: %
	@[ ! -e build ] && mkdir -p build || true
	sed -e s,/etc/default,$(CONFIG_DIR),g "$<" > "$@"
	chmod +x "$@"

clean:
	rm -rf build

install: all
	install -d $(DESTDIR)$(BIN_DIR)/
	install -m0755 -t $(DESTDIR)$(BIN_DIR)/ $(BUILD_SCRIPTS)
	install -dD $(DESTDIR)/etc
	install -dD $(DESTDIR)$(PREFIX)/share/unbound-scripts
	install -m0644 -t $(DESTDIR)$(PREFIX)/share/unbound-scripts functions.sh
	install -dD $(DESTDIR)$(SYS_PREFIX)/lib/firmware/vendor

install-mkinitcpio: install
	install -dD $(DESTDIR)$(PREFIX)/lib/initcpio/install
	install -m0644 -t $(DESTDIR)$(PREFIX)/lib/initcpio/install initcpio/install/unbound
	install -dD $(DESTDIR)$(PREFIX)/lib/initcpio/hooks
	install -m0644 -t $(DESTDIR)$(PREFIX)/lib/initcpio/hooks initcpio/hooks/unbound

install-dracut: install
	install -dD $(DESTDIR)$(DRACUT_CONF_DIR)
	install -m0644 -t $(DESTDIR)$(DRACUT_CONF_DIR) dracut/dracut.conf.d/10-unbound.conf
	install -dD $(DESTDIR)$(DRACUT_MODULES_DIR)/91kernel-modules-unbound
	install -m0755 -t $(DESTDIR)$(DRACUT_MODULES_DIR)/91kernel-modules-unbound dracut/modules.d/91kernel-modules-unbound/module-setup.sh
	install -dD $(DESTDIR)$(DRACUT_MODULES_DIR)/99unbound-firmware
	install -m0755 -t $(DESTDIR)$(DRACUT_MODULES_DIR)/99unbound-firmware dracut/modules.d/99unbound-firmware/install-unbound-firmware.sh
	install -m0755 -t $(DESTDIR)$(DRACUT_MODULES_DIR)/99unbound-firmware dracut/modules.d/99unbound-firmware/load-unbound-firmware.sh
	install -m0755 -t $(DESTDIR)$(DRACUT_MODULES_DIR)/99unbound-firmware dracut/modules.d/99unbound-firmware/module-setup.sh

install-macsmc-battery: install
	install -dD $(DESTDIR)$(SYSTEMD_UNIT_DIR)
	install -dD $(DESTDIR)$(UDEV_RULES_DIR)
	install -m0755 -t $(DESTDIR)$(SYSTEMD_UNIT_DIR) macsmc-battery/systemd/macsmc-battery-charge-control-end-threshold.path
	install -m0755 -t $(DESTDIR)$(SYSTEMD_UNIT_DIR) macsmc-battery/systemd/macsmc-battery-charge-control-end-threshold.service
	install -m0644 -t $(DESTDIR)$(UDEV_RULES_DIR) macsmc-battery/udev/93-macsmc-battery-charge-control.rules

install-udev-hwdb: install
	install -dD $(DESTDIR)$(UDEV_HWDB_DIR)
	install -m0644 -t $(DESTDIR)$(UDEV_HWDB_DIR) udev/hwdb.d/65-autosuspend-override-unbound-sdhci.hwdb

install-arch: install install-mkinitcpio install-macsmc-battery install-udev-hwdb
	install -m0755 -t $(DESTDIR)$(BIN_DIR)/ $(BUILD_ARCH_SCRIPTS)
	install -dD $(DESTDIR)$(PREFIX)/lib/systemd/system
	install -dD $(DESTDIR)$(PREFIX)/lib/systemd/system/{multi-user,sysinit}.target.wants
	install -m0644 -t $(DESTDIR)$(PREFIX)/lib/systemd/system $(addprefix systemd/,$(UNITS))
	ln -sf $(addprefix $(PREFIX)/lib/systemd/system/,$(MULTI_USER_WANTS)) \
		$(DESTDIR)$(PREFIX)/lib/systemd/system/multi-user.target.wants/
	install -dD $(DESTDIR)$(PREFIX)/share/libalpm/hooks
	install -m0644 -t $(DESTDIR)$(PREFIX)/share/libalpm/hooks libalpm/hooks/95-unboot-install.hook

install-fedora: install install-dracut install-macsmc-battery install-udev-hwdb

install-initramfs-tools: install
	install -dD $(DESTDIR)$(PREFIX)/share/initramfs-tools/hooks
	install -m0755 -t $(DESTDIR)$(PREFIX)/share/initramfs-tools/hooks initramfs-tools/hooks/unbound
	install -dD $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-premount
	install -m0755 -t $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-premount initramfs-tools/scripts/init-premount/unbound
	install -dD $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-bottom
	install -m0755 -t $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-bottom initramfs-tools/scripts/init-bottom/unbound

install-debian: install install-initramfs-tools install-macsmc-battery install-udev-hwdb
	install -dD $(DESTDIR)/etc/kernel/postinst.d
	install -m0755 -t $(DESTDIR)/etc/kernel/postinst.d kernel/postinst.d/zz-update-unboot

uninstall:
	rm -f $(addprefix $(DESTDIR)$(BIN_DIR)/,$(SCRIPTS))
	rm -rf $(DESTDIR)$(PREFIX)/share/unbound-scripts

uninstall-mkinitcpio:
	rm -f $(DESTDIR)$(PREFIX)/lib/initcpio/install/unbound
	rm -f $(DESTDIR)$(PREFIX)/lib/initcpio/hooks/unbound

uninstall-dracut:
	rm -f $(DESTDIR)$(DRACUT_CONF_DIR)/10-unbound.conf

uninstall-macsmc-battery:
	rm -f $(DESTDIR)$(SYSTEMD_UNIT_DIR)/macsmc-battery-charge-control-end-threshold.path
	rm -f $(DESTDIR)$(SYSTEMD_UNIT_DIR)/macsmc-battery-charge-control-end-threshold.service
	rm -f $(DESTDIR)$(UDEV_RULES_DIR)/93-macsmc-battery-charge-control.rules

uninstall-udev-hwdb:
	rm -f $(DESTDIR)$(UDEV_HWDB_DIR)/65-autosuspend-override-unbound-sdhci.hwdb

uninstall-arch: uninstall-mkinitcpio uninstall-macsmc-battery uninstall-udev-hwdb
	rm -f $(addprefix $(DESTDIR)$(BIN_DIR)/,$(ARCH_SCRIPTS))
	rm -f $(addprefix $(DESTDIR)$(PREFIX)/lib/systemd/system/,$(UNITS))
	rm -f $(addprefix $(DESTDIR)$(PREFIX)/lib/systemd/system/multi-user.target.wants/,$(MULTI_USER_WANTS))
	rm -f $(DESTDIR)$(PREFIX)/share/libalpm/hooks/95-unboot-install.hook

uninstall-fedora: uninstall-dracut uninstall-macsmc-battery uninstall-udev-hwdb

uninstall-initramfs-tools:
	rm -f $(DESTDIR)$(PREFIX)/share/initramfs-tools/hooks/unbound
	rm -f $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-premount/unbound
	rm -f $(DESTDIR)$(PREFIX)/share/initramfs-tools/scripts/init-bottom/unbound

uninstall-debian: uninstall-initramfs-tools uninstall-macsmc-battery uninstall-udev-hwdb
	rm -f $(DESTDIR)/etc/kernel/postinst.d/zz-update-unboot

.PHONY: install-usb-gadget clean \
        install \
        install-mkinitcpio \
        install-dracut \
        install-macsmc-battery \
        install-udev-hwdb \
        install-arch \
        install-fedora \
        install-initramfs-tools \
        install-debian \
        uninstall \
        uninstall-mkinitcpio \
        uninstall-dracut \
        uninstall-macsmc-battery \
        uninstall-udev-hwdb \
        uninstall-arch \
        uninstall-fedora \
        uninstall-initramfs-tools \
        uninstall-debian

install-usb-gadget:
	install -dD $(DESTDIR)$(BIN_DIR) $(DESTDIR)$(SYSTEMD_UNIT_DIR) $(DESTDIR)$(UDEV_RULES_DIR) $(DESTDIR)$(NETWORKD_DIR)
	install -m0755 -t $(DESTDIR)$(BIN_DIR) usb-gadget/unbound-usb-gadget
	sed -e s,/usr/bin/,$(BIN_DIR)/,g usb-gadget/unbound-usb-gadget@.service > $(DESTDIR)$(SYSTEMD_UNIT_DIR)/unbound-usb-gadget@.service
	install -m0644 -t $(DESTDIR)$(UDEV_RULES_DIR) usb-gadget/80-unbound-usb-gadget.rules
	install -m0644 -t $(DESTDIR)$(NETWORKD_DIR) usb-gadget/80-unbound-usb-gadget.network
