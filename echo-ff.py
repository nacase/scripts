#!/usr/bin/env python3
# quick shortcut to dump $1 binary 0xff bytes to stdout

import sys
import os

if len(sys.argv) < 2:
    sys.stderr.write("usage: {} <size in bytes>\n".format(sys.argv[0]))
    sys.stderr.write("Writes given number of 0xff bytes to stdout\n")
    sys.exit(1)

num_bytes = int(sys.argv[1])

for i in range(0, num_bytes):
    sys.stdout.buffer.write(b"\xff")
