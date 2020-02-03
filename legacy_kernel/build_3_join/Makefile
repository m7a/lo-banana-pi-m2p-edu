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

map1 = out_1/ext4_patch.tar.xz:/fs/ccnt_b3jo/in/ext4_patch.tar.xz
map2 = out_2/ext4_main.tar.xz:/fs/ccnt_b3jo/in/ext4_main.tar.xz

image:
	[ "$(MA_IMAGEBUILD)" = 0 ] || \
		docker build --build-arg "MA_DEBIAN_MIRROR=$$MA_DEBIAN_MIRROR" \
		-t $(MA_IMAGEPREFIX)/bpi-build-3-join .

run:
	exec docker run --rm -v "$(WRKROOT)/$(map1)" -e MA_DEBIAN_MIRROR \
					-v "$(WRKROOT)/$(map2)" \
					-v "$(WRKROOT)/out:/fs/ccnt_b3jo/out" \
					$(MA_IMAGEPREFIX)/bpi-build-3-join

dist-clean:
	-docker rmi $(MA_IMAGEPREFIX)/bpi-build-3-join
