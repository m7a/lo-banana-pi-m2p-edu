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
	[ -f "$(WRKROOT)/in/hostconfig.tar.xz" ] || $(MAKE) run

establish_directories:
	mkdir -p "$(WRKROOT)/tmp_h"

image:
	[ "$(MA_IMAGEBUILD)" = 0 ] || \
		docker build --build-arg "MA_DEBIAN_MIRROR=$$MA_DEBIAN_MIRROR" \
		-t $(MA_IMAGEPREFIX)/bpi-build-prepare-config-img .

run:
	call_docker() { \
			exec docker run --rm -e MA_DEBIAN_MIRROR "$$@" \
			-v "$(WRKROOT)/tmp_h:/fs/ccnt_b0pr/tmp" \
			-v "$(WRKROOT)/in:/fs/ccnt_b0pr/out" \
			$(MA_IMAGEPREFIX)/bpi-build-prepare-config-img; \
		}; hcl=call_docker; \
		for i in $(MA_HOSTCONFIG); do \
			hctmp="$$(cd .. && cd "$$i" && pwd)"; \
			hcl="$$hcl -v \"$$hctmp:/fs/ccnt_b0pr/in/$$(basename \
								"$$hctmp")\""; \
		done; \
		eval "$$hcl"

clean:
	-rm -rf "$(WRKROOT)/tmp_h"

dist-clean: clean
	-docker rmi $(MA_IMAGEPREFIX)/bpi-build-prepare-config-img
