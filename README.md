---
x-masysma-name: banana_pi_m2_plus_edu
section: 37
title: Banana Pi M2+EDU Resources (revised for 2026)
keywords: ["kb", "bananapi", "arm", "debian", "m2p", "blog", "bpi"]
lang: en-US
date: 2017/03/31 16:21:44
author: ["Linux-Fan, Ma_Sys.ma (Ma_Sys.ma@web.de)"]
x-masysma-version: 2.0
x-masysma-copyright: (c) 2017, 2018, 2020, 2025 Ma_Sys.ma <info@masysma.net>
x-masysma-repository: https://www.github.com/m7a/lo-banana-pi-m2p-edu
x-masysma-website: https://masysma.net/37/banana_pi_m2_plus_edu.xhtml
x-masysma-owned: 1
---
Introduction: Debian on the Banana Pi M2+EDU
============================================

The Banana Pi M2+EDU is a cheap ARM board supporting Gigabit Ethernet. This
article describes means of getting to run Debian on the Banana Pi M2+EDU.

The approach presented here tries to get an installation as close to an
_unmodified_ Debian as possible. In the past, this did not seem possible and
thus, some minor deviations were accepted.

The approach described here was initially written down in 2017 and has most
recently been validated with Debian 13 Trixie (per 2025-12-29).

Useful online resources
=======================

