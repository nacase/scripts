#!/bin/bash
# Mute/Unmute/toggle PulseAudio device via command line.
# Set device name.  Run 'pactl list | grep "Sink #" -A5' and use
# the 'Name:' field for the device you want to use.
# To get the default sink name, run: pactl info | grep "Default Sink"
#
# This script can be bound to function keys in your desktop environment
# for quick muting/unmuting.
#
# Author: Nate Case <nacase@gmail.com>

# Use Default Sink
sinkname=`pactl info | grep "Default Sink" | awk -F": " '{print $2}'`

arglower=`echo "$1" | tr 'A-Z' 'a-z'`
case "$arglower" in
y*|1|on)
    val="yes"
    ;;
n*|0|off)
    val="no"
    ;;
*)
    # Default behavior: toggle mute
    state=`pactl list sinks | grep -E "Name:|Mute:" | grep -E "${sinkname}" -A1 | tail -n1 | awk -F": " '{print $2}'`
    if [ "${state}" = "yes" ] ; then
        val="no"
    else
        val="yes"
    fi
    ;;
esac

pactl set-sink-mute "${sinkname}" ${val}
