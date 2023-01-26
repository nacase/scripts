#!/bin/bash
#
# diff with one byte per line, only include value
# works better when file sizes don't match and things get shifted around
#

die() {
    >&2 echo "ERROR: $*"
    exit 1
}

[ -f "$1" ] || die "File not found"
[ -f "$2" ] || die "File not found"

file1=$(mktemp /tmp/bindiff.file1.XXXXXX)
file2=$(mktemp /tmp/bindiff.file2.XXXXXX)
od -w1 -t x1 -v "$1" | awk '{print $2}' > "${file1}"
od -w1 -t x1 -v "$2" | awk '{print $2}' > "${file2}"
diff -bu "${file1}" "${file2}"
rm -f "${file1}" "${file2}"
