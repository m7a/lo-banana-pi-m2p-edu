#!/bin/sh -ex
wget -Oboot.bmp https://raw.githubusercontent.com/armbian/build/master/packages/blobs/splash/armbian-universal.bmp
wget https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-dtb-next-sunxi_5.70_armhf.deb
wget https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-headers-next-sunxi_5.70_armhf.deb
wget https://apt.armbian.com/pool/main/l/linux-4.19.13-sunxi/linux-image-next-sunxi_5.70_armhf.deb
wget https://apt.armbian.com/pool/main/l/linux-u-boot-bananapim2plus-dev/linux-u-boot-dev-bananapim2plus_5.70_armhf.deb
wget https://apt.armbian.com/pool/main/l/linux-xenial-root-bananapim2plus/linux-xenial-root-bananapim2plus_5.73_armhf.deb
