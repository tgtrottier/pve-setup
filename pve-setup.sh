#!/bin/bash
# Proxmox Setup Script - Taylor Trottier

#install unsubscribed proxmox directory
	rm /etc/apt/sources.list
	cat << EOT >> /etc/apt/sources.list
	deb http://ftp.debian.org/debian stretch main contrib
	deb http://download.proxmox.com/debian/pve stretch pve-no-subscription
	# security updates
	deb http://security.debian.org stretch/updates main contrib
	EOT
	apt update

#install tools for fan controller thanks richgannon.net
	apt-get install ipmitool -y
	apt-get install smartmontools -y
	apt-get install lm_sensors -y
	wget http://richgannon.net/projects/dellfanspeed/r710_fan_controller.sh
	mv r710_fan_control.sh /etc/init.d/
	chmod +x /etc/init.d/r710_fan_controller.sh
	update-rc.d r710_fan_controller.sh defaults

#wipe storage disks and write with ext4 
	
	apt-get install parted
	for i in $((ls /dev/sd*)|grep "\/dev\/sd[c-z]$"); do
	echo item:$i;
	parted -s -a optimal $i mklabel gpt --  mkpart primary ext4 2048s 100%
	
	done
	
# Modify fstab to mount drives to locations for mergerfs and snapraid
	cat <<EOT >> /etc/fstab
	 
	/dev/pve/root / ext4 errors=remount-rw 0 1
	/dev/pve/swap none swap sw 0 0
	proc /proc proc defaults 0 0

	/dev/sdc1 /parity/r710/1 ext4 defaults 0 2
	/dev/sdd1 /mnt/r710/2 ext4 defaults 0 2
	/dev/sde1 /mnt/r710/3 ext4 defaults 0 2
	/dev/sdf1 /mnt/r710/4 ext4 defaults 0 2

	/mnt/r710/\* /pool fuse.mergerfs  defaults,allow_other,direct_io,use_ino,category.create=eplfs,hard_remove,moveonenospc=true,minfreespace=20G,fsname=mergerfsPool 0 0

	
	EOT
	
	mkdir -p /pool /parity/r710/1 /mnt/r710/1 /mnt/r710/2 /mnt/r710/3 /mnt/r710/4
	
	mount -a
 
#- Snapraid Install
	wget https://github.com/amadvance/snapraid/releases/download/v11.2/snapraid-11.2.tar.gz
	tar xzvf snapraid-11.2.tar.gz
	cd snapraid-11.2/
	./configure
	make
	make check
	make install
	cd ..
	cp ~/snapraid-11.2/snapraid.conf.example /etc/snapraid.conf
	cd ..


 
	cat <<EOT >> /etc/Snapraid.conf

	parity /mnt/r710/p/snapraid.parity

	content /var/snapraid/snapraid.content
	content /mnt/r710/1/snapraid.content
	content /mnt/r710/2/snapraid.content
	content /mnt/r710/3/snapraid.content
	content /mnt/r710/4/snapraid.content

	disk d1 /mnt/r710/1/
	disk d2 /mnt/r710/2/
	disk d3 /mnt/r710/3/
	disk d4 /mnt/r710/4/

	exclude *.bak
	exclude *.unrecoverable
	exclude /tmp/
	exclude /lost+found/
	exclude .AppleDouble
	exclude ._AppleDouble
	exclude .DS_Store
	exclude .Thumbs.db
	exclude .fseventsd
	exclude .Spotlight-V100
	exclude .TemporaryItems
	exclude .Trashes
	exclude .AppleDB
	blocksize 256

	EOT

	mount -a
	
	
