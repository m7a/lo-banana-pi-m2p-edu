# Ma_Sys.ma Scripts to build Debian images for a Banana Pi M2+EDU,
# Copyright (c) 2017 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# To be called from inside the container...

MA_KERNEL = 4.10.0-sun8i

ma_pattern_ubd = linux-u-boot-dev-bananapim2plus*.deb
ma_chrfs = $$MA_BPI_WORKDIR/tmp/rootfs
ma_dbm = $$MA_BPI_WORKDIR/tmp/debootstrap_completed.txt
ma_devpre = $$MA_BPI_WORKDIR/tmp/armbian
ma_sxpre = $$MA_BPI_WORKDIR/tmp/ubx/usr/lib
ma_sxfn = u-boot-sunxi-with-spl.bin
ma_tcm = /var/tmp/tools_completed.txt

all:
	$(MAKE) local_setup
	$(MAKE) local_s1_prepare_files
	$(MAKE) local_s2_boot
	$(MAKE) local_postinst_d
	$(MAKE) local_apply_fsroot
	$(MAKE) local_package_result

local_setup:
	@if [ -z "$$MA_BPI_WORKDIR" ]; then echo MA_BPI_WORKDIR not set. 1>&2; \
								exit 1; fi
	@if [ ! -f "$$MA_BPI_WORKDIR/in/armbian.tar.xz" ]; then echo \
			Required armbian.tar.xz missing. 1>&2; exit 1; fi
	[ -d "$$MA_BPI_WORKDIR/tmp" ] || mkdir "$$MA_BPI_WORKDIR/tmp"

local_s1_prepare_files: local_debootstrap local_prepare_armbian_xz

# might prepend this w/ an automatic download if not present...
local_prepare_armbian_xz:
	tar -C "$$MA_BPI_WORKDIR/tmp" -xf "$$MA_BPI_WORKDIR/in/armbian.tar.xz"
	$(MAKE) local_extract_special_debs

local_extract_special_debs: local_extract_root_dev local_extract_u_boot_dev

local_extract_root_dev:
	[ -d "$$MA_BPI_WORKDIR/tmp/arrf" ] || mkdir "$$MA_BPI_WORKDIR/tmp/arrf"
	dpkg-deb -x "$(ma_devpre)"/linux-*-root-dev-bananapim2plus*.deb \
						"$$MA_BPI_WORKDIR/tmp/arrf"

local_extract_u_boot_dev:
	[ -d "$$MA_BPI_WORKDIR/tmp/ubx"  ] || mkdir "$$MA_BPI_WORKDIR/tmp/ubx"
	dpkg-deb -x "$(ma_devpre)"/$(ma_pattern_ubd) "$$MA_BPI_WORKDIR/tmp/ubx"

local_debootstrap:
	@if [ -f "$(ma_dbm)" ]; then \
			echo Skipping debootstrap, already complted. \
							$$(cat "$(ma_dbm)"); \
		else \
			$(MAKE) local_debootstrap_sub; \
		fi

local_debootstrap_sub:
	mkdir -p "$(ma_chrfs)/usr/share/keyrings"
	cp /usr/share/keyrings/debian-archive-keyring.gpg \
					"$(ma_chrfs)/usr/share/keyrings"
	debootstrap --no-check-gpg --arch=armhf --foreign jessie \
					"$(ma_chrfs)" "$$MA_DEBIAN_MIRROR"
	cp /usr/bin/qemu-arm-static "$$MA_BPI_WORKDIR/tmp/rootfs/usr/bin"
	@if ! chroot "$(ma_chrfs)" /bin/true; then \
			echo Failed to call chroot. Please install \
				qemu-user-static on the system \
				running this container.; \
			exit 1; \
		fi
	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
			LC_ALL=C LANGUAGE=C LANG=C chroot "$(ma_chrfs)" \
			/debootstrap/debootstrap --second-stage
	umount "$(ma_chrfs)/proc"
	date > "$(ma_dbm)"

local_s2_boot: local_boot local_boot_spl

local_boot_spl:
	xz -9 < "$$(find "$(ma_sxpre)" -type f -name $(ma_sxfn))" > \
					"$$MA_BPI_WORKDIR/out/$(ma_sxfn).xz"
	rm -r "$$MA_BPI_WORKDIR/tmp/ubx"

