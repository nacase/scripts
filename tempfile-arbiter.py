#!/usr/bin/env python
# 
# Simple arbitration scheme using temporary files on a shared filesystem.
#
# - Nate Case

# Procedure:
#
# 1) Program initiates request to start by creating file named
#    REQ.<host>
# 2) Once arbiter sees request, will grant it by creating
#    GNT.<host>
# 3) When initiator is done (test finished), deletes original REQ.<host>
#    file
# 4) Arbiter sees this, removes GNT.<host>, and then goes back to 
#    granting requests
#
# Notes:
# 1) If a REQ is granted but not cleared for more than X seconds,
#    it's a timeout and the arbiter will delete the REQ and GNT.
#

import os, sys, time

def usage():
    print "Usage: %s <temp directory> <timeout in seconds>" % sys.argv[0]
    sys.exit(-1)

if len(sys.argv) < 3:
    usage()

TEMPDIR = sys.argv[1]
TIMEOUT = int(sys.argv[2])

def find_req():
    """Search directory for requests and return the hostname of
    the first one found."""
    files = os.listdir(TEMPDIR)
    for f in files:
        if f.startswith("REQ."):
            return f[4:]
    return ""

def grant(host):
    fname = os.path.join(TEMPDIR, "GNT.%s" % host)
    os.system("touch %s" % fname)

def clear_grant(host):
    fname = os.path.join(TEMPDIR, "GNT.%s" % host)
    os.system("rm -f %s" % fname)

def clear_req(host):
    fname = os.path.join(TEMPDIR, "REQ.%s" % host)
    os.system("rm -f %s" % fname)

def req_done(host):
    """Return True if request is finished (REQ file gone)."""
    fname = os.path.join(TEMPDIR, "REQ.%s" % host)
    # This is necessary to flush NFS directory caches
    os.listdir(TEMPDIR)
    try:
        os.stat(fname)
    except:
        return True
    return False

def main():
    timeout_counter = 0
    grant_active = 0
    gnthost = ""
    while True:
        if grant_active:
            if req_done(gnthost):
                print "Request finished, clearing grant for '%s'" % gnthost
                clear_grant(gnthost)
                grant_active = 0
            else:
                if timeout_counter > TIMEOUT:
                    print "Timeout occurred for %s.  Clearing req" % gnthost
                    clear_req(gnthost)
                    clear_grant(gnthost)
                    grant_active = 0
                else:
                    time.sleep(1)
                    timeout_counter += 1
        else:
            gnthost = find_req()
            if gnthost != "":
                print "Granting request for '%s'" % gnthost
                grant(gnthost)
                grant_active = 1
                timeout_counter = 0
            else:
                time.sleep(2)

if __name__ == '__main__':
    main()
