#!/bin/sh
mkdir -p ./pbr
cd ./pbr

#电信
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/chinatelecom.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/chinatelecom_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > ct.txt
#联通
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/unicom_cnc.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/unicom_cnc_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > cu.txt
#移动
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/cmcc.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/cmcc_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > cm.txt
#广电
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/chinabtn.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/chinabtn_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > cbtn.txt
#教育网
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/cernet.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/cernet_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > cernet.txt
#长城宽带/鹏博士
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/gwbn.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/gwbn_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > gwbn.txt
#其他
{
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/othernet.txt
  wget --show-progress --no-check-certificate -qO- https://ispip.clang.cn/othernet_apnic.txt
} | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" \
  | python3 ../scripts/ip_cidr_dedupe.py > other.txt

{
echo "/ip route rule"

for net in $(cat ct.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done

for net in $(cat cu.txt) ; do
  echo "add dst-address=$net action=lookup table=CMCC"
done

for net in $(cat cm.txt) ; do
  echo "add dst-address=$net action=lookup table=CMCC"
done

for net in $(cat cbtn.txt) ; do
  echo "add dst-address=$net action=lookup table=CMCC"
done

for net in $(cat cernet.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done

for net in $(cat gwbn.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done

for net in $(cat other.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done
} > ../ros-pbr-CT-CMCC.rsc


{
echo "/ip firewall address-list"

for net in $(cat ct.txt) ; do
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat cu.txt) ; do
  echo "add list=dpbr-CMCC address=$net"
done

for net in $(cat cm.txt) ; do
  echo "add list=dpbr-CMCC address=$net"
done

for net in $(cat cbtn.txt) ; do
  echo "add list=dpbr-CMCC address=$net"
done

for net in $(cat cernet.txt) ; do
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat gwbn.txt) ; do
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat other.txt) ; do
  echo "add list=dpbr-CT address=$net"
done
} > ../ros-dpbr-CT-CMCC.rsc


######电信联通
{
echo "/ip firewall address-list"

for net in $(cat ct.txt) ; do
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat cu.txt) ; do
  echo "add list=dpbr-CU address=$net"
done

for net in $(cat cm.txt) ; do
  echo "add list=dpbr-CU address=$net"
done

for net in $(cat cbtn.txt) ; do
  echo "add list=dpbr-CU address=$net"
done

for net in $(cat cernet.txt) ; do
  echo "add list=dpbr-CU address=$net"
done

for net in $(cat gwbn.txt) ; do
  echo "add list=dpbr-CU address=$net"
done

for net in $(cat other.txt) ; do
  echo "add list=dpbr-CU address=$net"
done
} > ../ros-dpbr-CT-CU.rsc


cd ..
rm -rf ./pbr