local_boot:
	cp -R "$$MA_BPI_WORKDIR/tmp/arrf/usr/share/armbian"/* "$(ma_chrfs)/boot"
	cp "$$MA_BPI_WORKDIR/tmp/armbian/boot.bmp" "$(ma_chrfs)/boot"
	cp -R "$$MA_BPI_WORKDIR/tmp/arrf/boot" "$(ma_chrfs)"
	cp "$(ma_chrfs)/boot/bin/bananapim2plus.bin" \
						"$(ma_chrfs)/boot/script.bin"
	mkdir -p "$(ma_chrfs)/var/tmp/build/debs"
	cp /var/tmp/build/Makefile "$(ma_chrfs)/var/tmp/build"
	cp "$$MA_BPI_WORKDIR/tmp/armbian"/*.deb "$(ma_chrfs)/var/tmp/build/debs"
	@# remove files which are not to be installed...
	rm "$(ma_chrfs)/var/tmp/build/debs"/linux-*-root-dev-bananapim2p*.deb \
			"$(ma_chrfs)/var/tmp/build/debs"/$(ma_pattern_ubd)
	cp /etc/apt/sources.list "$(ma_chrfs)/etc/apt/sources.list"
	$(MAKE) local_require_make
	$(MAKE) local_boot_build
	rm -r "$(ma_chrfs)/var/tmp/build"

local_require_make:
	[ -x "$(ma_chrfs)/usr/bin/make" ] || chroot "$(ma_chrfs)" /bin/sh -ec \
				"apt-get update && apt-get -y dist-upgrade && \
				apt-get -y install make"

local_boot_build:
	chroot "$(ma_chrfs)" $(MAKE) -C /var/tmp/build chroot_boot

local_postinst_d:
	tar -C "$$MA_BPI_WORKDIR/tmp" -xpf \
					"$$MA_BPI_WORKDIR/in/hostconfig.tar.xz"
	cp -R "$$MA_BPI_WORKDIR/tmp/hostconfig/postinst.d" "$(ma_chrfs)/tmp"
	for i in "$(ma_chrfs)/tmp/postinst.d"/*; do \
			if [ -x "$$i" ]; then \
				chroot "$(ma_chrfs)" \
					"/tmp/postinst.d/$$(basename "$$i")"; \
			else \
				echo Skipping non-executable file "$$i"; \
			fi; \
		done
	rm -r "$(ma_chrfs)/tmp/postinst.d"

local_apply_fsroot:
	tar -C "$$MA_BPI_WORKDIR/tmp/hostconfig/fsroot" -c . | \
							tar -C "$(ma_chrfs)" -xp

local_package_result:
	tar -C "$(ma_chrfs)" -c . | xz -9 > \
					"$$MA_BPI_WORKDIR/out/ext4_main.tar.xz"

chroot_boot:
	-dpkg --configure -a # for safety
	$(MAKE) chroot_boot_install_tools
	$(MAKE) chroot_boot_local_make_bootable

chroot_boot_install_tools:
	@if [ -f "$(ma_tcm)" ]; then \
			echo Tool installation completed, $$(cat "$(ma_tcm)"); \
		else \
			$(MAKE) chroot_boot_install_tools_sub; \
		fi

chroot_boot_install_tools_sub:
	dpkg -i /var/tmp/build/debs/*.deb
	apt-get -y install initramfs-tools u-boot-tools
	date > "$(ma_tcm)"

chroot_boot_local_make_bootable:
	@if [ -f "/boot/initrd.img-$(MA_KERNEL)" ]; then \
					echo Deleting old initrd.; \
					rm "/boot/initrd.img-$(MA_KERNEL)"; fi
	update-initramfs -k $(MA_KERNEL) -c
	mkimage -A arm -O linux -T ramdisk -C gzip -n uInitrd \
		-d "/boot/initrd.img-$(MA_KERNEL)" "/boot/uInitrd-$(MA_KERNEL)"
	ln -sf /boot/uInitrd-$(MA_KERNEL) /boot/uInitrd
	mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
