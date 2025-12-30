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
	[ -f "$(WRKROOT)/in/BPI-M2P-bsp.tar.xz" ] || $(MAKE) run

establish_directories:
	mkdir -p "$(WRKROOT)/tmp_0"

image:
	[ "$(MA_IMAGEBUILD)" = 0 ] || \
		docker build --build-arg "MA_DEBIAN_MIRROR=$$MA_DEBIAN_MIRROR" \
		-t $(MA_IMAGEPREFIX)/bpi-build-0-clone-repo-img .

run:
	exec docker run --rm -e MA_DEBIAN_MIRROR \
				-v "$(WRKROOT)/tmp_0:/fs/ccnt_b0dl/tmp" \
				-v "$(WRKROOT)/in:/fs/ccnt_b0dl/out" \
				$(MA_IMAGEPREFIX)/bpi-build-0-clone-repo-img

clean:
	-rm -rf "$(WRKROOT)/tmp_0"

dist-clean: clean
	-docker rmi $(MA_IMAGEPREFIX)/bpi-build-0-clone-repo-img
