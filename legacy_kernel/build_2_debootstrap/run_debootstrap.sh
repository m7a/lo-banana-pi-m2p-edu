#!/bin/sh -e
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

# Setup

if [ -z "$MA_BPI_WORKDIR" ]; then
	echo MA_BPI_WORKDIR not set. Terminating.
	exit 1
fi

stage=1

nextstage() {
	stage="$(($stage + 1))"
	echo $stage > "$MA_BPI_WORKDIR/tmp/stage.txt"
}

[ ! -f "$MA_BPI_WORKDIR/tmp/stage.txt" ] || \
				stage="$(cat "$MA_BPI_WORKDIR/tmp/stage.txt")"

if [ "$stage" = 1 ]; then
	if [ -d "$MA_BPI_WORKDIR/tmp/rootfs" ]; then
		echo WARNING: Root FS already present. Deleting... 2>&2
		rm -r "$MA_BPI_WORKDIR/tmp/rootfs"
	fi

	mkdir -p "$MA_BPI_WORKDIR/tmp/rootfs"

	nextstage
fi

if [ "$stage" = 2 ]; then
	mkdir -p "$MA_BPI_WORKDIR/tmp/rootfs/usr/share/keyrings"
	cp /usr/share/keyrings/debian-archive-keyring.gpg \
				"$MA_BPI_WORKDIR/tmp/rootfs/usr/share/keyrings"
	# Bootstrap 1
	debootstrap --no-check-gpg --arch=armhf --foreign jessie \
				"$MA_BPI_WORKDIR/tmp/rootfs" "$MA_DEBIAN_MIRROR"
	nextstage
fi

if [ "$stage" = 3 ]; then
	# Bootstrap 2

	cp /usr/bin/qemu-arm-static "$MA_BPI_WORKDIR/tmp/rootfs/usr/bin"

	if ! chroot "$MA_BPI_WORKDIR/tmp/rootfs" /bin/true; then
		echo Failed to call chroot. Please install qemu-user-static on \
			the system running this container.
		exit 1
	fi

	nextstage
fi

if [ "$stage" = 4 ]; then
	# requires privileged...
	DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
					LC_ALL=C LANGUAGE=C LANG=C chroot \
					"$MA_BPI_WORKDIR/tmp/rootfs" \
					/debootstrap/debootstrap --second-stage
	nextstage
fi

if [ "$stage" = 5 ]; then
	tar -C "$MA_BPI_WORKDIR/tmp" -xpf "$MA_BPI_WORKDIR/in/hostconfig.tar.xz"
	cp -R "$MA_BPI_WORKDIR/tmp/hostconfig/postinst.d" \
					"$MA_BPI_WORKDIR/tmp/rootfs/tmp"
	nextstage
fi

if [ "$stage" = 6 ]; then
	for i in "$MA_BPI_WORKDIR/tmp/rootfs/tmp/postinst.d"/*; do
		if [ -x "$i" ]; then
			chroot "$MA_BPI_WORKDIR/tmp/rootfs" \
					"/tmp/postinst.d/$(basename "$i")"
		else
			echo Skipping non-executable file "$i"
		fi
	done
	nextstage
fi

if [ "$stage" = 7 ]; then
	rm -r "$MA_BPI_WORKDIR/tmp/rootfs/tmp/postinst.d"
	nextstage
fi

if [ "$stage" = 8 ]; then
	# User configuration
	tar -C "$MA_BPI_WORKDIR/tmp/hostconfig/fsroot" -c . | \
					tar -C "$MA_BPI_WORKDIR/tmp/rootfs" -xp
	nextstage
fi

if [ "$stage" = 9 ]; then
	# Package result
	tar -C "$MA_BPI_WORKDIR/tmp/rootfs" -c . | xz -9 > \
					"$MA_BPI_WORKDIR/out/ext4_main.tar.xz"
	nextstage
fi

if [ "$stage" = 10 ]; then
	rm "$MA_BPI_WORKDIR/tmp/stage.txt"
else
	echo ERROR: Early termination, stage ${stage}/10. 1>&2
	exit 1
fi
