#!/bin/ksh

prtpicl -v -c scsi-fcp | egrep 'ww|devfs' | sed 's/ //g' |awk '{ print $2 }' | nawk 'ORS=NR%3?" ":"\n"' > /tmp/piclmap.$$
luxadm qlgc | egrep -i "device:|fcode" | nawk 'ORS=NR%2?" ":"\n"'| sed 's/Opening Device: /DEVPATH=/g;s/Detected FCode Version:/FCODE_VERSION=/g;s/Host Adapter Driver: /DRIVER=/g;s/FC-AL//g' | awk '{$1=$1;print}' | sed 's/= /=/g' > /tmp/luxadm_qlgc.$$

(for c in `cfgadm -al | grep "fc-" | awk '{ print $1 }'`;do
        /usr/ucb/echo -n $c;
        luxadm -e dump_map /dev/cfg/${c} | grep Adap |while read l;do
                for w in `echo $l`;do
                        WC=`echo $w|wc -c`
                        if [ $WC -eq 17 ];then
                                /usr/ucb/echo  -n " $w "
                        fi
                done
                echo ""
        done
done
) | while read l;do
        W=`echo $l |awk '{ print $2 }'`
        L=`echo "$l " | awk '{ print $1 " p:" $2 " n:"$3 }'`
        /usr/ucb/echo -n "$L "
        P=`grep $W /tmp/piclmap.$$ | awk '{ print $3 }'`
	/usr/ucb/echo -n "$P "
	#-- -this will ONLY work if we have QLOGIC hbas
	grep $P /tmp/luxadm_qlgc.$$
done

rm /tmp/piclmap.$$
rm /tmp/luxadm_qlgc.$$
