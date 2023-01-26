#!/bin/bash

do_dd() {
    >&2 echo "    -> dd $*"
    dd "$@"
}

die() {
    >&2 echo "ERROR: $*"
    exit 1
}

if [ "$1" == "" ]
then
	echo "usage: $0 <kernel image>"
	exit 1
fi

KERN=$1

[ -f "${KERN}" ] || die "${KERN} not found"

# Detect kernel image type
FTYPE=$(file "${KERN}")
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

[ "${ITYPE}" = "Unknown" ] && die "Unknown kernel image type '${FTYPE}'"

echo " * Detected image type: $ITYPE"

OUTFILE=$KERN-initramfs.cpio.gz
OUTFILENOGZ=$KERN-initramfs.cpio
TMPFILE=""

if [ $IS_BZIMAGE == 1 ]
then
	# Extract ELF file from bzImage
	# The 'binoffset' utility is found in scripts/binoffset.c of any
	# linux kernel tree (UPDATE: Removed from tree in 2.6.34)
	echo " * Searching for gzip magic header in bzImage"
	HDR=`binoffset $KERN 0x1f 0x8b 0x08 0x0`
    CAT_TOOL="cat"
    if [ "$HDR" = "-1" ] ; then
        echo "* No gzip header found"
        echo "* Searching for xz header"
	    HDR=`binoffset $KERN 0xfd 0x37 0x7a 0x58 0x5a 0x00`
        [ "${HDR}" = "-1" ] && die "Unable to find initramfs"
        CAT_TOOL="xzcat"
    else
        echo "* Found gzip header at ${HDR}"
        CAT_TOOL="zcat"
    fi
	PID=$$
	TMPFILE="/tmp/$KERN.vmlin.$PID"
	echo " * Extracting ELF image"
	do_dd "if=$KERN" bs=1 "skip=$HDR" | ${CAT_TOOL} - > "$TMPFILE"
	
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
	HDR=`binoffset $OUTFILE 0x1f 0x8b 0x08 0x08`
    SUFFIX=".gz"
    if [ "$HDR" = "-1" ] ; then
        echo "* No gzip header found"
        echo "* Searching for xz header"
	    HDR=`binoffset $OUTFILE 0xfd 0x37 0x7a 0x58 0x5a 0x00`
        if [ "${HDR}" = "-1" ] ; then
            echo "* No xz header found"
            echo "* Searching for lzma header"
	        HDR=`binoffset $OUTFILE 0x5d 0x00 0x00`
            SUFFIX=".lzma"
        else
            SUFFIX=".xz"
        fi

        [ "${HDR}" = "-1" ] && die "No initramfs found"
    fi
	echo " * Found at offset $HDR"
	echo " * Copying out compressed portion to $OUTFILE$SUFFIX"
	do_dd "if=$OUTFILE" bs=1 "skip=$HDR" "of=$OUTFILE$SUFFIX"
	exit 0
fi

TMPDIR=`mktemp -d /tmp/extra_initramfs.XXXXXX`
if [ $IS_BIN == 0 ]
then
	echo " * Converting to vmlinux binary format"
	if [ $IS_UIMAGE == 1 ]
	then
		do_dd if=$KERN of=$TMPDIR/vmlinux.bin.gz bs=64 skip=1 &> /dev/null
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
do_dd if=$BINFILE of=$OUTFILE bs=1024 skip=$SKIP &> /dev/null
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
