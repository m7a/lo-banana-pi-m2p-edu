#!/bin/sh -e
# Ma_Sys.ma Script to generate images for Banana Pi M2+EDU based on Debian only,
# Copyright (c) 2020 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

scriptroot="$(cd "$(dirname "$0")" && pwd)"
# allows local ant build template to be used if present.
MDVL_CI_PHOENIX_ROOT="$(cd "$scriptroot/../.." && pwd)"
export MDVL_CI_PHOENIX_ROOT

wd="$scriptroot/wd"
tmp_port=9842
package_dir="$scriptroot/package"
debian_version=buster
#mirror=http://ftp.it.debian.org/debian
mirror=http://192.168.1.16/debian
adddep=",vim,aptitude,openssh-server,docker.io"
add_sources_list_line=

if [ "$1" = "--help" ]; then
	echo "Usage $0 [conf-script]"
	exit 0
fi

# shellcheck disable=SC1090
[ $# = 0 ] || . "$1" # load config if present

[ -d "$wd" ] || mkdir "$wd"

if ! [ -f "$wd/u-boot-sunxi-with-spl.bin" ]; then
	echo "-- download u-boot --"
	echo "logfile=$wd/download-uboot-armbian.txt"
	cp -r "$scriptroot/download-uboot-armbian" "$wd"
	cd "$wd/download-uboot-armbian"
	ant download > "$wd/download-uboot-armbian.txt" 2>&1
	ubootsplbin="$(find "$wd/download-uboot-armbian" -type f \
					-name u-boot-sunxi-with-spl.bin)"
	mv "$ubootsplbin" "$wd"
	ant dist-clean >> "$wd/download-uboot-armbian.txt" 2>&1
	echo
fi

if ! [ -d "$wd/repo/conf" ]; then
	echo "-- build package --"
	echo "package_dir=$package_dir"
	echo "logfile=$wd/package.txt"
	cp -r "$package_dir" "$wd/package"
	cd "$wd/package"
	ant package > "$wd/package.txt" 2>&1
	echo
fi

echo "-- generating repository --"
mkdir -p "$wd/repo/conf"
cat > "$wd/repo/conf/distributions" <<EOF
Origin: Linux-Fan, Ma_Sys.ma
Label: MDVL_TEMP
Suite: stable
Codename: squeeze
Version: 6.0.6
Architectures: armhf source
SignWith: yes
Components: main non-free contrib
Description: Temporary MDVL repository. $(date)
EOF

if ! [ "$(echo "$wd"/*.deb)" = "$wd/*.deb" ]; then
	reprepro -A armhf -b "$wd/repo" includedeb squeeze "$wd"/*.deb
	rm "$wd"/*.deb
fi
echo

echo "-- starting local repository server --"
cd "$wd/repo"
python3 -m http.server --bind 127.0.0.1 "$tmp_port" &
pypid=$!
echo "pypid=$pypid"
# shellcheck disable=SC2064
trap "kill -s TERM $pypid" INT TERM EXIT
echo

echo "-- calling mmdebstrap --"
mmdebstrap --architectures=armhf --components=main,contrib,non-free \
	--variant=important \
	"--include=mdvl-banana-pi-m2-plus-edu-root$adddep" \
	--mode=unshare \
	> "$wd/fsroot.tar" <<EOF
deb $mirror $debian_version main contrib non-free
deb $mirror $debian_version-updates main contrib non-free
deb http://security.debian.org/ buster/updates main contrib non-free
deb http://127.0.0.1:$tmp_port/ squeeze main contrib non-free
$add_sources_list_line
EOF