Information on how to work with this single board computer is scattered
around several sites. The following attempts to collect some useful links:

 * [Basic u-boot configuration hints](https://www.get-edi.io/Booting-Debian-with-U-Boot/)
 * Linux-Sunxi u-boot configuration:
   [Mainline U-Boot Howto](https://linux-sunxi.org/Mainline_U-Boot)

Mailing list questions:

 * [Getting Started](https://lists.debian.org/debian-user/2020/02/msg00597.html)
 * [Towards Debian-only Solution](https://alioth-lists.debian.net/pipermail/blend-tinker-devel/2020-February/000024.html)

Wiki Entries:

 * [Installing Debian on Allwinner](https://wiki.debian.org/InstallingDebianOn/Allwinner)
 * [Installing Debian on Allwinner H3](https://wiki.debian.org/InstallingDebianOn/Allwinner/H3)

Introduction to the new approaches
==================================

The “new approach” relies solely on data provided by Debian. This allows for a
very stable result and enables the maximum benefits which usually come with a
Debian system: Easy upgrades between releases, security fixes etc.

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

New: Debian without external sources
====================================

Result
:   Produces an image containing a “proper” Debian. Aside from the scripts
    provided here, only a Debian mirror and host system are needed.

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
:   Builds a root filesystem in output file `wd/fsroot.tar`. To set different
    variables (e.g. configure mirror or Debian version, you can pass a script
    file as parameter which is being sourced. See section
    _Customization Variables_ for details.
`s2_write_to_disk.sh` (as root)
:   Writes the prepared files to a MicroSD card and updates the bootloader.
`s3_close_userns.sh`
:   Reverts the setting performed in `s0`. It is a separate step to permit
    skipping or delaying the actual `s2_write_to_disk.sh`. For maximum security,
    execute this script directly after `s1_generate.sh`.

## Common Points of Failure

 * Rootfs generation fails with the following message:
   `apt download failed: E: apt-get --yes -oDebug::pkgDpkgPm=1 -oDir::Log=/dev/null -oAPT::Keep-Fds::=14 -oDPkg::Tools::options::'cat >&14'::InfoFD=14 -oDpkg::Pre-Install-Pkgs::=cat >&14 -oDebug::NoLocking=1 -oDpkg::Use-Pty=0 -oDPkg::Chroot-Directory= install ?narrow(?or(?archive(^stable$),?codename(^stable$)),?architecture(amd64),?essential) -oAPT::Status-Fd=<$fd> -oDpkg::Use-Pty=false failed: process exited with 100 and error in console output`
   This means to tell that mmdebstrap could not run successfully.
   The known workaround is to run this step as root (e.g. by adding a sudo
   invocation in front of `mmdebstrap` in `s1_generate.sh`)

 * Invalid root filesystem generated.
   In this case, carefully check if the custimization is correct and has been
   applied (e.g. by checking the image's contents for the presence of
   customized files)

 * Invalid boot loader configuration.
   This is one of the hardest issues to debug properly and took most of the
   scripts' development time. In case something is wrong with the bootloader
   stage, two major directions can be checked:
   (1) is the `u-boot-sunxi-with-spl.bin` correct?
   One cannot really know, but (new) good u-boot binaries will show bootloader
   output on HDMI.
   (2) is the bootloader configuration correct?
   It is quite hard to get configuration right manually. However, Debian package
   `u-boot-menu` provides an automatism which can be invoked by
   `/usr/sbin/u-boot-update` to generate a configuration
   `/boot/extlinux/extlinux.conf` which (despite its name) can be processed by
   u-boot. The first step is to check the file's existence and if it contains
   proper `UUID` of the microSD card's first partition.
   Note that message `Starting kernel...` without further progress can
   be caused by either (1) or (2)!

## Customization Variables

Relevant customization variables are as follows (defaults given behind `=`)

`wd="$scriptroot/wd"`
:   Specifies a “working directory“. This needs to have enough free space to
    take all parts of the result image and should thus be reasonably large
    (e.g. 3 GiB). It is recommended to follow the default. If not, the same
    variable is also defined in `s2_write_to_disk.sh` and needs to be changed
    as well.
`debian_version=trixie`
:   Configures the Debian release to use.
`package_dir="$scriptroot/package"`
:   Gives a directory to build the customization package from.
    Note: This is expected to contain MDPC 2.0/ant-based instructions to
    build a package called `mdvl-banana-pi-m2-plus-edu-root`. It is recommended
    to duplicate the existing `package` and change the copy in case an own
    customization package is needed.
`mirror=http://ftp.de.debian.org/debian`
:   Configures the Debian mirror to use.
`adddep=vim,aptitude,docker.io`
:   A list of packages (comma-separated, without spaces) to install in addition
    to `mdvl-bamana-pi-m2-plus-edu-root`.

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
`linux-fan` can read `root`'s password from the DPKG status files as the
`postinst` script is readable by all users...

## Technical Details

While `s0_open_userns.sh` and `s3_close_userns.sh` are reasonably “trivial”,
the other two scripts might not be as easy to understand. The script's content
is summarized in bullet points in the following as to serve as a means to
create your own scripts or understand the existing ones better:

### `s1_generate.sh`

 * Obtain configuration values: working directory, port, version, mirror,
   additional packages and package sources to install
 * Create package from directory `package` (using MDPC 2.0, see
   [masysmaci/build(32)](../32/masysmaci_build.xhtml) for details).
 * Invoke `mmdebstrap` to generate a root filesystem `fsroot.tar`
   with the generated package installed. By installing the generated package,
   dependencies are pulled in and default users and passwords are created.
 * Also, this ensures that `/etc/default/u-boot` is populated with the following
   setting: `U_BOOT_FDT=sun8i-h3-bananapi-m2-plus.dtb` - the use of the
   correct device tree is essential to have features like USB work in the
   installed system.

### `s2_write_to_disk.sh`

 * detect device size and set 1 GiB of swap space and the remainder for the
   root filesystem.
 * create a suitable partition table with `sfdisk` leaving the first MiB free
   for the bootloader
 * detect partition device files
 * format partitions with defined UUIDs and generate a suitable `fstab`
 * mount the formatted root filesystem
 * extract generated `fsroot.tar` to the root filesystem
 * extract `u-boot-sunxi-with-spl.bin` from the root filesystem.
   The file is provied by package `u-boot-sunxi` for Orange Pi Plus which is
   close enough to run on Banana PI M2+EDU if combined with the correct device
   tree (`sun8i-h3-bananapi-m2-plus.dtb`, see S1).
 * copy the newly generated `fstab` to `/etc/fstab`
 * re-generate bootloader configuration to make the boot process aware of the
   UUIDs to use.
 * umount root filesystem
 * install the extracted `u-boot-sunxi-with-spl.bin` to the device

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
