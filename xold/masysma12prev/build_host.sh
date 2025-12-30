#!/bin/sh -e

wrkroot=/fs/vmstor

case "$1" in
(all1)
	"$0" prepare_wrkroot
	"$0" establish_directories
	
	"$0" sub_p1 & p1=$!
	"$0" sub_p2 & p2=$!
	"$0" sub_p3 & p3=$!
	
	for i in $p1 $p2 $p3; do
		rc=0
		wait $i || rc=$?
		if [ "$rc" != 0 ] && [ "$rc" != 127 ]; then
			echo "[M1] Subprocess failure: $i failed w/ $rc"
			exit $rc
		fi
	done

	"$0" sub_p6 & p6=$!
	"$0" sub_p7 & p7=$!

	for i in $p6 $p7; do
		rc=0
		wait $i || rc=$?
		if [ "$rc" != 0 ] && [ "$rc" != 127 ]; then
			echo "[M2] Subprocess failure: $i failed w/ $rc"
			exit $rc
		fi
	done

	"$0" sub_p8 & p8=$!
	"$0" sub_p9 & p9=$!

	for i in $p8 $p9; do
		rc=0
		wait $i || rc=$?
		if [ "$rc" != 0 ] && [ "$rc" != 127 ]; then
			echo "[M3] Subprocess failure: $i failed w/ $rc"
			exit $rc
		fi
	done

	echo "[M4] Use files from $wrkroot/out as per README.txt";;
(sub_p1)
	"$0" build_image_1 2>&1 | tee "$wrkroot/out/log1.txt" | \
							sed "s/^/[I1:1:$$] /g"
	"$0" run_build_1 2>&1 | tee -a "$wrkroot/out/log1.txt" | \
							sed "s/^/[I1:2:$$] /g";;
(sub_p2)
	"$0" build_image_2 2>&1 | tee "$wrkroot/out/log2.txt" | \
							sed "s/^/[I2:1:$$] /g"
	"$0" run_build_2 2>&1 | tee -a "$wrkroot/out/log2.txt" | \
							sed "s/^/[I2:2:$$] /g";;
(sub_p3)
	"$0" build_image_3 2>&1 | tee "$wrkroot/out/log3.txt" | \
							sed "s/^/[I3: :$$] /g";;
(sub_p6)
	"$0" run_build_3 2>&1 | tee "$wrkroot/out/log4.txt" | \
							sed "s/^/[I4:1:$$] /g";;
(sub_p7)
	"$0" run_mv 2>&1 | tee "$wrkroot/out/log5.txt" | \
							sed "s/^/[I4:2:$$] /g";;
(sub_p8)
	"$0" run_clean 2>&1 | tee "$wrkroot/out/log6.txt" | \
							sed "s/^/[I5:1:$$] /g";;
(sub_p9)
	"$0" clean_img 2>&1 | tee "$wrkroot/out/log7.txt" | \
							sed "s/^/[I5:2:$$] /g";;
(prepare_wrkroot)
	mkdir -p "$wrkroot/in"
	scp linux-fan@192.168.1.16:/data/programs/images/BPI-M2P-bsp.tar.xz \
								"$wrkroot/in";;
(establish_directories)
	if [ ! -d "$wrkroot/in" ]; then
		echo Need $wrkroot/in first.
		exit 1
	fi
	mkdir -p "$wrkroot/tmp_1" "$wrkroot/tmp_2" \
			"$wrkroot/out_1" "$wrkroot/out_2" "$wrkroot/out";;
# May run in parallel
(build_image_1)
	cd build_1_kernel_boot
	exec docker build -t masysmalocal/bpi-build-1-kernel-boot-img .;;
(build_image_2)
	cd build_2_debootstrap
	exec docker build -t masysmalocal/bpi-build-2-debootstrap .;;
(build_image_3)
	cd build_3_join
	exec docker build -t masysmalocal/bpi-build-3-join .;;
# May run in parallel
(run_build_1)
	# ...making tmp visible is optional (also for 2 and 3)...
	exec docker run --rm -v "$wrkroot/in:/fs/ccnt_b1kb/in:ro" \
				-v "$wrkroot/tmp_1:/fs/ccnt_b1kb/tmp" \
				-v "$wrkroot/out_1:/fs/ccnt_b1kb/out" \
				masysmalocal/bpi-build-1-kernel-boot-img;;
(run_build_2)
	# privileged is for mounting proc in the chroot.
	# The only alternative to be thought of involves giving proc as a docker
	# volume and that might be even more problematic...
	pwa="$(cd "$(dirname "$0")" && pwd)"
	exec docker run --privileged --rm \
			-v "$pwa/hostconfig:/fs/ccnt_b2db/in/hostconfig:ro" \
			-v "$wrkroot/tmp_2:/fs/ccnt_b2db/tmp" \
			-v "$wrkroot/out_2:/fs/ccnt_b2db/out" \
			masysmalocal/bpi-build-2-debootstrap;;
# After run_build_1 and run_build_2 (may run in parallel)
(run_build_3)
	map1="out_1/ext4_patch.tar.xz:/fs/ccnt_b3jo/in/ext4_patch.tar.xz"
	map2="out_2/ext4_main.tar.xz:/fs/ccnt_b3jo/in/ext4_main.tar.xz"
	exec docker run --rm -v "$wrkroot/$map1" -v "$wrkroot/$map2" \
			-v "$wrkroot/out:/fs/ccnt_b3jo/out" \
			masysmalocal/bpi-build-3-join;;
(run_mv)
	cp "$wrkroot/out_1/make_bootable.tar.xz" "$wrkroot/out_1/fat32.tar.xz" \
								"$wrkroot/out";;
# After run_build_3 and run_mv
(run_clean)
	rm -rf "$wrkroot/tmp_1" "$wrkroot/tmp_2" "$wrkroot/out_1" \
							"$wrkroot/out_2";;
(clean_img)
	exec docker rmi masysmalocal/bpi-build-1-kernel-boot-img \
			masysmalocal/bpi-build-2-debootstrap \
			masysmalocal/bpi-build-3-join;;
(*)
	echo "USAGE $0 all1"
	echo "USAGE $0 prepare_wrkroot|establish_directories|build_image_{1..3}"
	echo "USAGE $0 run_build_{1..3}|run_mv|run_clean|clean_img";;
esac
