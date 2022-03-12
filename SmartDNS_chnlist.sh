#!/bin/bash
mkdir -p ./SmartDNS_chnlist
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/accelerated-domains.china.conf
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/apple.china.conf
wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/chnDNS?g'>./SmartDNS_chnlist/google.china.conf

sha256sum ./SmartDNS_chnlist/accelerated-domains.china.conf | awk '{print$1}' >./SmartDNS_chnlist/accelerated-domains.china.conf.sha256sum
sha256sum ./SmartDNS_chnlist/apple.china.conf | awk '{print$1}' >./SmartDNS_chnlist/apple.china.conf.sha256sum
sha256sum ./SmartDNS_chnlist/google.china.confIPchnroute | awk '{print$1}' >./SmartDNS_chnlist/google.china.confIPchnroute.sha256sum

cp -f IPchnroute ./SmartDNS_chnlist/whitelist-ip-chnlist
sed -i 's/^/whitelist-ip /g' ./SmartDNS_chnlist/whitelist-ip-chnlist
