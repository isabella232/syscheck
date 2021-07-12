#!/bin/bash

test_file () {
	FILE=`echo $1 | sed 's/\//_/g'`
	touch $FILE

	if git diff --shortstat $1 | grep changed 2>&1  > /dev/null; then
		printf "\x1b[31mWARNING: file modified\x1b[0m\n"
	else
		printf "\n"
	fi


	printf "checking $1\t"
	echo $FILE
}

test_file README.md
test_file hardening
test_file database/hardening

exit






#print_colorized running apt-update
#sudo apt-get update
#sudo apt-get autoremove
#sudo apt-get -y upgrade
#print_colorized checking dpkg
#sudo dpkg --verify | tee database/dpkg--verify

print_colorized checking .bashrc
sha512sum ~/.bashrc > database/dot-bashrc
cp ~/.bashrc > snapshot/.

print_colorized checking dot-config-autostart
cat ~/.config/autostart/* | sha512sum > database/dot-config-autostart
tar -cJvf snapshot/dot-config-autostart.tar.xz ~/.config/autostart

print_colorized checking resolv.conf
sha512sum /etc/resolv.conf > database/etc-resolv-conf
cp /etc/resolv.conf > snapshot/.

print_colorized checking rc.local
sha512sum /etc/rc.local > database/etc-rc-local
cp /etc/rc.local > snapshot/.

print_colorized checking fstab
sha512sum /etc/fstab > database/etc-fstab
cp /etc/fstab > snapshot/.

print_colorized checking system-files-permissions
ls -d -l /etc/cron* /etc/ssh/sshd_config |  awk '{print $1 $9}'' | sha512sum > database/sysfile-permissions
ls -d -l /etc/cron* /etc/ssh/sshd_config |  awk '{print $1 $9}'' > snapshot/sysfile-permissions

print_colorized checking dns
/usr/bin/nslookup one.one.one.one | head -n 2 | sha512sum > database/dns
/usr/bin/nslookup one.one.one.one | head -n 2 > snapshot/dns

print_colorized checking nmap-portscan
/usr/bin/nmap 127.0.0.1 | grep -v "Starting" | grep -v "latency" | grep -v "scanned" > database/nmap-portscan

print_colorized checking loaded-kernel-modules
lsmod | cut -f1 -d' ' | sort -u > database/loaded-kernel-modules

print_colorized checking rkhunter
sudo rkhunter --check --cronjob --disable ipc_shared_mem --report-warnings-only > database/rkhunter

print_colorized checking chkrootkit
sudo chkrootkit | grep -v '!' > database/chkrootkit

print_colorized all done!
echo
print_colorized git status
git status
