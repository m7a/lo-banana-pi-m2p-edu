---
x-masysma-name: banana_pi_m2_plus_edu
section: 37
title: Banana Pi M2+EDU Resources
keywords: ["kb", "bananapi", "arm", "debian", "m2p", "blog", "bpi"]
lang: en-US
date: 2017/03/31 16:21:44
x-masysma-version: 1.0.4
x-masysma-copyright: |
  Copyright (c) 2017, 2018, 2020 Ma_Sys.ma.
  For furhter info send an e-mail to Ma_Sys.ma@web.de.
x-masysma-repository: https://www.github.com/m7a/lo-banana-pi-m2p-edu
x-masysma-website: https://masysma.lima-city.de/37/banana_pi_m2_plus_edu.xhtml
x-masysma-owned: 1
---
Introduction: Debian on the Banana Pi M2+EDU
============================================

The Banana Pi M2+EDU is a cheap ARM board supporting Gigabit Ethernet. This
article describes means of getting to run Debian on the Banana Pi M2+EDU.

The approach presented here tries to get an installation as close to an
_unmodified_ Debian as possible. In the past, this did not seem possible and
thus, some minor deviations were accepted.

Overview
========

This document describes three distinct approaches:

 1. A new approach to use Debian with only minimal external sources.
    The solution proposed here does not involve the Debian installer, but
    relies on bootstrapping an image suitable to be copied onto a MicroSD
    card which can then boot on the board.
 2. An old approach which involved the combination of a regular Debian with
    u-boot and kernel taken from the armbian project. This approach should
    still work, but makes upgrading the kernel and OS difficult.
 3. An old approach using the vendor-supplied kernel. This is by far the
    tecnically “worst” variant, but it allows making use of some hardware
    features which are not available by using the other approaches.

Note that both “old” approaches are accompanied by scripts whose (integrated
or documented) download links may no longer work due to external updates. At
least for the armbian-based approach it should be simple enough to adapt them.
If you find updated links which work, feel free to send me an e-mail such that
I can correct the description here, too.

Useful online resources
=======================

