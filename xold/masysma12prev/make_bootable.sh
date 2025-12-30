#!/bin/sh -e

# equivalent scripts/bootloader.sh

if [ $# = 0 -o "$1" = "--help" ]; then
	echo USAGE $0 DEVICE
	echo Use the device node directly like /dev/sda, not the partition!
	exit 0
fi

if [ "$(id -u)" != 0 ]; then
	echo Need to be root. 1>&2
	exit 1
fi

card="$1"
if [ ! -e "$card" ]; then
	echo Node not found: $1 1>&2
	exit 1
fi

for i in boot0_sdcard.fex u-boot.fex sunxi_mbr.fex boot-resource.fex env.fex; do
	if [ ! -f "$i" ]; then
		echo $i not found. aborting...
		exit 1
	fi
done

# dd if=/dev/zero of=tmp_file bs=1M count=100

dd if=boot0_sdcard.fex  "of=${card}" bs=1k seek=8
dd if=u-boot.fex        "of=${card}" bs=1k seek=16400
dd if=sunxi_mbr.fex     "of=${card}" bs=1k seek=20480
dd if=boot-resource.fex "of=${card}" bs=1k seek=36864
dd if=env.fex           "of=${card}" bs=1k seek=69632
