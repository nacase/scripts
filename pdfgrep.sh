#!/bin/bash
#

if [ "$2" = "" ] ; then
    echo "usage: $0 <pattern> \"<files>\""
    echo "grep options -iE are assumed"
    echo "note: place quotes around <files> when using wildcards"
    exit 1
fi

pattern=$1
shift

ls -1 $* | while read x ; do
    tmp1=`mktemp /tmp/pdfgrep.XXXXXX`
    pdftotext "${x}" "${tmp1}"
    echo "Searching ${x}:"
    grep -iE "${pattern}" "${tmp1}"
    rm -f "${tmp1}"
done
