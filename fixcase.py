#!/usr/bin/env python
#
# Pass this script a path, and it will fix any case-sensitivity errors in
# it, returning the corrected path.  Useful when working with filesystems
# shared between Unix/Windows and you're given a path that may only work
# on case-insensitive filesystems.
#
# Nate Case
#
import os
import sys

def get_basic_case_combos(str):
    """Returns list of string in common capitalization forms."""
    return (str, str.lower(), str.upper(), str.capitalize())

def fixfile(dir, file):
    """Find the right file in the given known-to-exist directory.  Return the
    name of the existing filename (no path)."""
    # First check the existance of common capitalized ways to avoid searching
    # the directory if possible
    names = get_basic_case_combos(file)
    for name in names:
        if os.path.exists(os.path.join(dir, name)):
            return name
    # Failing that, compare with each file in the directory.
    names = os.listdir(dir)
    for name in names:
        if name.upper() == file.upper():
            return name

    return None

if len(sys.argv) < 2:
    print "Usage: %s <path>" % sys.argv[0]
    sys.exit(-1)
    
opath = sys.argv[1]

if opath[0] == "/":
    root = "/"
else:
    root = "./"

# Break path up into parts
parts = opath.split("/")

tpath = root
for part in parts:
    try:
        tpath = os.path.join(tpath, fixfile(tpath, part))
    except:
        sys.stderr.write("No file/dir matching '%s' in %s\n" % (part, tpath))
        sys.exit(-2)

print tpath
