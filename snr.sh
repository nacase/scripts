#!/bin/bash
#
# Simple script to do search-and-replace on files.  With automatic backup.
#
# - Nate Case
#

if [ "$3" == "" ]
then
	echo "usage: $0 <search string> <replacement string> <files>.."
	exit 1
fi

# Parse command line
SEARCH=$1
shift
REPLACE=$1
shift
FILES=$*

echo "Mass search-and-replace"
echo "-----------------------"
echo ""
echo "Search string: '$SEARCH'"
echo "Replacement string: '$REPLACE'"
echo "Files to change: $FILES"
echo ""
echo -n "Proceed with operation (Y/n) ? "
read response
response=`echo $response | tr '[a-z]' '[A-Z]'`
if [ "$response" == "" -o "$response" == "Y" -o "$response" == "YES" ]
then
        # Do nothing
        echo ""
else
        echo "Operation aborted"
        exit 3
fi

for x in $FILES
do
	if [ ! -f $x ]
	then
		echo "Skipping invalid file '$x'"
		continue
	fi
	SEPS="/ , : %"
	FOUND_SEP=0
	for SEP in $SEPS ; do
		echo "${SEARCH}${REPLACE}" | grep -qE $SEP
		if [ $? != 0 ] ; then
			FOUND_SEP=1
			break
		fi
	done
	if [ $FOUND_SEP = 0 ] ; then
		echo "Error: Search/Replace strings contain too much funk"
		echo "(cannot contain all of '$SEPS')"
		exit 1
	fi
	sed -i.SNR-BACKUP "s${SEP}${SEARCH}${SEP}${REPLACE}${SEP}g" $x
	CHANGES=`diff -u $x.SNR-BACKUP $x | diffstat | tail -n1 | awk '{print $4}'`
	if [ "$CHANGES" == "" ]
	then
		echo "$x: search string not found; leaving unmodified"
	else
		echo "$x: replaced $CHANGES occurrences of string"
	fi
	# Make backup a hidden file
	mv $x.SNR-BACKUP .$x.SNR-BACKUP
done

echo "Operation complete: Backups are named .<filename>.SNR-BACKUP"
