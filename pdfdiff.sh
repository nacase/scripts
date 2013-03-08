#!/bin/sh
#
# Graphically display difference between two PDFs using pdftotext and meld
#

if [ "$2" = "" ] ; then
    echo "usage: $0 <pdf 1> <pdf 2>"
    exit 1
fi

tmp1=`mktemp /tmp/pdfdiff.XXXXXX`
tmp2=`mktemp /tmp/pdfdiff.XXXXXX`

pdftotext "$1" "$tmp1"
pdftotext "$2" "$tmp2"
meld "$tmp1" "$tmp2"
rm -f "$tmp1" "$tmp2"
