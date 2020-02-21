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
swap_size_mib=1024
# /2 because output is in 512 byte blocks (independent of actual blocksize)
total_mib="$(($(blockdev --getsz "$output_device") / 2 / 1024))"
data_mib="$((total_mib - swap_size_mib - 1))"
cat <<EOF
output_device=$output_device
swap_size_mib=$swap_size_mib
total_mib=$total_mib
data_mib=$data_mib

EOF

echo "-- write partition table --"
sfdisk "$output_device" <<EOF
label: dos

start=1MiB size=${data_mib}MiB type=83 bootable
start=$((data_mib + 1))MiB size=${swap_size_mib}MiB type=82
EOF
echo

echo "-- install bootloader --"
dd "if=$wd/u-boot-sunxi-with-spl.bin" "of=$output_device" bs=1024 seek=8
echo

echo "-- detect and format partitions --"
# find partition to mount
partition_root=NONEXISTENT_FILE
partition_swap=NONEXISTENT_FILE
numt=10
curt=1
while [ "$curt" -le "$numt" ] && ! [ -e "$partition_root" ]; do
	echo attempting to locate partition...
	sleep 1
	partitions="$(echo "$output_device"?* | tr ' ' '\n' | sort)"
	partition_root="$(echo "$partitions" | head -n 1)"
	partition_swap="$(echo "$partitions" | head -n 2 | tail -n 1)"
	curt="$((curt + 1))"
done
echo "partition_root=$partition_root"
echo "partition_swap=$partition_swap"
uuid_root="$(uuidgen)"
uuid_swap="$(uuidgen)"
echo "uuid_root=$uuid_root"
echo "uuid_swap=$uuid_swap"
mkfs.ext4 -U "$uuid_root" -L bpi-system "$partition_root"
mkswap    -U "$uuid_swap" -L bpi-swap   "$partition_swap"
tee "$wd/fstab" <<EOF
# BEGIN /etc/fstab auto-generated $(date) by $0
proc                                       /proc  proc  defaults                         0  0
tmpfs                                      /tmp   tmpfs defaults,size=128M,nr_inodes=1M  0  0
UUID=$uuid_root  /      ext4  errors=remount-ro                0  1
UUID=$uuid_swap  none   swap  sw                               0  0
# END /etc/fstab
EOF
echo

echo "-- copy data --"
mkdir "/media/microsd$$"
trap "rmdir /media/microsd$$" INT TERM EXIT
mount "$partition_root" "/media/microsd$$"
numpresent="$(find "/media/microsd$$" -mindepth 1 | wc -l)"
if [ "$numpresent" -gt 1 ]; then
	echo "ERROR: $numpresent files found on target mountpoint." \
					"Expected a maximum of 1." \
					"Device mounted under /media/microsd$$."
	exit 1
fi
pv "$wd/fsroot.tar" | tar -C "/media/microsd$$" -x
cp "$wd/fstab" "/media/microsd$$/etc/fstab"
df -h
umount "/media/microsd$$"
