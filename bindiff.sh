#!/bin/bash
# 'cmp -l' is one of the simplest ways to look at binary differences
# between two files.  Unfortunately, it prints out the offsets in decimal
# and the values in octal, making it pretty unfriendly.
#
# This shell script wraps around 'cmp' to print both the offset and values
# in hexadecimal.
#
# Author: Nate Case <nacase@gmail.com>

if [ "$2" = "" ] ; then
    echo "usage: $0 <file1> <file2>"
    exit 1
fi

cmp_out_to_hex() {
    printf "Offset\t\tValue 1\tValue 2\n"
    while read -r line ; do
        ofs=`echo ${line} | awk '{print $1}'`
        val1_oct=`echo ${line} | awk '{print $2}'`
        val2_oct=`echo ${line} | awk '{print $3}'`
        printf "0x%x:\t0x%02x\t0x%02x\n" ${ofs} \
               `echo $((0$val1_oct))` \
               `echo $((0$val2_oct))`
    done
}

cmp -l $1 $2 | cmp_out_to_hex
