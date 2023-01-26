#!/bin/sh
# show lines that are common/present in both files given
tmp1=$(mktemp /tmp/common-lines1.XXXXXX)
tmp2=$(mktemp /tmp/common-lines2.XXXXXX)
cat "$1" | sort | uniq > "${tmp1}"
cat "$2" | sort | uniq > "${tmp2}"
comm -12 "${tmp1}" "${tmp2}"
rm -f "${tmp1}" "${tmp2}"
