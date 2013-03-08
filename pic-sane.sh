#!/bin/bash
# Make a photo ready for distributing on the Internet
# Remove EXIF metadata, scale down to sane size.

if [ "$1" = "" ] ; then
    echo "usage: $0 <image filename> [output filename]"
    echo "Output filename will default to the inputfilename + medium"
    exit
fi

FNAME="$1"
ext=$(echo ${FNAME} | sed 's/.*\.//')
OUT_FNAME=$(echo ${FNAME} | sed "s/\.${ext}$/-medium.${ext}/")
if [ "$2" != "" ]
then
    OUT_FNAME="$2"
fi

convert -strip -resize x800 ${FNAME} ${OUT_FNAME}
echo "Created ${OUT_FNAME}"
