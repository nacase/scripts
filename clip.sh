#!/bin/sh
# copy file contents to X clipboard
usage() {
    echo "usage: $0 [-t] <file to copy>"
    exit 1
}
[ -n "$1" ] || usage
cat "$1" | xclip -selection clipboard
echo "Contents of file '$1' copied to clipboard"
