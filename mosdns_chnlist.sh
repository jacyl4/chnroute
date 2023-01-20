#!/bin/bash
mkdir -p ./mosdns_chnlist
sudo rm -rf ./mosdns_chnlist/*

wget -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf \
| cut -d / -f2 >./mosdns_chnlist/Domains.chn.txt


sha256sum ./mosdns_chnlist/Domains.chn.txt | awk '{print$1}' >./mosdns_chnlist/Domains.chn.txt.sha256sum
