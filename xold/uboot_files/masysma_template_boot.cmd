echo Ma_Sys.ma boot.cmd is running for kernel 4.19.0-8-armmp-lpae...
setenv load_addr 0x44000000
echo Ma_Sys.ma boot.cmd root=/dev/mmcblk0p1
setenv bootargs root=/dev/mmcblk0p1 rootwait console=tty1 consoleblank=0
load mmc 0:1 ${ramdisk_addr_r} /boot/uInitrd-4.19.0-8-armmp-lpae
load mmc 0:1 ${kernel_addr_r} /boot/vmlinuz-4.19.0-8-armmp-lpae
load mmc 0:1 ${fdt_addr_r} /usr/lib/linux-image-4.19.0-8-armmp-lpae/${fdtfile}
fdt addr ${fdt_addr_r}
fdt resize 65536
echo Ma_Sys.ma boot.cmd invoking kernel with bootz...
bootz ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
