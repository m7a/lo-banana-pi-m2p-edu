---
x-masysma-name: banana_pi_m2_plus_edu
section: 37
title: Banana Pi M2+EDU Resources
keywords: ["kb", "bananapi", "arm", "debian", "m2p", "blog", "bpi"]
lang: en-US
date: 2017/03/31 16:21:44
x-masysma-version: 1.0.2
x-masysma-copyright: |
  Copyright (c) 2017, 2018 Ma_Sys.ma.
  For furhter info send an e-mail to Ma_Sys.ma@web.de.
x-masysma-repository: https://www.github.com/m7a/lp-banana-pi-m2p-edu
x-masysma-website: https://masysma.lima-city.de/37/banana_pi_m2_plus_edu.xhtml
x-masysma-owned: 1
---
WARNING: Outdated
=================

As of today (2020/02/03), at least parts of the scripts have ceased to work.
Additionally, there might by now be a means to build everything wholly on Debian
resources, but the details of this have not been found out yet.

For now, the original content has been retained below.

## Files overview

`armbian_and_debian`
:   Files used to create images based on an armbian Kernel and a Debian OS.
`legacy_kernel`
:   Files used to create images based on the vendor-supplied Kernel and Debian.

Introduction: Debian on the Banana Pi M2+EDU
============================================

The Banana Pi M2+EDU is a cheap ARM board supporting Gigabit Ethernet. This
article describes means of getting to run Debian (and Docker) on the Banana Pi
M2+EDU.

Debian is the OS used for all Ma_Sys.ma computers and thus it seemed to be a
good idea to attempt to get to run an _unmodified_ Debian on the Banana Pi
M2+EDU as well.

This proved to be difficult and thus, some minor modifications were accepted in
the end. Still, the result is closer to a “stock” Debian compared to most other
approaches.

### The necessity for a recent kernel 

The first approach was to use the vendor-supplied tools in addition to a
`debootstrap`-created Debian root directory (cf. section “Debian + Vendor
Supplied Legacy Kernel”). This proved unable to run Docker and was thus
replaced by the approach presented in “Debian + Armbian Kernel”.

