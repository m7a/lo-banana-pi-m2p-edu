#!/bin/sh -e
# Ma_Sys.ma Script to generate images for Banana Pi M2+EDU based on Debian only,
# Copyright (c) 2020, 2025 Ma_Sys.ma <info@masysma.net>

scriptroot="$(cd "$(dirname "$0")" && pwd)"
# allows local ant build template to be used if present.
MDVL_CI_PHOENIX_ROOT="$(cd "$scriptroot/../.." && pwd)"
export MDVL_CI_PHOENIX_ROOT

wd="$scriptroot/wd"
tmp_port=9842
package_dir="$scriptroot/package"
debian_version=trixie
#mirror=http://ftp.de.debian.org/debian
mirror=http://192.168.128.1/debian
adddep="vim,aptitude,docker.io"

if [ "$1" = "--help" ]; then
	echo "Usage $0 [conf-script]"
	exit 0
fi

# shellcheck disable=SC1090
[ $# = 0 ] || . "$1" # load config if present

[ -d "$wd" ] || mkdir "$wd"

if ! [ -d "$wd/repo" ]; then
	echo "-- build package --"
	echo "package_dir=$package_dir"
	echo "logfile=$wd/package.txt"
	mkdir "$wd/repo"
	cp -r "$package_dir" "$wd/package"
	cd "$wd/package"
	ant package > "$wd/package.txt" 2>&1
	mv "$wd"/*.deb "$wd/repo"
	echo
fi

echo "-- assemble package list --"
pkgfilelist="${pkgfilelist:-}"
for i in "$wd/repo"/*.deb; do
	if [ -f "$i" ]; then
		pkgfilelist="$pkgfilelist --include=$i"
	fi
done
echo "pkgfilelist=$pkgfilelist"
echo

echo "-- calling mmdebstrap --"
echo "logfile=$wd/mmdebstrap.txt"
# NOTE - If you get “apt download failed: E: apt-get --yes -oDebug::pkgDpkgPm=1 -oDir::Log=/dev/null -oAPT::Keep-Fds::=14 -oDPkg::Tools::options::'cat >&14'::InfoFD=14 -oDpkg::Pre-Install-Pkgs::=cat >&14 -oDebug::NoLocking=1 -oDpkg::Use-Pty=0 -oDPkg::Chroot-Directory= install ?narrow(?or(?archive(^stable$),?codename(^stable$)),?architecture(amd64),?essential) -oAPT::Status-Fd=<$fd> -oDpkg::Use-Pty=false failed: process exited with 100 and error in console output” - run it with sudo...
if mmdebstrap --architectures=armhf --components=main,contrib,non-free \
		--hook-dir=/usr/share/mmdebstrap/hooks/file-mirror-automount \
		--verbose --variant=important $pkgfilelist "--include=$adddep" \
		--mode=unshare "$debian_version" "$wd/fsroot.tar" "$mirror"
then
	echo image generation completed successfully.
else
	echo image generation FAILED. Check the logs for details. \
		The image may not be bootable.
	exit 1
fi
