#!/bin/sh -e
# Ma_Sys.ma Script to generate images for Banana Pi M2+EDU based on Debian only,
# Copyright (c) 2020 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.

# run as root
sysctl -w kernel.unprivileged_userns_clone=1