Information on how to work with this single board computer is scattered
around several sites. The following attempts to collect some useful links:

 * [Basic u-boot configuration hints](https://www.get-edi.io/Booting-Debian-with-U-Boot/)
 * Linux-Sunxi u-boot configuration: [Mainline U-Boot Howto](https://linux-sunxi.org/Mainline_U-Boot)
 * [InstallingDebianOn/Allwinner](https://wiki.debian.org/InstallingDebianOn/Allwinner)

Introduction to the new approaches
==================================

The “new approach” relies solely on data provided through Debian. This allows
for a very stable result and enables the maximum benefits which usually come
with a Debian system: Easy upgrades between releases, security fixes etc.

The scripts for this approach are found in directory `new_debian_only` and
are intended to be invoked “in sequence“ as numbered. Build operations take
place on a Debian host system (which need not be armhf) and rely on certain
Debian packages to be present. By instantiating `mmdebstrap`, large part of
the process runs without the need for `root` permissions if
`unprivileged_userns_clone` is set to 1 (as performed by `s0_open_userns.sh`).

All data is accumulated in a working directory `wd` which the user may delete
after the build. In order to only rely on the “stable” featureset of
`mmdebstrap`, all customizazion needs to happen through custom packages. An
example for such a package (whose dependencies your own customizazion should
always include!) is supplied in directory `package-sample`. If you are fine
with the configuration it provides, you can also try using it without
modifications.

New: Debian with minimal external sources
=========================================

Result
:   Produces an image containing an OS as close to a “proper” Debian as
    possible. Aside from the scripts provided here, only one non-Debian
    component is used: The `u-boot-sunxi-with-spl.bin` is still
    taken from armbian.

This new approach consists of three major stages:

 1. Preparation
 2. Building of a root filesystem
 3. Copying to the MicroSD card

As parts of the steps need to run as root whereas others can run as a regular
user, the scripts are divided into the following individual files:

Dependencies
:   The scripts have been tested to run on Debian stable (Debian Buster) and
    require (at least) the following dependencies:
    `ant`, `mmdebstrap`, `reprepro`, `python3`, `sfdisk`.

`s0_open_userns.sh` (as root)
:   Invokes `sysctl -w kernel.unprivileged_userns_clone=1` to allow the
    next step to work without being root.

If necessary, add your user to `/etc/subuid` and `/etc/subgid` if there is no
entry for it yet. In my case, the following line had to be added to both files
on one machine, but not on another:

	linux-fan:689824:65536

See <https://help.ubuntu.com/lts/serverguide/lxc.html#lxc-basic-usage>
(section _User namespaces_) for details.

`s1_generate.sh` (as user)
:   Performs most of the preparation and builds a root filesystem in
    output file `wd/fsroot.tar`. To set different variables (e.g. configure
    mirror or Debian version, you can pass a script file as parameter which
    is being sourced. See _Customization Variables_ below.
`s2_write_to_disk.sh` (as root)
:   Writes the prepared files to a MicroSD card. Note that in case you do not
    want to rely on the automatism, it is perfectly reasonable to do the step
    “by hand”. See the source code or the old instructions for
    _Debian + armbian Kernel_ for ideas on how to do this.
`s3_close_userns.sh`
:   Reverts the setting performed in `s0`. It is a separate step to permit
    skipping or delaying the actual `s2_write_to_disk.sh`. For maximum security,
    execute this script directly after `s1_generate.sh`.

## Common Points of Failure

 * Invalid root filesystem generated.
   In this case, carefully check if the custimization is correct and has been
   applied (e.g. by checking the image's contents for customized files)
 * Invalid boot loader configuration.
   This is one of the hardest issues to debug properly and took most of the
   scripts' development time. In case something is wrong with the bootloader
   stage, two major directions can be checked:
   (1) is the `u-boot-sunxi-with-spl.bin` correct?
   One cannot really know, but (new) good u-boot binaries will show bootloader
   output on HDMI.
   (2) is the `boot.cmd` (and from that: `boot.scr`) correct?
   It is quite hard to get this file right and one can still foreget to
   re-generate `boot.scr` afterwards (hint: put an echo with a changing version
   number in there and check if it occurs on-screen).
   Note that message `Starting kernel...` without further progress can
   be caused by either (1) or (2)!

In any case, the method of debugging should be to try out different things and
if they fail, attempt to “revert“ to a known good configuration.

## Customization Variables

Relevant customization variables are as follows (defaults given behind `=`)

`wd="$scriptroot/wd"`
:   Specifies a “working directory“. This needs to have enough free space to
    take all parts of the result image and should thus be reasonably large
    (e.g. 3 GiB). It is recommended to follow the default. If not, the same
    variable is also defined in `s2_write_to_disk.sh` and needs to be changed
    as well.
`tmp_port=9842`
:   In order to supply a custom package to `mmdebstrap`, it is served from a
    temporary repository using a temporarily running webserver (that's the
    `python3` dependency by the way). This needs a free port on the host machine
    (the webserver will only listen on the loopback interface). Most likely,
    the default is OK here.
`debian_version=buster`
:   Configures the Debian release to use.
`package_dir="$scriptroot/package"`
:   Gives a directory to build the customization package from.
    Note: This is expected to contain MDPC 2.0/ant-based instructions to
    build a package called `mdvl-banana-pi-m2-plus-edu-root`. It is recommended
    to duplicate the existing `package` and change the copy in case an own
    customization package is needed.
`mirror=http://ftp.it.debian.org/debian`
:   Configures the Debian mirror to use. Security will always point to
    `security.debian.org`.
`adddep=,vim,aptitude,openssh-server,docker.io`
:   A list of packages (comma-separated, without spaces, starting with a leading
    comma) to install in addition to `mdvl-bamana-pi-m2-plus-edu-root`.
`add_sources_list_line=`
:   Configures an additional mirror to use. Together with `adddep`, this allows
    arbitrarily customized packages to be input into the filesystem root
    generation process.

## Customization Package

The customization package needs to take care that instead of only a “chroot“,
the build procedure arrives at a bootable root filesystem. It thus needs to
depend on kernel and other essential tools for running systems. Additionally,
this package is responsible for providing essential configuration files like
`/etc/network/interfaces` or `/etc/fstab`.

The supplied `package` directory contains the instructions for a package
which creates an user `linux-fan` and sets passwords for `root` and `linux-fan`
to `testwort`. It is recommended to change the passwords _after_ the package has
set them because if one relies on the package for productive passwords,
`linux-fan` can read `root`'s password from the DPKG status files (i.e. the
`postinst` script is readable by all users...).

Introduction to the old approaches
==================================

The “old approaches“ rely on a combination of Docker images and Makefiles. This
allows the build process to be parallelized and should run on non-Debian host
systems as well. On the downside, it is not always exactly obvious where the
actual commands are stored. The documentation for the respective approaches
still intends to shed some light on this.

At the time of the creation of the “old” approaches, these solutions existed
for Debian on a Banana Pi M2+EDU:

 * Debian-Images from the
   [official Banana Pi website](http://www.banana-pi.org/m2plus-download.html):
   These images are larger than necessary and only available with old kernels.
   Also, it is a bit unclear how those images can be created/customized.
 * [armbian](https://www.armbian.com/banana-pi-m2-plus/):
   These images are of good quality and best if you want an image optimized for
   the ARM platform. They are, however, heavily customized and as of this
   writing, there is no Debian + recent Kernel combination offered.

If one is looking for an easy solution, the armbian-Images can be recommended.
The following sections present an approach which comes closer to an unmodified
Debian and allows maximum control over the packages present in the image.

All of the approaches presented here, as well as the armbian images, work with
microSD cards of any size (tested for 128 GB). Customizazion happens by
supplying files in subdirectory `hostconfig` -- either in form of scripts or in
form of files which are being copied to the target image.

## Kernel Upgrading

One of the tricky parts around bootloader configuration is the handling of
kernel upgrades. Despite repeated attempts, no way of specifying the initramfs
in its regular form (`initrd.img`) was found. Instead, this image needs to be
converted to be usable by u-boot (`uInitrd`). To do this automatically upon
kernel upgrades, script `y-masysma-gen-uboot-files` is supplied as part of the
customization package. It attempts to automatically generate all boot-related
files upon kernel upgrades (and initially). Noteworthy files are:

 * `/boot/uInitrd-KERNEL` generated from `/boot/initrd.img-KERNEL` by `mkimage`
 * `/boot/boot.cmd` generated from `/etc/masysma_template_boot.cmd`
   (a known working configuration found through trial-and-error)
 * `/boot/boot.scr` generated from `/boot/boot.cmd` by `mkimage`.

Old: Combination Debian + Armbian Kernel
========================================

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

External Resources (Debian Jessie)

 * `boot.bmp`
 * `linux-dtb-dev-sun8i_5.26_armhf.deb`
 * `linux-firmware-image-dev-sun8i_5.26_armhf.deb`
 * `linux-headers-dev-sun8i_5.26_armhf.deb`
 * `linux-image-dev-sun8i_5.26_armhf.deb`
 * `linux-u-boot-dev-bananapim2plus_5.25_armhf.deb`
 * `linux-xenial-root-dev-bananapim2plus_5.25_armhf.deb`

External Ressources (Debian Stretch)

 * [`boot.bmp`](https://raw.githubusercontent.com/armbian/build/master/packages/blobs/splash/armbian-universal.bmp)
 * [`linux-dtb-next-sunxi_5.70_armhf.deb`](https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-dtb-next-sunxi_5.70_armhf.deb)
 * [`linux-headers-next-sunxi_5.70_armhf.deb`](https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-headers-next-sunxi_5.70_armhf.deb)
 * [`linux-image-next-sunxi_5.70_armhf.deb`](https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-image-next-sunxi_5.70_armhf.deb)
 * [`linux-u-boot-dev-bananapim2plus_5.70_armhf.deb`](https://apt.armbian.com/pool/main/l/linux-u-boot-bananapim2plus-dev/linux-u-boot-dev-bananapim2plus_5.70_armhf.deb)
 * [`linux-xenial-root-bananapim2plus_5.73_armhf.deb`](https://apt.armbian.com/pool/main/l/linux-xenial-root-bananapim2plus/linux-xenial-root-bananapim2plus_5.73_armhf.deb)

Obtain the files listed. In case the links do not work, remove the
version-specific parts and search for similar files. Other versions might also
work but have not been tested. If you want to use the hack for direct invocation
(the system is also prepared to perform fully-automatic processing), provide the
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

Old: Debian + Vendor-Supplied legacy Kernel
===========================================

Files or this approach can be found in directory `legacy_kernel`.
_Note that these scripts have not been tested after their development in
2017 again. It is unclear, if anything from this still works._

Result
:   This approach produces an image suited for a microSD card which contains a
    Debian installation equipped with the officially supplied Banana Pi M2+
    kernel. This supports HDMI and Gigabit Ethernet but is based on a kernel
    3.4.39 and thus e.g. too old to run Docker.

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

Old: Getting to run Docker on the Banana Pi M2+EDU
==================================================

From 2020 and onwards, this should no longer be necessary. Now-stable Debian
Buster provides docker.io packages which can be installed through apt. Hence
there is no need to provide Docker through separate files.

In order to run Docker on the Banana Pi M2+EDU, create a directory, e.g.
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
