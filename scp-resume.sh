#!/bin/bash
# resume an scp upload
# use the same args you used for the scp with this script
usage() {
    echo "usage: $0 <original scp args>"
    exit 1
}
[ -n "$1" ] || usage
rsync -P -e ssh "$@"
