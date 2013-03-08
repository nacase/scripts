#!/usr/bin/env python
#
# Generate a C header file with an array of bytes given a binary file
# as input.
#
# Author: Nate Case <nacase@gmail.com>

import sys, time

if len(sys.argv) < 3:
    print "usage: %s <binary file> <array variable name>" % sys.argv[0]
    sys.exit(-1)

BINFILE=sys.argv[1]
VARNAME=sys.argv[2]

f = open(BINFILE, "rb")
data = f.read()
f.close()

print """/*
 * Binary data blob generated %s
 */

#ifndef __%s_H__
#define __%s_H__

#define %s_SIZE 0x%x

unsigned char %s[%s_SIZE] = {
/*\t\t 0\t 1\t 2\t 3\t 4\t 5\t 6\t 7   */""" \
    % (time.ctime(), VARNAME.upper(), VARNAME.upper(), VARNAME.upper(), \
        len(data), VARNAME.lower(), VARNAME.upper())

size = len(data)
n = 0
sys.stdout.write("/* %08x */\t" % n)
for b in data:
    sys.stdout.write("0x%02x" % ord(b))
    if (n+1) < size:
        sys.stdout.write(",")
    if (n+1) % 8 == 0:
        sys.stdout.write("\n/* %08x */\t" % (n+1))
    else:
        sys.stdout.write("\t")
    n += 1

print """};

#endif  /* __%s_H__ */""" % (VARNAME.upper())
