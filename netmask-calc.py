#!/usr/bin/env python
#
# Tool for easily calculating netmask ranges
#
# Author: Nate Case <nacase@gmail.com>

import sys

def parse_ip_addr(s):
    """Return IP address in integer format, or None if invalid IPv4 address."""
    if s.count(".") != 3:
        return None

    addr = 0x00
    octets = s.split(".")
    for octet in octets:
        n = int(octet)
        if (n < 0 or n > 255):
            return None
        addr = addr | n
        addr = addr << 8
    addr = addr >> 8
    return addr

def ip_addr_to_str(addr):
    """Convert an integer to a printable IP address string."""
    octets = []
    for x in range(0,4):
        octets.append(addr & 0xff)
        addr = addr >> 8
    octets.reverse()
    s = ""
    for octet in octets:
        s = s + str(octet) + "."
    return s[:-1]

def calc_netmask_len(netmask):
    """Return the netmask length from a given netmask. e.g. 255.255.255.0
    would return 24."""
    if netmask == 0:
        return 0
    first_zero = 31
    for x in range(31,-1,-1):
        bit = (netmask >> x) & 1
        if bit == 0:
            return 31-x
    return 32

def netmask_class(netmask_len):
    if netmask_len == 8:
        return "A"
    elif netmask_len == 16:
        return "B"
    elif netmask_len == 24:
        return "C"
    else:
        return None

def usage():
    sys.stderr.write("usage: %s <ip address[/netmask length]> [netmask]\n" \
                            % sys.argv[0])
    sys.stderr.write("\n")
    sys.stderr.write("You must specify either the netmask length or netmask\n")
    sys.exit(-1)

if len(sys.argv) < 2:
    usage()

ipaddr = 0
netmask_len = 0
netmask = 0

if sys.argv[1].count("/") == 1:
    (ipaddr_s, netmask_len_s) = sys.argv[1].split("/")
    ipaddr = parse_ip_addr(ipaddr_s)
    netmask_len = int(netmask_len_s)
    if not ipaddr:
        sys.stderr.write("Invalid IP address '%s' given\n" % ipaddr_s)
        sys.exit(-2)
    if netmask_len < 0 or netmask_len > 32:
        sys.stderr.write("Invalid netmask length '%d' given\n" % netmask_len)
        sys.exit(-3)
    netmask = ((2**netmask_len) - 1) << (32-netmask_len)
else:
    if len(sys.argv) < 3:
        usage()
    ipaddr = parse_ip_addr(sys.argv[1])
    if not ipaddr:
        sys.stderr.write("Invalid IP address '%s' given\n" % sys.argv[1])
        sys.exit(-2)
    netmask = parse_ip_addr(sys.argv[2])
    if not netmask:
        sys.stderr.write("Invalid netmask '%s' given\n" % sys.argv[2])
        sys.exit(-4)
    netmask_len = calc_netmask_len(netmask)

ip_addr_lo = ipaddr & netmask
# Highest address, aka the broadcast address
ip_addr_hi = ipaddr | (~netmask & 0xffffffff)
# excludes broadcast
num_valid_hosts = 2**(32 - netmask_len) - 2

print "IP address                      : %s" % ip_addr_to_str(ipaddr)
print "Netmask                         : %s" % ip_addr_to_str(netmask)
print "Netmask length                  : %d" % netmask_len
print "Subnet address (lowest addr)    : %s" % ip_addr_to_str(ip_addr_lo)
print "Broadcast (highest addr)        : %s" % ip_addr_to_str(ip_addr_hi)
print "# valid hosts allowed           : %d" % num_valid_hosts
print "(excludes broadcast)"
print ""
