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



mkdir -p ./mosdns_chnlist
sudo rm -rf ./mosdns_chnlist/*

wget --show-progress -cqO /tmp/geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat
chmod +x mosdns



./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:private
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:cn
echo "qpic.cn" >>/tmp/geosite.dat:cn

wget --show-progress -cqO- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf \
| cut -d / -f2 >/tmp/Domains.chn.txt
cat /tmp/geosite_private.txt \
/tmp/geosite_cn.txt \
/tmp/Domains.chn.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >./mosdns_chnlist/Domains.chn.txt
sed -i '/\.arpa$/d' ./mosdns_chnlist/Domains.chn.txt

./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:apple
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:apple-cn
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:apple-ads
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:apple-dev
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:apple-update
./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:icloud
cat /tmp/geosite_apple.txt \
/tmp/geosite_apple-cn.txt \
/tmp/geosite_apple-ads.txt \
/tmp/geosite_apple-dev.txt \
/tmp/geosite_apple-update.txt \
/tmp/geosite_icloud.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >./mosdns_chnlist/Domains.apple.txt



./mosdns v2dat unpack-domain -o /tmp /tmp/geosite.dat:category-games
cat /tmp/geosite_category-games.txt \
| sort | uniq | xargs -n1 | sed '/^\s*$/d' >./mosdns_chnlist/Domains.games.txt



wget --show-progress -cqO ./mosdns_chnlist/99-bogus-nxdomain.china.conf https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/bogus-nxdomain.china.conf
sha256sum ./mosdns_chnlist/99-bogus-nxdomain.china.conf | awk '{print$1}' >./mosdns_chnlist/99-bogus-nxdomain.china.conf.sha256sum

sha256sum ./mosdns_chnlist/Domains.chn.txt | awk '{print$1}' >./mosdns_chnlist/Domains.chn.txt.sha256sum
sha256sum ./mosdns_chnlist/Domains.apple.txt | awk '{print$1}' >./mosdns_chnlist/Domains.apple.txt.sha256sum
sha256sum ./mosdns_chnlist/Domains.games.txt | awk '{print$1}' >./mosdns_chnlist/Domains.games.txt.sha256sum
