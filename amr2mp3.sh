#!/bin/bash
# Convert AMR (gsm?) files to mp3
# Based on http://www.aquarionics.com/journal/2004/08/04/how_to_convert_amr_files_to_mp3/

for file in $* ; do
    FILE=`echo $file | sed -e "s/.amr//"`;
    TMPF=`mktemp /tmp/amrconvfile.XXXXXX`
    echo "* Decoding"
    3gpp-decoder $file $TMPF.s16 > log.std 2> log.err;
    echo "* Converting to wave format"
    sox -r 8000 -c 1 -s $TMPF.s16 -r 16000 $TMPF.wav > log.std 2> log.err;
    echo "* Converting to MP3"
    lame $TMPF.wav $FILE.mp3 --silent \
    	--tt $FILE --ta $USER --tl Aquarionics --ty `date +%y`
    echo "Done, $FILE.mp3 created"
    #rm -f $TMPF $TMPF.s16 $TMPF.wav
    echo $TMPF $TMPF.s16 $TMPF.wav
done
