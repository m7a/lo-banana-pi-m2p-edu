#!/bin/sh -e

# USE THESE NOTES INSTEAD OF THE COMPLEX THINGS BELOW AND TRY TO GET IT TO RUN WITH ONLY ONE debian:7 docker container or such?
# (no external things needed...)
# -> https://github.com/BPI-SINOVOIP/BPI-M2P-bsp
#sudo dd if=boot0_sdcard.fex     of=${card} bs=1k seek=8
#sudo dd if=u-boot.fex           of=${card} bs=1k seek=16400
#sudo dd if=sunxi_mbr.fex    of=${card} bs=1k seek=20480
#sudo dd if=boot-resource.fex    of=${card} bs=1k seek=36864
#sudo dd if=env.fex          of=${card} bs=1k seek=69632

# SD/bpi-m2p/3.4.39-BPI-M2P-Kernelt.gz (contains a lib directory)
# SD/bpi-m2p/BOOTLOADER-bpi-m2p.tgz (constains usr/lib structure)
# SD/bpi-m2p/BPI-BOOT-bpi-m2p.tgz (bananapi/bpi-m2p/linux/* -> FAT32)

# output/BPI-M2P-720P/pack w/ .fex files

workdir=/fs/vmstor

case "$1" in
(1)
	exec aptitude install build-essential libncurses5-dev u-boot-tools \
			qemu-user-static debootstrap git binfmt-support \
			libusb-1.0-0-dev pkg-config gcc-arm-linux-gnueabihf;;
(2)
	exec tar -C "$workdir" -xf /data/programs/images/bpi-sinovoip.tar.xz;;
(3_1)
	cd bpi-build
	exec docker build -t masysmalocal/bpibuild .;;
(3_2)
	exec docker run --rm -it -v /fs/vmstor:/fs/vmstor \
		-v "$HOME/pmnt/sshfs/buildsys:/fs/buildsys" \
		masysmalocal/bpibuild /bin/bash;;
(3)
	cp -r "$workdir/bpi-sinovoip/BPI-Mainline-kernel" \
				"$workdir/bpi-sinovoip/BPI-M2P-bsp/kernel"
	cp -r "$workdir/bpi-sinovoip/BPI-Mainline-uboot" \
				"$workdir/bpi-sinovoip/BPI-M2P-bsp/u-boot"
	;;
(4)
	cd "$workdir/bpi-sinovoip/BPI-M2P-bsp"
	./build.sh BPI-M2P-720P
	;;
(5)
	echo Need FAT32 partition sz 50MB @100MB offset and ext4 partition and swap if wanted;;
(6)
	echo Copy to FAT: $workdir/bpi-sinovoip/BPI-M2P-bsp/SD/bpi-m2p/BPI-BOOT/bananapi/bpi-m2p/linux/*
	# uImage, uEnv.txt, + 2others
	;;
(6)
	echo Outside container run 7;;
(7)
	exec docker run --privileged --rm -it -v /fs/vmstor:/fs/vmstor \
		-v "$HOME/pmnt/sshfs/buildsys:/fs/buildsys" debian:8 /bin/bash;;
(8)
	apt update
	echo INSTALL qemu-user-static IN THE OUTSIDE SYSTEM OR VM
	apt -y install debootstrap qemu-user-static
	mkdir "$workdir/rootfs"
	exec debootstrap --arch=armhf --foreign jessie "$workdir/rootfs";;
(9)
	exec cp /usr/bin/qemu-arm-static "$workdir/rootfs/usr/bin/";;
(9_2)
	exec chroot "$workdir/rootfs" /debootstrap/debootstrap --second-stage;;
	# (optional) switch back
(10)
	cp -R \
	"$workdir/bpi-sinovoip/BPI-M2P-bsp/SD/bpi-m2p/BPI-ROOT/lib/modules"/* \
								"/mnt/lib";;
(11)
	echo Copy to ext4: $workdir/rootfs;;
(12)
	echo dd if=$workdir/bpi-sinovoip/BPI-M2P-bsp/u-boot-sunxi/u-boot.bin of=/dev/sdX1 bs=1024 seek=8
	echo "alt. cf. guide for individual files. .fex files below output/BPI-M2P-720P/pack (boot.fex is missing)"
	echo aalt. go to $workdir/bpi-sinovoip/BPI-Mainline-uboot, ./bpi-m2.sh and then dd out/bpi-m2/u-boot-sunxi-with-spl.bin to the device instead.
	;;
(*)
	echo Usage $0 1--3;;
esac
