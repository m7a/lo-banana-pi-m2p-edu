FROM debian:bullseye
LABEL maintainer "Linux-Fan <Ma_Sys.ma@web.de>"

# SSHD for file synchronization, Copyright (c) 2019 Ma_Sys.ma.
# For further info send an e-mail to Ma_Sys.ma@web.de.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# docker build -t masysma-12-rsync-target .
# docker run -d -v /home/backupuser/itasync:/home/linux-fan/sync -p 8194:8194 --restart=unless-stopped --name ma-d-rsync-target-ita masysma-12-rsync-target

ARG MA_DEBIAN_MIRROR=http://192.168.1.16/debian
SHELL ["/bin/sh", "-ec"]
RUN \
	echo deb $MA_DEBIAN_MIRROR bullseye main > /etc/apt/sources.list; \
	echo deb $MA_DEBIAN_MIRROR bullseye-updates main \
						>> /etc/apt/sources.list; \
	echo deb http://security.debian.org/ bullseye-security main \
						>> /etc/apt/sources.list; \
	useradd -u 1024 -m linux-fan; \
	mkdir -p /home/linux-fan/.ssh /home/linux-fan/.sshd \
							/home/linux-fan/sync; \
	apt-get update; \
	apt-get -y dist-upgrade; \
	apt-get install -y openssh-server rsync; \
	apt-get clean; \
	cp /etc/ssh/*_key* /home/linux-fan/.sshd; \
	printf  "%s\n%s\n%s\n%s\n" \
		"Port 8194" \
		"HostKey /home/linux-fan/.sshd/ssh_host_ed25519_key" \
		"PasswordAuthentication no" \
		"UsePrivilegeSeparation no" \
		> /home/linux-fan/.sshd/sshd_config; \
	echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMbFUf6X8N/1MIuzjhuaoLjUCQ5bhmogs72jJJe5ibk linux-fan@masysma-12-sub" > /home/linux-fan/.ssh/authorized_keys; \
	chown linux-fan:linux-fan -R /home/linux-fan; \
	chmod 600 /home/linux-fan/.sshd/* /home/linux-fan/.ssh/*

EXPOSE 8194
USER linux-fan
CMD [ "/usr/sbin/sshd", "-f", "/home/linux-fan/.sshd/sshd_config", "-e", "-D" ]
