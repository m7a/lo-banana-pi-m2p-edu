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

include $(MA_BS_CONF_PREFIX)conf.mk

export MA_DEBIAN_MIRROR MA_IMAGEPREFIX MA_IMAGEBUILD MA_HOSTCONFIG WRKROOT

all:
	[ -d "$(WRKROOT)/in" ] || mkdir "$(WRKROOT)/in"
	[ "$(MA_USE_HACK)" != 1 ] || $(MAKE) hack_in
	$(MAKE) image
	$(MAKE) run

# -- HACK --

hack_in: host_config_hack armbian_hack

host_config_hack:
	mkdir -p "$(WRKROOT)/tmp_h/hostconfig"
	for i in $(MA_HOSTCONFIG); do tar -C "$$i" -c . | \
				tar -C "$(WRKROOT)/tmp_h/hostconfig" -xp; done
	tar -C "$(WRKROOT)/tmp_h" -c hostconfig | xz -9 > \
				"$(WRKROOT)/in/hostconfig.tar.xz"

armbian_hack:
	tar -c armbian | xz -9 > "$(WRKROOT)/in/armbian.tar.xz"

# -- END --

establish_directories:
	mkdir -p "$(WRKROOT)/tmp" "$(WRKROOT)/out"

image:
	[ "$(MA_IMAGEBUILD)" = 0 ] || \
		docker build --build-arg "MA_DEBIAN_MIRROR=$$MA_DEBIAN_MIRROR" \
		-t $(MA_IMAGEPREFIX)/bpi-build-armbian-debootstrap .

# privileged is for mounting proc in the chroot. The only alternative to be
# thought of involves giving proc as a docker volume and that might be even more
# problematic...
run:
	exec docker run --privileged --rm \
			-e MA_DEBIAN_MIRROR \
			-v "$(WRKROOT)/in:/fs/ccnt/in:ro" \
			-v "$(WRKROOT)/tmp:/fs/ccnt/tmp" \
			-v "$(WRKROOT)/out:/fs/ccnt/out" \
			$(MA_IMAGEPREFIX)/bpi-build-armbian-debootstrap

clean:
	-rm -rf "$(WRKROOT)/tmp" "$(WRKROOT)/tmp_h"

dist-clean: clean
	-docker rmi $(MA_IMAGEPREFIX)/bpi-build-armbian-debootstrap

x_update_readme:
	cp /data/main/man/d5i/37/banana_pi_m2_plus_edu.d5i README.txt