These solutions to “Debian on the Banana Pi M2+EDU” currently exist:

 * Debian-Images from the
   [official Banana Pi website](http://www.banana-pi.org/m2plus-download.html):
   These images are larger than necessary and only available with old kernels.
   Also, it is a bit unclear how those images can be created/customized.
 * [armbian](https://www.armbian.com/banana-pi-m2-plus/):
   These images are of good quality and best if you want an image optimized for
   the ARM platform. They are, however, heavily customized and as of this
   writing, there is no Debian + recent Kernel.

If one is looking for an easy solution, the armbian-Images can be recommended.
The following sections present an approach which comes closer to an unmodified
Debian and allows maximum control over the packages present in the image.

All of the approaches presented here, as well as the armbian images, work with
microSD cards of any size (tested for 128 GB).

Debian + Vendor Supplied Legacy Kernel
======================================

Result
:   This approach produces an image suited for a microSD card which contains a
    Debian installation equipped with the officially supplied Banana Pi M2+
    kernel. This supports HDMI and Gigabit Ethernet but is based on a kernel
    3.4.39 and thus too old to run Docker.

First, clone the repository as follows:

	git clone https://github.com/m7a/lp-banana-pi-m2p-edu

System requirements:

 * Docker
 * POSIX `make`

Configuration is similar to the approach presented in section “Debian + Armbian
Kernel”, but there is no “hack” needed. Also, an additional variable called
`MA_HOOK_PREPARE` is available:

`MA_HOOK_PREPARE`
:   Contains code to be executed for preparation (e.g. providing `.tar.xz`
    files). This is set to `:` (or `true`) if not used.

Be aware that unlike “Debian + Armbian Kernel”, this approach creates _four_
containers which exchange intermediate results in form of `.tar.xz`-files.
External resources are downloaded in “step 0” if not already present in
`$(WRKROOT)/in`.

To run the build, use `make` as described in section “Debian + Armbian Kernel”.
It makes sense to use `make -j10 ...` (or a larger number if you want to use
more processes) to parallelize kernel and u-boot compilation.

Partition the microSD card as follows:

	100 MiB of leading free space
	50 MiB of FAT32 storage (label=BPI-BOOT, flags=lba, boot)
	XX MiB of EXT4 storage  (label=BPI-ROOT)
	1024 MiB of SWAP storage

Hint: To backup & restore the partition layout, use `sfdisk` as follows:

 * save: `sfdisk -d /dev/sdj > file`
 * restore: `sfdisk /dev/sdj < file`
 * This is of course only necessary if you want to re-create partitioning from a
   previously partitioned microSD card.

Run these commands (assuming `/dev/sdj` is your microSD card device node) to
establsih the partition filesystems and labels. The flags will need to be set
separately (e. g. with `gparted`).

	mkdosfs -F 32 -n BPI-BOOT /dev/sdj1
	mkfs.ext4 -L BPI-ROOT /dev/sdj2
	mkswap /dev/sdj3

Once the build has completed successfully, use the resulting files from below
`$(WRKROOT)/out` as follows (assuming `/dev/sdj` is your microSD card device
node):

`f100mod.img.xz`
:   `unxz < f100mod.img.xz | dd bs=1k seek=8 skip=8 of=device`
`fat32.tar.xz`
:   `mount /dev/sdj1 /mnt && tar -C /mnt -xpf fat32.tar.xz && umount /mnt`
`ext4.tar.xz`
:   `mount /dev/sdj2 /mnt && tar -C /mnt -xpf ext4.tar.xz && umount /mnt`

Debian + Armbian Kernel
=======================

Result
:   This approach produces an image suited for a microSD card which contains a
    Debian installation equipped with the Armbian Bootloader and a recent Kernel
    like 4.10. The resulting system will support the Gigabit Ethernet port but
    not display anything via the HDMI output. Also, there will be no
    documented/automatic means of upgrading the kernel without re-generating the
    image.

The steps used to build the image are formalized in the associated GIT
Repository. It is recommended that you clone the repository as follows:

	git clone https://github.com/m7a/lp-banana-pi-m2p-edu.git

System requirements:

 * `xz-utils` (or prepared `.tar.xz` archives)
 * Docker
 * POSIX `make`

External Resources

 * `boot.bmp`
   <https://raw.githubusercontent.com/igorpecovnik/lib/master/bin/splash/armbian-universal.bmp>
 * <http://apt.armbian.com/pool/main/l/linux-4.10.0-sun8i/>
 * `linux-dtb-dev-sun8i_5.26_armhf.deb`
 * `linux-firmware-image-dev-sun8i_5.26_armhf.deb`
 * `linux-headers-dev-sun8i_5.26_armhf.deb`
 * `linux-image-dev-sun8i_5.26_armhf.deb`
 * `linux-u-boot-dev-bananapim2plus_5.25_armhf.deb`
   <http://apt.armbian.com/pool/main/l/linux-u-boot-bananapim2plus-dev/>
 * `linux-xenial-root-dev-bananapim2plus_5.25_armhf.deb`
   <http://apt.armbian.com/pool/main/l/linux-xenial-root-bananapim2plus/>

Obtain the files from the sources listed. Other versions might also work but
have not been tested. If you want to use the hack for direct invocation (the
system is also prepared to perform fully-automatic processing), provide the
files downloaded in the `armbian` directory in the repository.

Next, the image to be created has to be confgiured. This is done by creating a
file ending with `conf.mk`, e.g. `myconf.mk` and a `hostconfig` directory. A
minimal `hostconfig` and `conf.mk` are already supplied with the repository.
You are suggested to add your own separate `hostconfig`, e.g. `myhostconfig`
which may contain files below `fsroot` which will be copied to the root file
system (after the hooks from `postinst.d` have been executed) and `postinst.d`
which contains scripts/programs to be called from inside the prepared root
filesystem.

Assuming you followed the instructions so far, you might put the following in
`myconf.mk`

	# Changed Sample Settings
	MA_DEBIAN_MIRROR = http://ftp.de.debian.org/debian
	MA_USE_HACK = 1
	MA_HOSTCONFIG = hostconfig myhostconfig
	MA_IMAGEBUILD = 1
	MA_IMAGEPREFIX = masysmalocal
	WRKROOT = /var/tmp

The settings can be described as follows:

`MA_DEBIAN_MIRROR`
:   Configures the debian mirror to be consulted for image generation.
`MA_USE_HACK`
:   If this is 1, a hack to build `.tar.xz` files from `armbian` and
    `hostconfig` directories is enabled. This makes it easier to amend the
    configuration from the `hostconfig` directories but makes
    pipeline-automation more difficult. If you want to provide the `armbian`
    and `hostconfig` directories as `.tar.xz` archives, you can set this to 0
    and provide said archives in `$(WRKROOT)/in`, e.g. `/var/tmp/in`. Also,
    there is no need to specify `$(MA_HOSTCONFIG)` if the hack is not used and
    the directories `armbian` and `hostconfig` need not be present separately.
`MA_HOSTCONFIG`
:   Contains a space-separated list of directories to compose a single
    `hostconfig` (files are added in order which means you can override files
    from a pervious hostconfig by creating a file in `myhostconfig` with
    the same name as in `hostconfig`).
`MA_IMAGEBUILD`
:   Set this to 1 to build an own docker image to do the processing. If it is 0,
    docker will attempt to pull the image
    `$(MA_IMAGEPREFIX)/bpi-build-armbian-debootstrap`
    from Docker Hub or other configured repositories.
`MA_IMAGEPREFIX`
:   Declare a prefix for the docker image to use. If you want to use an existing
    Ma_Sys.ma image, you can set this to `masysma`. For this case set
    `MA_IMAGEBUILD = 0`.
`WRKROOT`
:   A “working-root” directory for intermediate files. Chose a directory
    large enough to take about twice the size of your target image.

If you want to build a (boring) image with just SSH, Aptitude and VIM, you do
not need to provide a `myhostconfig` and can go with the sample settings
provided.

Having prepared as described, call the build as follows:

~~~
$ make MA_BS_CONF_PREFIX=my
~~~

If you chose not to provide an own `myconf.mk`, a simple `make` is enough. 

Make sure your microSD card is MBR formatted, the first partition has the
`ext4` file system, starts at sector 2048 and is large enough to take the
crated root filesystem. You can check this with `fdisk -l`. If you are using
the `fstab` supplied with the given `hostconfig`, you will also need to have a
second partition containing a swap area. There is no technical need for a swap
partition – if you do not want it, just copy the prepared `fstab` to
`myhostconfig/fsroot/etc/fstab` and remove the last line containing `swap`. 

Once the build has completed, you will find two files below `$(WRKROOT)/out`: 

`u-boot-sunxi-with-spl.bin.xz`
:   This is the bootsector for your microSD card. Apply it to a given microSD
    card as follows:
    `unxz < u-boot-sunxi-with-spl.bin.xz | dd of=/dev/sdj bs=1024 seek=8`
    where `/dev/sdj` is your microSD card device node.
`ext4_main.tar.xz`
:   This contains the root filesystem to be used. Extract it to a mountpoint
    where the first partition of your microSD card is mounted (e.g. `/mnt`) as
    follows: `tar -C /mnt -xpf ext4_main.tar.xz`.

Umount your microSD card, put it into the Banana Pi M2+EDU, connect the Banana
Pi M2+EDU to the eternet network and then power on the Banana Pi M2+EDU and be
patient for about 30 seconds. You should then see lights at the ethernet port.
If not wait a little longer and if nothing happens, something is wrong.  Such
issues are best debugged using the serial console, search the web for how to do
this.

If the startup succeeded and you left that part of the default `hostconfig`
intact, you might login at the Banana Pi M2+EDU using `ssh linux-fan@IP` with
password `testwort`. The IP address will be taken from DHCP – you may find out
about it using `nmap -sn NETWORK` where NETWORK is your network like e. g.
192.168.1.0/24.

Additional notes and hints

 * To delete intermediate results, call `make clean`. If you also want to remove
   the docker image used, use `make dist-clean` instead.
 * If you intend to change the build process, the main part of it is implemented
   in the Makefile `build_inside.mk` which is called from inside the container
   (but outside the target root filesystem).

Getting to run Docker on the Banana Pi M2+EDU
=============================================

In order to run Docker on the Banana Pi M2+EDU, create a directory, e..g.
`docker_arm` with these contents:

~~~
fsroot/usr/bin/docker
fsroot/usr/bin/docker-proxy
fsroot/usr/bin/docker-containerd
fsroot/usr/bin/dockerd
fsroot/usr/bin/docker-containerd-ctr
fsroot/usr/bin/docker-runc
fsroot/usr/bin/docker-containerd-shim
fsroot/lib/systemd/system/docker.service
fsroot/lib/systemd/system/docker.socket
postinst.d/10_setup_docker.sh
~~~

For `10_setup_docker.sh` you might want to use this:

	#!/bin/sh -e
	addgroup docker

The files for `docker.service` and `docker.socket` may be obtained from the
docker sources. The binaries for `/usr/bin` may be taken from the official
Docker downloads.

From the running system, it is then a matter of
`systemctl enable docker.service && systemctl start docker.service`
to get to run the docker daemon.

Further Ideas
=============

In the future, the system presented here should be incorporated into an MDVL
build process and customization should not be done using `fsroot` and
`postinst.d` but with Debian packages instead.

Also, tests of all the different variants should be performed and code to
enable newer kernels (which never worked) should be removed from the legacy
build system.

License
=======

The Ma_Sys.ma-contributed scripts to build Debian images for a Banana Pi M2+EDU
are licensed under GPLv3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
