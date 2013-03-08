#!/bin/sh
# Recursively search through files in current directory and dump out
# the word frequency occurances
cat `find -type f | xargs echo` | sed 's/ /\n/g' | sed 's/\t/ /g' | sed 's/^ //g' | sed 's/ $//g' | sort -fd | uniq -ic | less | sort -n
