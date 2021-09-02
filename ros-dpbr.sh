#!/bin/sh
mkdir -p ./pbr
cd ./pbr

#电信
wget --no-check-certificate -c -O ct.txt https://ispip.clang.cn/chinatelecom_cidr.txt
#联通
wget --no-check-certificate -c -O cu.txt https://ispip.clang.cn/unicom_cnc_cidr.txt
#移动
wget --no-check-certificate -c -O cm.txt https://ispip.clang.cn/cmcc_cidr.txt
#铁通
wget --no-check-certificate -c -O crtc.txt https://ispip.clang.cn/crtc_cidr.txt
#教育网
wget --no-check-certificate -c -O cernet.txt https://ispip.clang.cn/cernet_cidr.txt
#长城宽带/鹏博士
wget --no-check-certificate -c -O gwbn.txt https://ispip.clang.cn/gwbn_cidr.txt
#其他
wget --no-check-certificate -c -O other.txt https://ispip.clang.cn/othernet_cidr.txt

{
echo "/ip route rule"

for net in $(cat ct.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done

for net in $(cat cu.txt) ; do
  echo "add dst-address=$net action=lookup table=CT"
done

for net in $(cat cm.txt) ; do
  echo "add dst-address=$net action=lookup table=CMCC"
done

for net in $(cat crtc.txt) ; do
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
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat cm.txt) ; do
  echo "add list=dpbr-CMCC address=$net"
done

for net in $(cat crtc.txt) ; do
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
  echo "add list=dpbr-CT address=$net"
done

for net in $(cat crtc.txt) ; do
  echo "add list=dpbr-CT address=$net"
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
} > ../ros-dpbr-CT-CU.rsc


cd ..
rm -rf ./pbr
