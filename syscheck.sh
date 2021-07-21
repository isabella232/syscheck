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

test_rkhunter () {
	test_file /etc/rkhunter.conf
	echo "Checking rkhunter, please wait..."
	GITFILE="rootkit_rkhunter"
	rkhunter --check --cronjob --disable properties,ipc_shared_mem,malware --report-warnings-only > $OUTPUT/$GITFILE
}

test_chkrootkit () {
	test_file /etc/chkrootkit.conf
	echo "Checking chkrootkit, please wait..."
	GITFILE="rootkit_chkrootkit"
	chkrootkit | grep -v '!' > $OUTPUT/$GITFILE
}

test_pkgmgr_integrity () {
	echo "Verifying files (md5sum) installed by apt/dpkg. This will take a few minutes..."
	GITFILE="pkgmgr_file-integrity"
	dpkg --verify | tee $OUTPUT/$GITFILE
}


if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as user: root"
        exit 1
fi


# create database and output directories
mkdir -p $DATABASE
mkdir -p $OUTPUT

# package manager test
test_pkgmgr_integrity

# local file tests
test_file ~/.bashrc
test_directory ~/.config/autostart
test_directory ~/.ssh
test_directory ~/.gnupg

# system file tests
test_file /etc/rc.local
test_file /etc/fstab
test_file /etc/resolv.conf
test_file /etc/nsswitch.conf
#test_file /etc/host.deny
#test_file /etc/host.allow
test_directory /etc/security
test_file /etc/ssl/openssl.cnf
test_directory /etc/ssl
test_directory /etc/ssh
test_file /etc/cron.d
test_file /etc/cron.daily
test_file /etc/cron.hourly
test_file /etc/cron.monthly
test_file /etc/crontab
test_file /etc/cron.weekly

# rootkit tests
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



