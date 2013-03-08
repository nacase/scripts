#!/bin/bash
#
# Determine the version of a Linux kernel tree.  This determines the
# version based on:
#
# 	Top-level Makefile
#	localversion* files that are present
#	Kernel config file (for setting additional LOCALVERSION) if present
#
# Note that the kernel tree does NOT have to be configured for this to
# work.
#	
# - Nate Case <ncase@xes-inc.com>
#

if [[ "$1" == "" ]] ; then
	echo "usage: $0 <path to kernel tree> [kernel config file]"
	exit 1
fi

KERNPATH=$1
if [[ "$2" != "" ]] ; then
	KCFG=$2
else
	KCFG=${KERNPATH}/.config
fi

head ${KERNPATH}/Makefile | grep -qE "^VERSION = "
if [[ $? != 0 ]] ; then
	echo "Invalid kernel tree '$KERNPATH' specified"
	exit 1
fi

get_kernel_tree_ver() {
	local kernpath="$1"
	local kcfg="$2"
	local quote='"'

	# Get the local version based on localversion* files and
	# CONFIG_LOCALVERSION
	local kernel_local_ver=""
	for x in ${kernpath}/localversion* ; do
		if [[ -f ${x} ]] ; then
			kernel_local_ver="${kernel_local_ver}`cat $x`"
		fi
	done

	if [[ -f ${kcfg} ]] ; then
		kernel_local_ver=${kernel_local_ver}`grep -E "^CONFIG_LOCALVERSION=" ${kcfg} | awk -F$quote '{print $2}'`
	fi

	local mkf_version=`grep -E "^VERSION" ${kernpath}/Makefile | awk -F"= " '{print $2}'`
	local mkf_patchlevel=`grep -E "^PATCHLEVEL" ${kernpath}/Makefile | awk -F"= " '{print $2}'`
	local mkf_sublevel=`grep -E "^SUBLEVEL" ${kernpath}/Makefile | awk -F"= " '{print $2}'`
	local mkf_extraversion=`grep -E "^EXTRAVERSION" ${kernpath}/Makefile | awk -F"= " '{print $2}'`
	local mkf_fullver=${mkf_version}.${mkf_patchlevel}.${mkf_sublevel}${mkf_extraversion}

	echo "${mkf_fullver}${kernel_local_ver}"
}

get_kernel_tree_ver ${KERNPATH} ${KCFG}
