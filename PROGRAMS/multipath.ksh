#!/bin/ksh

echo "running check"
(
echo "MPXIO ?"
echo "---------------------------------------------------"
modinfo | grep -i vhci
M=`modinfo |grep -i vhci | wc -l`
if [ $M -gt 0 ];then
echo "enabled"
else
echo "disabled"
fi
echo ""

echo "POWERPATH ?"
echo "---------------------------------------------------"
modinfo | grep -i emcp
P=`modinfo |grep -i emcp | wc -l`
if [ $P -gt 0 ];then
echo "enabled"
else
echo "disabled"
fi
echo ""

echo "VXDMP ?"
echo "---------------------------------------------------"
modinfo | grep -i vxdmp
V=`modinfo |grep -i vxdmp | wc -l`
if [ $V -gt 0 ];then
echo "enabled"
else
echo "disabled"
fi
echo ""


if [ $P -gt 0 ];then
echo "POWERPATH"
echo "---------------------------------------------------"
/etc/powermt display dev=all
fi

if [ $V -gt 0 ];then
echo "VXDMP"
echo "---------------------------------------------------"
vxdmpadm listctlr all
fi

if [ $M -gt 0 ];then
echo "LUXADM"
echo "---------------------------------------------------"
for d in `format < /dev/null| egrep 'HIT|EMC' | awk '{ print $2 }'`;do
echo $d
luxadm display /dev/rdsk/${d}s2
done
fi

if [ -f /usr/sbin/vxdisk ];then
echo "VXDISK LIST"
echo "---------------------------------------------------"
for d in `/usr/sbin/vxdisk -o alldgs list| awk '{ print $1 }'`;do
echo $d
/usr/sbin/vxdisk list $d
done
fi
) 
