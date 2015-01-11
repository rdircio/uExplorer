#!/bin/ksh

iostat -En | nawk 'ORS=NR%5?" ":"\n"'| sed 's/Soft Errors: /;/g;s/Hard Errors: /;/g;s/Transport Errors: /;/g;s/Vendor: /;/g;s/Product: /;/g;s/Revision: /;/g;s/Serial No: /;/g;s/Size: /;/g;s/Media Error: /;/g;s/Device Not Ready: /;/g;s/No Device: /;/g;s/Recoverable: /;/g;s/Illegal Request: /;/g;s/Predictive Failure Analysis: /;/g;s/ //g' > /tmp/iostat-En.$$

format < /dev/null| egrep -iv 'Specify|Search|available' | grep . | nawk 'ORS=NR%2?" ":"\n"' | tr -s ' ' | while read l;do 
	ID=`echo $l | nawk '{ print $2 }'`
	DEV=`echo $l | nawk '{ print $NF }'`
        #---- the next one is very nice, gets ONLY what is enclosed in "< >"
	SZ=`grep "${ID};" /tmp/iostat-En.$$ | awk -F";" '{ print $9 }'| nawk -v RS=">" -F'<' '{print $NF}'|sed 's/bytes//g'`
	SZ=$(( ((($SZ/1000)/1000)/1000) ))
        echo "$DEV;`grep \"${ID};\" /tmp/iostat-En.$$`" | awk -F";" '{ print "ID="$2 "\nPATH=" $1 "\nMANUFACTURER=" $6 "\nTAG=" $7 "\nSERIAL=" $9 "\nSIZE=" $10 }'
	echo "SIZEGB=$SZ"
	luxadm display /dev/rdsk/${ID}s2 | egrep 'WWN|\/dev' | sed 's/\/dev\/rdsk\///g' | tr -s " " | grep . | while read f;do
		echo "LUXADM=$f"
	done
done

echo "---------------internal"
df -kl | egrep " /$| /opt$| /var$| /usr$| /var/opt$| /var/tmp$" | awk '{ print $1 }' | awk -F'/' '{ print $NF }' |while read md;do
for l in `metastat -p $md`;do echo $l;done | grep "c[0-9]*t[0-9]*d[0-9]*s[0-9]*"
done | sort |uniq



echo "---------------CD and DVD drives"
cat /tmp/iostat-En.$$ | egrep -i "cdrom|dvd" | tr -s ' '
#--- echo "---------------TAPE drives"
#--- TODO
rm /tmp/iostat-En.$$
