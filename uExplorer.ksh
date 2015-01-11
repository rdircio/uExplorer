#!/bin/ksh

EHOME=/export/home/rdircio/uExplorer
. $EHOME/INCLUDES/settings.ksh
. $EHOME/INCLUDES/unixcmds.ksh

echo "---- Getting General Info"
. ${PROGS}/general.ksh
echo "---- Getting Network Devices Information"
. ${PROGS}/nics.ksh
echo "---- Getting HBA Information"
. ${PROGS}/hbainfo.ksh
echo "---- Getting Disk Information"
df -kl | egrep -v "Filesystem| /$| /tmp$| /devices$| /opt$| /var$| /usr$| /var/opt$| /var/tmp$| /system/contract$| /proc$| /etc/mnttab$| /etc/svc/volatile$| /system/object$| /dev/fd$| /var/run$"
${PROGS}/swapinfo.pl
. ${PROGS}/disks.ksh 
. ${PROGS}/inqs.ksh
. ${PROGS}/luxadm.ksh

cd ${RESULTS}
find . -type f |while read f;do
	cat $f | while read l;do
		F=`echo $f | sed 's/\//:/g'`
		echo "$F:$l"
	done
done
