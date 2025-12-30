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

all:
	$(MAKE) image
	$(MAKE) run

establish_directories:
	if [ ! -d "$(WRKROOT)/in" ]; then echo Need $wrkroot/in first. 1>&2; \
								exit 1; fi
	mkdir -p "$(WRKROOT)/tmp_1" "$(WRKROOT)/out_1"

image:
	[ "$(MA_IMAGEBUILD)" = 0 ] || \
		docker build --build-arg "MA_DEBIAN_MIRROR=$$MA_DEBIAN_MIRROR" \
		-t $(MA_IMAGEPREFIX)/bpi-build-1-kernel-boot-img .

run:
	exec docker run --rm -e MA_DEBIAN_MIRROR \
				-v "$(WRKROOT)/in:/fs/ccnt_b1kb/in:ro" \
				-v "$(WRKROOT)/tmp_1:/fs/ccnt_b1kb/tmp" \
				-v "$(WRKROOT)/out_1:/fs/ccnt_b1kb/out" \
				$(MA_IMAGEPREFIX)/bpi-build-1-kernel-boot-img

clean:
	-rm -rf "$(WRKROOT)/tmp_1" "$(WRKROOT)/out_1"

dist-clean: clean
	-docker rmi $(MA_IMAGEPREFIX)/bpi-build-1-kernel-boot-img
