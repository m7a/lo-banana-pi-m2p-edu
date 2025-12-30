#!/bin/sh -e

# Setup

if [ -z "$MA_BPI_WORKDIR" ]; then
	echo MA_BPI_WORKDIR not set. Terminating.
	exit 1
fi

[ -d "$MA_BPI_WORKDIR/tmp" ] || mkdir "$MA_BPI_WORKDIR/tmp"

target_resolution=720P

# Build

tar -C "$MA_BPI_WORKDIR/tmp" -xf "$MA_BPI_WORKDIR/in/BPI-M2P-bsp.tar.xz"

builddir="$MA_BPI_WORKDIR/tmp/BPI-M2P-bsp"
cd "$builddir"
echo 1 | ./build.sh BPI-M2P-$target_resolution

echo Ma_Sys.ma Debug Build completed.
curlog="$(cat "$builddir/u-boot-sunxi/cur.log")"
if [ -z "$curlog" ]; then
	echo Ma_Sys.ma FATAL ERROR: EMPTY CURLOG. THE GENERATED u-boot.fex IS \
								INVALID. 1>&2
	exit 1
else
	echo Ma_Sys.ma Debug CURLOG=\"$curlog\"
fi

# Ext4

(
	mkdir -p "$MA_BPI_WORKDIR/tmp/ext4"
	tar -C "$MA_BPI_WORKDIR/tmp/ext4" -xf \
				"$builddir/SD/bpi-m2p"/*-BPI-M2P-Kernel.tgz
	tar -C "$MA_BPI_WORKDIR/tmp/ext4" -xf \
				"$builddir/SD/bpi-m2p/BOOTLOADER-bpi-m2p.tgz"
	tar -C "$MA_BPI_WORKDIR/tmp/ext4" -c . | \
				xz -9 > "$MA_BPI_WORKDIR/out/ext4_patch.tar.xz"
	rm -r "$MA_BPI_WORKDIR/tmp/ext4"
) & ep=$!

# Fat32

(
	mkdir -p "$MA_BPI_WORKDIR/tmp/fat32"
	cp -r "$builddir/SD/bpi-m2p/BPI-BOOT/bananapi" \
						"$MA_BPI_WORKDIR/tmp/fat32"
	tar -C "$MA_BPI_WORKDIR/tmp/fat32" -c . | xz -9 \
					> "$MA_BPI_WORKDIR/out/fat32.tar.xz"
	rm -r "$MA_BPI_WORKDIR/tmp/fat32"
) & fp=$!

# Bootloader

(
	froot="$builddir/output/BPI-M2P-$target_resolution/pack"
	card="$MA_BPI_WORKDIR/tmp/boot.img"
	dd if=/dev/zero "of=$card" bs=1M count=100
	dd "if=$froot/boot0_sdcard.fex"  "of=$card" bs=1k seek=8
	dd "if=$froot/u-boot.fex"        "of=$card" bs=1k seek=16400
	dd "if=$froot/sunxi_mbr.fex"     "of=$card" bs=1k seek=20480
	dd "if=$froot/boot-resource.fex" "of=$card" bs=1k seek=36864
	dd "if=$froot/env.fex"           "of=$card" bs=1k seek=69632
	xz -9 < "$card" > "$MA_BPI_WORKDIR/out/f100mod.xz"
) & bp=$!

# Finish

for i in $ep $fp $bp; do
	rc=0
	wait $i || rc=$?
	if [ "$rc" != 0 ] && [ "$rc" != 127 ]; then
		echo Subprocess $i failed w/ code ${rc}.
		exit $rc
	fi
done

# Cleanup

cd "$MA_BPI_WORKDIR"
rm -r "$builddir"
