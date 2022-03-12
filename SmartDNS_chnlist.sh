#!/bin/bash
mkdir -p ./SmartDNS_chnlist
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/accelerated-domains.china.conf
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/apple.china.conf
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/google.china.conf
