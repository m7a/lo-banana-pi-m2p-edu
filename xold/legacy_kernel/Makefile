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

# $1 [-a] $2 log file $3 command & args
LOGGED_COMMAND = @logged_command() { \
		append=0; \
		if [ "$$1" = -a ]; then \
			append=1; \
			shift; \
		fi; \
		log_file="$$1"; \
		shift; \
		commandpid=; \
		if [ "$$append" = 1 ]; then \
			"$$@" >> "$$log_file" 2>&1 & commandpid=$$!; \
		else \
			"$$@" >  "$$log_file" 2>&1 & commandpid=$$!; \
		fi; \
		trap "kill -s TERM $$commandpid" INT TERM; \
		tail -f "$$log_file" & tailpid=$$!; \
		wait "$$commandpid"; \
		rc=$$?; \
		kill -s TERM "$$tailpid" || true; \
		exit "$$rc"; \
	}; logged_command

all:
	$(MAKE) prepare_wrkroot
	$(MAKE) establish_directories
	$(MAKE) prepare
	$(MAKE) sub_1
	$(MAKE) sub_2

prepare_wrkroot:
	mkdir -p "$(WRKROOT)/in"
	$(MA_HOOK_PREPARE)

establish_directories:
	mkdir -p "$(WRKROOT)/out" "$(WRKROOT)/in"
	$(MAKE) -C build_0_clone_repo   establish_directories
	$(MAKE) -C build_prepare_config establish_directories
	$(MAKE) -C build_1_kernel_boot  establish_directories
	$(MAKE) -C build_2_debootstrap  establish_directories

prepare: build_0_clone_repo_all build_prepare_config_all

build_0_clone_repo_all:
	$(MAKE) -C build_0_clone_repo all

build_prepare_config_all:
	$(MAKE) -C build_prepare_config all

sub_1: build_1_kernel_boot_all build_2_debootstrap_all build_3_join_image

build_1_kernel_boot_all:
	$(LOGGED_COMMAND) "$(WRKROOT)/out/log1.txt" \
					$(MAKE) -C build_1_kernel_boot all

build_2_debootstrap_all:
	$(LOGGED_COMMAND) "$(WRKROOT)/out/log2.txt" \
					$(MAKE) -C build_2_debootstrap all

build_3_join_image:
	$(LOGGED_COMMAND) "$(WRKROOT)/out/log3.txt" \
						$(MAKE) -C build_3_join image

sub_2: build_3_join_run mv

build_3_join_run:
	$(LOGGED_COMMAND) -a "$(WRKROOT)/out/log3.txt" \
						$(MAKE) -C build_3_join run

mv:
	cp "$(WRKROOT)/out_1/f100mod.img.xz" "$(WRKROOT)/out_1/fat32.tar.xz" \
								"$(WRKROOT)/out"

dist-clean: build_0_clone_repo_dist_clean build_prepare_config_dist_clean \
		build_1_kernel_boot_dist_clean build_2_debootstrap_dist_clean \
		build_3_join_image_dist_clean

build_0_clone_repo_dist_clean:
	$(MAKE) -C build_0_clone_repo dist-clean

build_prepare_config_dist_clean:
	$(MAKE) -C build_prepare_config dist-clean

build_1_kernel_boot_dist_clean:
	$(MAKE) -C build_1_kernel_boot dist-clean

build_2_debootstrap_dist_clean:
	$(MAKE) -C build_2_debootstrap dist-clean

build_3_join_image_dist_clean:
	$(MAKE) -C build_3_join dist-clean

x_update_readme:
	cp /data/main/man/d5i/37/banana_pi_m2_plus_edu.d5i README.txt
