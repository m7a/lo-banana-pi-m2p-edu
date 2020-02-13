#!/bin/sh -e
# Ma_Sys.ma Script to generate images for Banana Pi M2+EDU based on Debian only,
# Copyright (c) 2020 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

scriptroot="$(cd "$(dirname "$0")" && pwd)"
include_root_overrides="$scriptroot/armbian_and_debian/hostconfig"
wd="$scriptroot/wd"
output_device=
mirror=http://ftp.it.debian.org/debian
debian_version=buster

while [ $# != 0 ]; do
	case "$1" in
	(--help) echo "USAGE $0" "[-i INCLUDE] [-o DEVICE] [-d DEBIANVERSION]" \
					"[-w WORKDIR] [-m MIRROR]"; exit 0;;
	(-i)     include_root_overrides="$include_root_overrides \"$2\"";;
	(-o)     output_device="$2";;
	(-w)     wd="$2";;
	(-d)     debian_version="$2";;
	(*)      echo "Unknown option: $1"; exit 1;;
	esac
	shift 2
done

if [ ! -f "$wd/fsroot_complete.txt" ]; then
	if [ -d "$wd/fsroot" ]; then
		rm -r "$wd/fsroot"
	fi
	mkdir -p "$wd/fsroot/usr/share/keyrings"
	date >> "$wd/fsroot_inprogress.txt"
	debootstrap --no-check-gpg --arch=armhf --foreign "$debian_version" \
		"$wd/fsroot" "$mirror" 2>&1 | tee -a "$wd/fsroot_inprogress.txt"
	cp /usr/bin/qemu-arm-static "$wd/fsroot/usr/bin"
	if ! chroot "$wd/fsroot" /bin/true; then
		echo ERROR: Could not run ARM executable. | \
					tee -a "$wd/fsroot_inprogress.txt"
		exit 1
	fi
	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
			LC_ALL=C LANGUAGE=C LANG=C chroot "$wd/fsroot" \
			/debootstrap/debootstrap --second-stage 2>&1 | \
			tee -a "$wd/fsroot_inprogress.txt"
	umount "$wd/fsroot/proc" || true # "not mounted"?
	date >> "$wd/fsroot_inprogress.txt"
	mv "$wd/fsroot_inprogress.txt" "$wd/fsroot_complete.txt"
fi
