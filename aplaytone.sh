#!/bin/bash
#
# Play a sine frequency tone on an ALSA device
#
# - Nate

if [ "$1" = "" ] ; then
        echo "usage: $0 <frequency> [aplay params]"
        exit 1
fi

which sox &> /dev/null
if [ $? != 0 ] ; then
        echo "Error: sox not found"
        echo "This script requires the 'sox' utility to be installed."
        exit 1
fi

FREQ="$1"
shift
SRATE=48000
FMT="S16_LE"
#echo "Adjusting mixer settings"
#amixer -c ${DEST_CARD_NUM} sset PCM 86% unmute | grep dB
echo "Sending ${FREQ} Hz tone to 'aplay $@'"
sox -q -n -t wav -r ${SRATE} -c 1 -2 - synth sin ${FREQ} | aplay -r ${SRATE} -f ${FMT} $@
