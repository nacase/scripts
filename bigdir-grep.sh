#!/bin/bash
#
# Use this script for grepping through a big directory containing a huge
# number of files (e.g., when you get the "/bin/grep: Argument list too long"
# error)
#
# Nate Case <nacase@gmail.com>

usage() {
        echo "usage: `basename $0` [grep args] <match pattern> <file pattern>"
        echo ""
        echo "The <file pattern> argument is passed to 'find -name'"
        echo ""
        echo "example: $0 -i mysearchstr '*.patch'"
        exit 1
}

ARG_I=0
GREP_ARGS=( )
MATCH_PATTERN=""
FILE_PATTERN=""
# Parse command line options without using getopt
while [ $# -ge 1 ]; do
        case $1 in
	-*)	GREP_ARGS[$((ARG_I))]="$1" ; ARG_I=$((ARG_I+1)) ;;
        *)      if [ "$MATCH_PATTERN" = "" ] ; then MATCH_PATTERN="$1" ; else FILE_PATTERN="$1"; fi ;;
        esac

        shift
done

if [ "$MATCH_PATTERN" = "" -o "$FILE_PATTERN" = "" ] ; then
	usage
fi

find . -maxdepth 1 -name "$FILE_PATTERN" | while read line ; do grep -H ${GREP_ARGS[@]} "${MATCH_PATTERN}" "${line}" ; done
