#!/bin/sh
# Find out which processes have open files, executable path, or current
# working directory matching a specified name.
#
# This is useful for trying to figure out why you can't umount an NFS
# filesystem for example.  It's similar to lsof and fuser, but doesn't
# suck as much when trying to work with stale NFS mounts.  This won't
# catch cases where you have another filesystem mounted that depends
# on the given path (e.g., loopback mounts, or mount underneath the
# directory itself).
#
# - Nate Case

MATCH=$*

if [ "$MATCH" = "" ] ; then
	echo "usage: $0 <file/directory name to match>"
	exit 1
fi

if [ `whoami` != "root" ] ; then
	echo "Error: This script requires root access.  Please use 'sudo $0'"
	exit 5
fi

pid_files() {
	pid=$1
	echo "    cwd: `readlink /proc/$pid/cwd`"
	echo "    exe: `readlink /proc/$pid/exe`"
	echo "    root: `readlink /proc/$pid/root`"
	ls -l /proc/$pid/fd/ | grep $MATCH | sed 's/.* \-> /    /'
}

for x in /proc/[0-9]* ; do
	name=`readlink $x/exe`
	pid=`basename $x`
	#echo "process $pid ($name):"
	pid_files $pid | grep -qE $MATCH
	if [ $? = 0 ] ; then
		echo "process $pid ($name):"
		pid_files $pid | grep $MATCH
	fi
done

echo "Other potentially problematic processes:"
ps auxw | grep -E " D+| DN| Ds "
