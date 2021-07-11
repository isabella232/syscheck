#!/bin/bash

print_colorized () {
	printf "\x1b[32m%s %s...\x1b[0m\n" $1 $2
}


print_colorized running apt-update
sudo apt-get update
sudo apt-get autoremove
sudo apt-get -y upgrade

print_colorized checking dpkg
sudo dpkg --verify | tee database/dpkg--verify

print_colorized checking local-files
sha512sum ~/.bashrc > database/dot-bashrc
cat ~/.config/autostart/* | sha512sum > database/dot-config-autostart

print_colorized checking system-files
sha512sum /etc/resolv.conf > database/etc-resolv-conf
sha512sum /etc/rc.local > database/etc-rc-local

print_colorized checking system-files-permissions
ls -d -l /etc/cron* /etc/ssh/sshd_config | cut -f1 -d' ' | sha512sum > database/sysfile-permissions

print_colorized checking dns
/usr/bin/nslookup one.one.one.one | head -n 2 > database/dns

print_colorized checking nmap-portscan
/usr/bin/nmap 127.0.0.1 | grep -v "Starting" | grep -v "latency" | grep -v "scanned" > database/nmap-portscan

print_colorized checking loaded-kernel-modules
lsmod | cut -f1 -d' ' | sort -u > database/loaded-kernel-modules

print_colorized checking rkhunter
sudo rkhunter --check --cronjob --disable ipc_shared_mem --report-warnings-only > database/rkhunter

print_colorized checking chkrootkit
sudo chkrootkit | grep -v '!' > database/chkrootkit

print_colorized all done!
print_colorized git diff
