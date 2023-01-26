#!/bin/bash
#
# compare two kconfig-generated .config files with output that's intended
# to be a little friendlier than what you get with "diff -u"
# (e.g., false differences due to difference in file position)
#
# bash 4 required
#
# Nate Case <nacase@gmail.com>
#

die() {
    >&2 echo "ERROR: $*"
    exit 1
}

usage() {
    echo "usage: $0 <.config file 1> <.config file 2>"
    exit 1
}

# print out dash strings of lengths defined by the args.
# e.g., table_header 3 2 1 prints "--- -- -"
table_header() {
    for x in "$@" ; do
        printf "%0.s-" $(seq 1 "${x}")
        printf " "
    done
    printf "\n"
}

cfg1="$1"
cfg2="$2"

[ -f "${cfg1}" ] || usage
[ -f "${cfg2}" ] || usage

declare -A cfg1vals
declare -A cfg2vals

# come up with terse human-friendly output filenames to reference
# in our diff output
base1=$(basename "${cfg1}")
base2=$(basename "${cfg2}")
if [ "${base1}" = "${base2}" ] ; then
    base1=$(basename "$(dirname "${cfg1}")")
    base2=$(basename "$(dirname "${cfg2}")")
    if [ "${base1}" = "${base2}" ] ; then
        base1="${base1}1"
        base2="${base2}2"
    fi
fi

set_cfg_regex="^CONFIG_.*="
unset_cfg_regex="^# CONFIG_.* is not set$"

col1_width="38"
col2_width="19"
col3_width="19"
printf "%-${col1_width}s %-${col2_width}s %-${col3_width}s\n" "Config Option" "${base1}" "${base2}"
table_header "${col1_width}" "${col2_width}" "${col3_width}"

# read in config file 1
while IFS= read -r line ; do
    if [[ "${line}" =~ ${unset_cfg_regex} ]] ; then
        # Found line like this: # CONFIG_* is not set
        keytmp="${line#* CONFIG_}"
        key="${keytmp% is*}"
        cfg1vals["${key}"]="<disabled>"
    elif [[ "${line}" =~ ${set_cfg_regex} ]] ; then
        # Found regular line like this: CONFIG_BLAH=blah
        keytmp="${line%%=*}"
        key="${keytmp#CONFIG_*}"
        val="${line#*=}"
        # save in our global associative array
        cfg1vals["${key}"]="${val}"
    fi
done < "${cfg1}"

# read in config file 2
while IFS= read -r line ; do
    if [[ "${line}" =~ ${unset_cfg_regex} ]] ; then
        # Found line like this: # CONFIG_* is not set
        keytmp="${line#* CONFIG_}"
        key="${keytmp% is*}"
        cfg2vals["${key}"]="<disabled>"
    elif [[ "${line}" =~ ${set_cfg_regex} ]] ; then
        # Found regular line like this: CONFIG_BLAH=blah
        keytmp="${line%%=*}"
        key="${keytmp#CONFIG_*}"
        val="${line#*=}"
        # save in our global associative array
        cfg2vals["${key}"]="${val}"
    fi
done < "${cfg2}"

# find keys missing in cfg2
for key in "${!cfg1vals[@]}" ; do
    b1val="${cfg1vals[${key}]}"
    b2val="${cfg2vals[${key}]}"
    [ -z "${b2val}" ] && cfg2vals[${key}]="<missing>"
done

# find keys missing in cfg1
for key in "${!cfg2vals[@]}" ; do
    b1val="${cfg1vals[${key}]}"
    b2val="${cfg2vals[${key}]}"
    [ -z "${b1val}" ] && cfg1vals[${key}]="<missing>"
done

# print differences
for key in "${!cfg1vals[@]}" ; do
    b1val="${cfg1vals[${key}]}"
    b2val="${cfg2vals[${key}]}"
    if [ "${b1val}" != "${b2val}" ] ; then
        printf "%-${col1_width}s %-${col2_width}s %-${col3_width}s\n" "${key}" "${b1val}" "${b2val}"
    fi
done
