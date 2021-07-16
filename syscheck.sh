#!/bin/bash

OUTPUT="output"
DATABASE="database"

test_file () {
	if [ -d "$1" ]; then
		return
	fi
	echo "Checking $1"
	GITFILE=`echo $1 | sed 's/\//_/g'`
	sha512sum $1 > $DATABASE/$GITFILE
}

test_directory () {
	FILES=`find $1`
	for file in $FILES; do
		test_file $file
	done
}

test_permissions () {
	echo "Checking permissions $1"
	TMP=`echo $1 | sed 's/\//_/g'`
	GITFILE="permissions_"$TMP
	ls -d -l $1 |  awk '{print $1 $9}' > $OUTPUT/$GITFILE
	sha512sum $OUTPUT/$GITFILE > $DATABASE/$GITFILE
}

test_local_ssh_directory () {
	FILES=`find ~/.ssh | grep -v known_hosts`
	for file in $FILES; do
		test_file $file
	done
}

test_rkhunter () {
	test_file /etc/rkhunter.conf
	echo "Checking rkhunter, please wait..."
	GITFILE="rootkit_rkhunter"
	sudo rkhunter --check --cronjob --disable ipc_shared_mem --report-warnings-only > $OUTPUT/$GITFILE
	sha512sum $OUTPUT/$GITFILE > $DATABASE/$GITFILE
}

test_chkrootkit () {
	test_file /etc/chkrootkit.conf
	echo "Checking chkrootkit, please wait..."
	GITFILE="rootkit_chkrootkit"
	sudo chkrootkit | grep -v '!' > $OUTPUT/$GITFILE
	sha512sum $OUTPUT/$GITFILE > $DATABASE/$GITFILE
}

test_pkgmgr_integrity () {
	echo "Verifying files (md5sum) installed by apt/dpkg. This will take a few minutes..."
	GITFILE="pkgmgr_file-integrity"
	sudo dpkg --verify | tee $OUTPUT/$GITFILE
	sha512sum $OUTPUT/$GITFILE > $DATABASE/$GITFILE
}

test_pkgmgr_update ()  {
	echo "System update"
	sudo apt-get update
	sudo apt-get -y autoremove
	sudo apt-get -y upgrade
}

test_kernel_modules () {
	echo "Checking kernel modules"
	GITFILE="kernel_modules"
	lsmod | cut -f1 -d' ' | sort -u > $OUTPUT/$GITFILE
	sha512sum $OUTPUT/$GITFILE > $DATABASE/$GITFILE
}




# create database and output directories
mkdir -p $DATABASE
mkdir -p $OUTPUT

#test_pkgmgr_update
#test_pkgmgr_integrity

# local file tests
test_file ~/.bashrc
test_directory ~/.config/autostart
test_local_ssh_directory
test_directory ~/.gnupg

# system file tests
test_file /etc/rc.local
test_file /etc/fstab
test_file /etc/resolv.conf
test_file /etc/nsswitch.conf
test_file /etc/host.deny
test_file /etc/host.allow
test_directory /etc/security
test_file /etc/ssl/openssl.cnf
test_directory /etc/ssl/certs
test_permissions /etc/ssh/sshd_config
test_permissions /etc/cron.d
test_permissions /etc/cron.daily
test_permissions /etc/cron.hourly
test_permissions /etc/cron.monthly
test_permissions /etc/crontab
test_permissions /etc/cron.weekly

# rootkit tests
test_kernel_modules
test_rkhunter
test_chkrootkit

# closing down
echo "All done! Test results as follow:"
echo "******************************"
git status -s
echo "******************************"

# Archive the output directory. The number is the epoch time. Use date command to convert it:
#         $ date --date='@2147483647'
#TMP="output_"`date +%s`.tar.xz
#tar -cJf $TMP output
#echo "The output directory was archived in $TMP"



