#!/bin/bash
# Convert a CPIO[.gz|.bz2|.xz] archive to TAR format using fakeroot
#
# Author: Nate Case <nacase@gmail.com>

if [ "$2" = "" ] ; then
    echo "usage: $0 <file.cpio[{.gz|.bz2|.xz}]> <file.tar>"
    exit 1
fi

CPIOFN="$1"
TARFN="$2"
CAT="cat"

file "${CPIOFN}" | grep -qE "gzip compressed"
if [ $? = 0 ] ; then
    echo "gzip compression detected"
    CAT="zcat"
else
    file "${FNAME}" | grep -qE "bzip2 compressed"
    if [ $? = 0 ] ; then
        echo "bzip2 compression detected"
        CAT="bzcat"
    else
        cat $1 | xz -d > /dev/null
        if [ $? = 0 ] ; then
            echo "XZ/LZMA compression detected"
            CAT="lzcat"
        else
            echo "Archive is not compressed"
        fi
    fi
fi

echo "Extracting archive"
CPIOFN=$(readlink -e ${CPIOFN})
TMPDIR=$(mktemp -d cpio2tar.XXXXXX)
TMPNUM=$(echo "${TMPDIR}" | cut -c 10-)
fakeroot bash -c " \
pushd \"${TMPDIR}\"; \
${CAT} \"${CPIOFN}\" | cpio --extract --make-directories --no-absolute-filenames -H newc; \
popd; \
tar -c -C \"${TMPDIR}\" -f \"${TARFN}\" ."
echo "Created ${TARFN}"
echo "Cleaning up temporary directory ${TMPDIR}"
rm -rf "cpio2tar.${TMPNUM}"
