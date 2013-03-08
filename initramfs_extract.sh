#!/bin/bash

if [ "$1" == "" ]
then
	echo "usage: $0 <kernel image>"
	exit 1
fi

KERN=$1

if [ ! -f $KERN ]
then
	echo "Error: $KERN not found"
	exit 2
fi

# Detect kernel image type
FTYPE=`file $KERN`
IS_UIMAGE=0
IS_ELF=0
IS_BIN=0
IS_GZBIN=0
IS_BZIMAGE=0
IS_PPC=0
ITYPE="Unknown"

echo $FTYPE | grep -qEi "u-boot|ppcboot"
if [ $? == 0 ] ; then IS_UIMAGE=1 ; ITYPE="uImage" ; fi

echo $FTYPE | grep -qEi "bzImage"
if [ $? == 0 ] ; then IS_BZIMAGE=1 ; ITYPE="bzImage" ; fi

echo $FTYPE | grep -qEi "ELF"
if [ $? == 0 ] ; then IS_ELF=1 ; ITYPE="ELF" ; fi

echo $FTYPE | grep -qEi "PowerPC"
if [ $? == 0 ] ; then IS_PPC=1 ; fi

echo $FTYPE | grep -qEi "gzip"
if [ $? == 0 ] ; then IS_GZBIN=1 ; ITYPE="gzipped binary" ; fi

echo $FTYPE | grep -qEi ": data"
if [ $? == 0 ] ; then IS_BIN=1 ; ITYPE="vmlinux binary" ; fi

if [ "$ITYPE" == "Unknown" ]
then
	echo "Unknown kernel image type"
	echo "File type: $FTYPE"
	exit 3
fi

echo " * Detected image type: $ITYPE"

OUTFILE=$KERN-initramfs.cpio.gz
OUTFILENOGZ=$KERN-initramfs.cpio
TMPFILE=""

if [ $IS_BZIMAGE == 1 ]
then
	# Extract ELF file from bzImage
	# The 'binoffset' utility is found in scripts/binoffset.c of any
	# linux kernel tree
	echo " * Searching for gzip magic header in bzImage"
	HDR=`/opt/bin/binoffset $KERN 0x1f 0x8b 0x08 0x0`
	PID=$$
	TMPFILE="/tmp/$KERN.vmlin.$PID"
	echo " * Found at offset $HDR"
	echo " * Extracting ELF image"
	dd if=$KERN bs=1 skip=$HDR | zcat - > $TMPFILE
	
	# Now tell the rest of this script to treat it as a regular ELF image
	IS_ELF=1
	KERN=$TMPFILE
fi

# This one is easy
if [ $IS_ELF == 1 ]
then
	CROSSTOOL=""
	if [ $IS_PPC == 1 ] ; then
		echo " * ELF file is for PowerPC architecture"
		CROSSTOOL="powerpc64-linux-"
 	fi
	ramfs_section=`${CROSSTOOL}readelf -e $KERN | grep -E " \.init\.data| \.init\.ramfs" | head -n1 | awk '{print $2}'`
	echo " * Copying initramfs from '${ramfs_section}' ELF section"
	${CROSSTOOL}objcopy -j ${ramfs_section} -O binary $KERN $OUTFILE
	if [ "$TMPFILE" != "" ] ; then
		rm -f $TMPFILE
	fi
	echo " * Created $OUTFILE"
	echo " * Checking for gzip file within $OUTFILE"
	HDR=`/opt/bin/binoffset $OUTFILE 0x1f 0x8b 0x08 0x08`
	echo " * Found at offset $HDR"
	echo " * Copying out gzip portion to $OUTFILE.gz"
	dd if=$OUTFILE bs=1 skip=$HDR of=$OUTFILE.gz
	exit 0
fi

TMPDIR=`mktemp -d /tmp/extra_initramfs.XXXXXX`
if [ $IS_BIN == 0 ]
then
	echo " * Converting to vmlinux binary format"
	if [ $IS_UIMAGE == 1 ]
	then
		dd if=$KERN of=$TMPDIR/vmlinux.bin.gz bs=64 skip=1 &> /dev/null
		zcat $TMPDIR/vmlinux.bin.gz > $TMPDIR/vmlinux.bin
	elif [ $IS_GZBIN == 1 ]
	then
		zcat $KERN > $TMPDIR/vmlinux.bin
	fi
	BINFILE=$TMPDIR/vmlinux.bin
else
	BINFILE=$KERN
fi

echo " * Searching for initramfs in binary image"
OFS=`hexdump -C $BINFILE | grep -E "  1f 8b 08" | awk '{print $1}'`
echo " * Found at offset 0x$OFS"
SKIP=`echo $((0x$OFS/1024))`
dd if=$BINFILE of=$OUTFILE bs=1024 skip=$SKIP &> /dev/null
echo " * Creating $OUTFILE"
# Fix trailing garbage at the end
gunzip $OUTFILE &> /dev/null
if [ $? != 0 ] ; then
	echo " * Initramfs was not gzipped, renaming to $OUTFILENOGZ"
	mv $OUTFILE $OUTFILENOGZ
else
	rm -f $OUTFILE
	gzip $OUTFILENOGZ
fi

# Clean up
rm $TMPDIR/vmlinux.bin*
rmdir $TMPDIR
