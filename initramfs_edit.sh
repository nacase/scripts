#!/bin/bash
#
# Interactively edit a compressed cpio ramfs archive.  Makes checks
# to ensure safety and enables you to add this to sudoers file for
# all users.
#
# Nate Case <nacase@gmail.com>
#

usage() {
    echo "usage: $0 <initramfs.cpio.{gz|lzma|bz2}>"
    exit 1
}

[ -f "$1" ] || usage

if [ "$UID" != "0" ]
then
	echo "Error: This script requires root access.  Please use 'sudo $0'"
	exit 5
fi

if [ "$SUDO_UID" = "" ]
then
	echo "Error: You must run this script via 'sudo'"
	exit 6
fi

function cleanup {
	echo "Cleaning up"

	if [ "$ARCHIVE" != "" ]
	then
		rm -f $ARCHIVE
	fi

	if [ "$TMPDIR" != "" -a "$TMPNAME" != "" ]
	then
		echo "Deleting /tmp/$TMPNAME"
		rm -rf /tmp/$TMPNAME
	fi
}

FNAME=$1
COMPRESS_TOOL=""
DECOMPRESS_TOOL="cat"
COMPRESS_SUFFIX=""
COMPRESS_ARGS=""

IN_TYPE=$(file "${FNAME}")
if [[ "${IN_TYPE}" =~ gzip ]] ; then
    COMPRESS_TOOL="gzip"
    DECOMPRESS_TOOL="zcat"
    COMPRESS_SUFFIX=".gz"
elif [[ "${IN_TYPE}" =~ LZMA ]] ; then
    COMPRESS_TOOL="lzma"
    DECOMPRESS_TOOL="lzcat"
    COMPRESS_SUFFIX=".lzma"
elif [[ "${IN_TYPE}" =~ bzip2 ]] ; then
    COMPRESS_TOOL="bzip2"
    DECOMPRESS_TOOL="bzcat"
    COMPRESS_SUFFIX=".bz2"
elif [[ "${IN_TYPE}" =~ XZ ]] ; then
    COMPRESS_TOOL="xz"
    DECOMPRESS_TOOL="xzcat"
    COMPRESS_SUFFIX=".xz"
    # Kernel embedded XZ does not support sha256/crc64
    COMPRESS_ARGS="--check=crc32"
else
    echo "Note: Assuming archive is uncompressed"
fi

fileowner=`stat $FNAME | grep "Uid:" | sed 's/.*Uid:[^0-9]*\([0-9]*\)\/.*/\1/'`
if [ "$fileowner" != "$SUDO_UID" ]
then
	echo "Error: $FNAME is owned by user ID $fileowner and you are"
	echo "user ID $SUDO_UID.  Refusing to modify."
	exit 2
fi

TMPDIR=`mktemp -d /tmp/ramfs.XXXXX`
TMPNAME=`basename $TMPDIR`
ARCHIVE=`mktemp /tmp/ramfs.cpio.XXXXX`

echo "Decompressing $0 .."
"${DECOMPRESS_TOOL}" $FNAME > $ARCHIVE
if [ $? != 0 ]
then
	echo "Error: Failed to decompress cpio archive '$FNAME'"
	rm -f $ARCHIVE
	exit 7
fi

# Looks legitimate -- proceed on
pushd $TMPDIR >> /dev/null
cat $ARCHIVE | cpio --extract --make-directories --no-absolute-filenames -H newc
if [ $? != 0 ]
then
	echo "Error: Failed to unpack $ARCHIVE to $TMPDIR"
	exit 9
fi
popd >> /dev/null

echo ""
echo "Successfully extracted ramfs archive to $TMPDIR"
echo ""
pushd $TMPDIR >> /dev/null
echo "Modifying permissions to allow modification by current user '$SUDO_UID'"
chown $SUDO_UID $TMPDIR
chown -R $SUDO_UID * 

echo "Launching new shell in $TMPDIR"
echo ""
echo "The contents of the ramfs are now in your current working directory."
echo "You can edit the filesystem from this shell."
echo ""
echo "You can copy over files as needed from /home/<user>/filesystems/"
echo "into this filesystem."
echo ""
echo "Type 'exit' when you are finished to save the changes back to the"
echo "image file."

TMP_RC=`mktemp /tmp/rcfile.XXXXXX`
cat >> $TMP_RC << EOF
export PS1='\[\033[01;36m\][ramfs edit] \[\033[01;34m\]\W \$ \[\033[00m\] '
EOF
chmod a+rx $TMP_RC

sudo -u $SUDO_USER /bin/bash --rcfile $TMP_RC

rm -f $TMP_RC

# Modify the filesystem image
echo ""
echo "Restoring permissions to be owned by root"
chown -R root *
chown root $TMPDIR
echo "Repacking cpio archive"
cd $TMPDIR
find . | cpio -o -H newc > $ARCHIVE
popd >> /dev/null

echo "Compressing image and copying to '$FNAME'"
pushd /tmp >> /dev/null
[ -n "${COMPRESS_TOOL}" ] && "${COMPRESS_TOOL}" "${COMPRESS_ARGS}" -9 "${ARCHIVE}"
popd >> /dev/null
cp -f "${ARCHIVE}${COMPRESS_SUFFIX}" "${FNAME}"
rm -f "${ARCHIVE}${COMPRESS_SUFFIX}"
cleanup
echo "${FNAME} is now updated with the changes you made"
