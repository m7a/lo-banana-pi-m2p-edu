#!/bin/sh -e
# Ma_Sys.ma Script to generate images for Banana Pi M2+EDU based on Debian only,
# Copyright (c) 2020 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

scriptroot="$(cd "$(dirname "$0")" && pwd)"
wd="$scriptroot/wd"

if [ $# = 0 ] || [ "$1" = "--help" ]; then
	cat <<EOF
USAGE $0 device

run as root or other user capable of writing+reading the respective raw device
file.
EOF
	exit 0
fi

echo "-- determine metadata --"
output_device="$1"
swap_size_gib=1
# /2 because output is in 512 byte blocks (independent of actual blocksize)
total_gib="$(($(blockdev --getsz "$output_device") / 2 / 1024 / 1024))"
data_gib="$(total_gib - swap_size_gib)"
cat <<EOF
output_device=$output_device
swap_size_gib=$swap_size_gib
total_gib=$total_gib
data_gib=$data_gib

EOF

echo "-- write partition table --"
sfdisk "$output_device" <<EOF
label: dos

start=0 size=${data_gib}GiB type=83 bootable
start=${data_gib}GiB size=${swap_size_gib}GiB type=82
EOF
echo

echo "-- install bootloader --"
dd "if=$wd/u-boot-sunxi-with-spl.bin" "of=$output_device" bs=1024 seek=8
echo

echo "-- copy data --"
mkdir "/media/microsd$$"
# find partition to mount
partition="$(echo "$output_device"?* | tr ' ' '\n' | sort | head -n 1)"
echo "partition=$partition"
mount "$partition" "/media/microsd$$"
numpresent="$(find "/media/microsd$$" | wc -l)"
if [ "$numpresent" -gt 1 ]; then
	echo "ERROR: $numpresent files found on target mountpoint." \
					"Expected a maximum of 1." \
					"Device mounted under /media/microsd$$."
	exit 1
fi
pv "$wd/fsroot.tar" | tar -C "/media/microsd$$" -x
df -h
umount "/media/microsd$$"
