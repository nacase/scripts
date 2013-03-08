#!/bin/sh
# Mass rename files (search/replace)
# - Nate Case

if [ "$2" = "" ]
then
	tool=`basename $0`
	echo "$tool: Mass rename files in current directory"
	echo "usage: $tool <search string> <replacement string>"
	exit 1
fi

# Parse command line
SEARCH="$1"
shift
REPLACE="$1"
shift

FILES=`echo *$SEARCH*`

if [ "$FILES" = "*$SEARCH*" ] ; then
	echo "No files found matching *$SEARCH*"
	exit 1
fi

echo "Mass rename files (search-and-replace)"
echo "--------------------------------------"
echo ""
echo "Search string: '$SEARCH'"
echo "Replacement string: '$REPLACE'"
echo "Files to change: $FILES"
echo ""
echo -n "Proceed with operation (Y/n) ? "
read response
response=`echo $response | tr '[a-z]' '[A-Z]'`
if [ "$response" = "" -o "$response" = "Y" -o "$response" = "YES" ]
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
	NEWNAME=`echo "$x" | sed "s/$SEARCH/$REPLACE/g"`
	if [ ! "$x" = "$NEWNAME" ]
	then
		echo "$x -> $NEWNAME"
		mv $x $NEWNAME
	fi
done

echo "Operation complete"
