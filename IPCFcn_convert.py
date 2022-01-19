#!/usr/bin/python3
import sys
import ipaddress

cidr = sys.argv[1]

for ip in ipaddress.IPv4Network(cidr):
	print(ip) 
