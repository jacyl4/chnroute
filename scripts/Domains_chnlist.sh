#!/bin/bash

#mkdir -p ./SmartDNS_chnlist
#sudo rm -rf ./SmartDNS_chnlist/*
#wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/DNS_chn?g'>./SmartDNS_chnlist/accelerated-domains.china.conf
#wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf | sed 's/server=/nameserver /g' | rev | cut -d / -f2- | rev | sed 's?$?/DNS_chn?g'>./SmartDNS_chnlist/apple.china.conf
#
#cp -f IPchnroute ./SmartDNS_chnlist/whitelist-ip-chnlist.conf
#sed -i 's/^/whitelist-ip /g' ./SmartDNS_chnlist/whitelist-ip-chnlist.conf
#
#sha256sum ./SmartDNS_chnlist/accelerated-domains.china.conf | awk '{print$1}' >./SmartDNS_chnlist/accelerated-domains.china.conf.sha256sum
#sha256sum ./SmartDNS_chnlist/apple.china.conf | awk '{print$1}' >./SmartDNS_chnlist/apple.china.conf.sha256sum
#sha256sum ./SmartDNS_chnlist/whitelist-ip-chnlist.conf | awk '{print$1}' >./SmartDNS_chnlist/whitelist-ip-chnlist.conf.sha256sum



mkdir -p ./chnlist
cd ./chnlist
chmod +x ../scripts/mosdns

wget --show-progress --no-check-certificate -qO geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat


../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:apple
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:apple-cn
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:apple-ads
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:apple-dev
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:apple-update
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:icloud
cat geosite_apple.txt \
geosite_apple-cn.txt \
geosite_apple-ads.txt \
geosite_apple-dev.txt \
geosite_apple-update.txt \
geosite_icloud.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >../mosdns_chnlist/Domains.apple.txt


../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:category-games
cat geosite_category-games.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >../mosdns_chnlist/Domains.games.txt


../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:private
../scripts/mosdns v2dat unpack-domain -o ./ geosite.dat:cn
wget --show-progress --no-check-certificate -qO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf \
| cut -d / -f2 >Domains.chn.txt
cat geosite_private.txt \
geosite_cn.txt \
Domains.chn.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >../mosdns_chnlist/Domains.chn.txt
sed -i '/\.arpa$/d' ../mosdns_chnlist/Domains.chn.txt
echo "qpic.cn" >>../mosdns_chnlist/Domains.chn.txt


wget --show-progress --no-check-certificate -qO ../mosdns_chnlist/99-bogus-nxdomain.china.conf https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/bogus-nxdomain.china.conf


sha256sum ../mosdns_chnlist/99-bogus-nxdomain.china.conf | awk '{print$1}' >../mosdns_chnlist/99-bogus-nxdomain.china.conf.sha256sum
sha256sum ../mosdns_chnlist/Domains.chn.txt | awk '{print$1}' >../mosdns_chnlist/Domains.chn.txt.sha256sum
sha256sum ../mosdns_chnlist/Domains.apple.txt | awk '{print$1}' >../mosdns_chnlist/Domains.apple.txt.sha256sum
sha256sum ../mosdns_chnlist/Domains.games.txt | awk '{print$1}' >../mosdns_chnlist/Domains.games.txt.sha256sum


cd ..
rm -rf ./chnlist