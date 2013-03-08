#!/bin/bash
# List files older than a year that are larger than 20 MB
#
# Author: Nate Case <nacase@gmail.com>

usage() {
        echo "Usage: $0 [options]"
        echo ""
        echo "Available options:"
        echo ""
        echo "  -d <dir>        Directory to search (default is current dir)"
        echo "  -t <age string> Time filter - default is '1 year ago'"
        echo "                  (passed to 'date' command)"
        echo "  -s <size>       File size filter in MegaBytes (default 20)"
        echo "  -h              This help screen"
        exit 1
}

# Parse command line options.  We don't use getopt since our
# busybox build doesn't include it
while [ $# -ge 1 ]; do
        case $1 in
        -d)     shift;  DIR=$1 ;;
        -d*)    DIR=`echo $1 | cut -c3-`;;
        -t)     shift;  TIME=$1 ;;
        -t*)    TIME=`echo $1 | cut -c3-`;;
        -s)     shift;  SIZE=$1 ;;
        -s*)    SIZE=`echo $1 | cut -c3-`;;
        -h)     usage ;;
        -?)     usage ;;
        -*)     echo "Invalid argument '$1'"; usage ;;
        esac

        shift
done

# Defaults
if test "$DIR" = ""; then
	DIR=`pwd`
fi

if test "$TIME" = ""; then
	TIME="1 year ago"
fi

if test "$SIZE" = ""; then
	SIZE=20
fi

# Convert MB to 512-byte blocks
SIZE_BLOCKS=`echo $(($SIZE*2048))`

TIMESTR=`date +%Y/%m/%d -d "$TIME"`
OLDFILE=`mktemp /tmp/oldfile.XXXXXXXX`
touch -d $TIMESTR $OLDFILE
# find 'size' units are 512-byte blocks by default.  older versions
# don't support the "M" suffix
find $DIR -type f \! -newer $OLDFILE -size +$SIZE_BLOCKS
rm -f $OLDFILE
