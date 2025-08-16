#!/bin/sh
mkdir -p ./pbr
cd ./pbr

#电信
wget --no-check-certificate -c -O ct.txt https://ispip.clang.cn/chinatelecom_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" ct.txt > ct.txt.tmp; mv ct.txt.tmp ct.txt
#联通
wget --no-check-certificate -c -O cu.txt https://ispip.clang.cn/unicom_cnc_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" cu.txt > cu.txt.tmp; mv cu.txt.tmp cu.txt
#移动
wget --no-check-certificate -c -O cm.txt https://ispip.clang.cn/cmcc_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" cm.txt > cm.txt.tmp; mv cm.txt.tmp cm.txt
#铁通
wget --no-check-certificate -c -O crtc.txt https://ispip.clang.cn/crtc_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" crtc.txt > crtc.txt.tmp; mv crtc.txt.tmp crtc.txt
#教育网
wget --no-check-certificate -c -O cernet.txt https://ispip.clang.cn/cernet_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" cernet.txt > cernet.txt.tmp; mv cernet.txt.tmp cernet.txt
#长城宽带/鹏博士
wget --no-check-certificate -c -O gwbn.txt https://ispip.clang.cn/gwbn_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" gwbn.txt > gwbn.txt.tmp; mv gwbn.txt.tmp gwbn.txt
#其他
wget --no-check-certificate -c -O other.txt https://ispip.clang.cn/othernet_cidr.txt
grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}(\/[0-9]{1,2})?" other.txt > other.txt.tmp; mv other.txt.tmp other.txt

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
