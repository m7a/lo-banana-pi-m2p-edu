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

MA_TARGET_RESOLUTION = 720P

# induced variables
MA_BPI_BUILDDIR = $$MA_BPI_WORKDIR/tmp/BPI-M2P-bsp
MA_BPI_FROOT = $(MA_BPI_BUILDDIR)/output/BPI-M2P-$(MA_TARGET_RESOLUTION)/pack
MA_BPI_CARD = $$MA_BPI_WORKDIR/tmp/f100mod.img

# Beware: The new-kernel prepared things do not result in a working image...

MA_NEW_KERNEL_NAME = linux-sunxi

all:
	$(MAKE) setup
	$(MAKE) extract_kernel
	[ ! -f "$$MA_BPI_WORKDIR/in/BPI-Mainline-kernel.tar.xz" ] || \
							$(MAKE) upgrade_kernel
	$(MAKE) compile
	$(MAKE) check_curlog
	$(MAKE) package
	$(MAKE) clean

setup:
	@if [ -z "$$MA_BPI_WORKDIR" ]; then echo MA_BPI_WORKDIR not set. 1>&2; \
								exit 1; fi
	[ -d "$$MA_BPI_WORKDIR/tmp" ] || mkdir "$$MA_BPI_WORKDIR/tmp"

extract_kernel:
	tar -C "$$MA_BPI_WORKDIR/tmp" -xf \
					"$$MA_BPI_WORKDIR/in/BPI-M2P-bsp.tar.xz"

upgrade_kernel:
	tar -C "$$MA_BPI_WORKDIR/tmp" -xf \
			"$$MA_BPI_WORKDIR/in/$(MA_NEW_KERNEL_NAME).tar.xz"
	rm -rf "$(MA_BPI_BUILDDIR)/linux-sunxi"
	mv -f "$$MA_BPI_WORKDIR/tmp/$(MA_NEW_KERNEL_NAME)" \
						"$(MA_BPI_BUILDDIR)/linux-sunxi"
	cp /var/tmp/build/new_kernel.diff "$(MA_BPI_BUILDDIR)"
	cd $(MA_BPI_BUILDDIR) && patch -i new_kernel.diff

compile:
	cd "$(MA_BPI_BUILDDIR)" && echo 1 | \
				./build.sh BPI-M2P-$(MA_TARGET_RESOLUTION)

check_curlog:
	@curlog="$$(cat \
		"$(MA_BPI_BUILDDIR)/u-boot-sunxi/cur.log")"; \
		if [ -z "$$curlog" ]; then \
			echo Ma_Sys.ma FATAL ERROR: EMPTY CURLOG. THE \
					GENERATED u-boot.fex IS INVALID. 1>&2; \
			exit 1; \
		else \
			echo Ma_Sys.ma Debug CURLOG=\"$$curlog\"; \
		fi

package: ext4 fat32 bootloader

ext4:
	if [ -f "$(MA_BPI_BUILDDIR)/new_kernel.diff" ]; then \
			$(MAKE) ext4_new_kernel; \
		else \
			$(MAKE) ext4_default; \
		fi

ext4_default:
	mkdir -p "$$MA_BPI_WORKDIR/tmp/ext4"
	tar -C "$$MA_BPI_WORKDIR/tmp/ext4" -xpf \
			"$(MA_BPI_BUILDDIR)/SD/bpi-m2p"/*-BPI-M2P-Kernel.tgz
	tar -C "$$MA_BPI_WORKDIR/tmp/ext4" -xpf \
			"$(MA_BPI_BUILDDIR)/SD/bpi-m2p/BOOTLOADER-bpi-m2p.tgz"
	tar -C "$$MA_BPI_WORKDIR/tmp/ext4" -c . | \
				xz -9 > "$$MA_BPI_WORKDIR/out/ext4_patch.tar.xz"
	rm -r "$$MA_BPI_WORKDIR/tmp/ext4"

ext4_new_kernel:
	tar -C "$(MA_BPI_BUILDDIR)/linux-sunxi/output" -c lib/modules | \
				xz -9 > "$$MA_BPI_WORKDIR/out/ext4_patch.tar.xz"

fat32:
	mkdir -p "$$MA_BPI_WORKDIR/tmp/fat32"
	cp -r "$(MA_BPI_BUILDDIR)/SD/bpi-m2p/BPI-BOOT/bananapi" \
						"$$MA_BPI_WORKDIR/tmp/fat32"
	tar -C "$$MA_BPI_WORKDIR/tmp/fat32" -c . | xz -9 \
					> "$$MA_BPI_WORKDIR/out/fat32.tar.xz"
	rm -r "$$MA_BPI_WORKDIR/tmp/fat32"

bootloader:
	dd if=/dev/zero "of=$(MA_BPI_CARD)" bs=1M count=100
	dd "if=$(MA_BPI_FROOT)/boot0_sdcard.fex"\
					"of=$(MA_BPI_CARD)" bs=1k seek=8
	dd "if=$(MA_BPI_FROOT)/u-boot.fex" \
					"of=$(MA_BPI_CARD)" bs=1k seek=16400
	dd "if=$(MA_BPI_FROOT)/sunxi_mbr.fex" \
					"of=$(MA_BPI_CARD)" bs=1k seek=20480
	dd "if=$(MA_BPI_FROOT)/boot-resource.fex" \
					"of=$(MA_BPI_CARD)" bs=1k seek=36864
	dd "if=$(MA_BPI_FROOT)/env.fex" \
					"of=$(MA_BPI_CARD)" bs=1k seek=69632
	xz -9 < "$(MA_BPI_CARD)" > "$$MA_BPI_WORKDIR/out/f100mod.img.xz"
	-rm "$(MA_BPI_CARD)"

clean:
	-rm -r "$$MA_BPI_WORKDIR/tmp"/*
