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

if [ -d "$MA_BPI_WORKDIR/tmp/rootfs" ]; then
	echo Root FS already present. Terminating.
	exit 1
fi

mkdir -p "$MA_BPI_WORKDIR/tmp/rootfs"

echo Extract ext4_main.tar.xz
tar -C "$MA_BPI_WORKDIR/tmp/rootfs" -xpf "$MA_BPI_WORKDIR/in/ext4_main.tar.xz"
echo Extract ext4_patch.tar.xz
tar -C "$MA_BPI_WORKDIR/tmp/rootfs" -xpf "$MA_BPI_WORKDIR/in/ext4_patch.tar.xz"

echo Pack ext4.tar.xz
tar -C "$MA_BPI_WORKDIR/tmp/rootfs" -c . | xz -9 > \
					"$MA_BPI_WORKDIR/out/ext4.tar.xz"

echo Cleanup
rm -r "$MA_BPI_WORKDIR/tmp/rootfs"
