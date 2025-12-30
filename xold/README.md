!!! OBSOLETE !!!
================

_All subdirectories in this tree are obsolete._
Newer instructions exist.
Please check the instructions one level up.

This file collects the old notes if for whatever reason it would later be
necessary to revisit the old stuff.

Directories starting with `masysma12` incorporate some old machine-specific
scripts which could be used before or alongside the old approaches. They are
obsolete, too...

2025-12-30 <info@masysma.net>

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
   [official Banana Pi website](http://wiki.banana-pi.org/Banana_Pi_BPI-M2%2B#Image_Release):
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

	git clone https://github.com/m7a/lo-banana-pi-m2p-edu

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

	git clone https://github.com/m7a/lo-banana-pi-m2p-edu

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
