#!/bin/ksh

R=`uname -r`

NAME=`$UNAME -n`
HOSTID=`hostid`
KERNEL=`$UNAME -v`
if [ $R = "5.8" ];then
        NCPUS_P=`$PSRINFO -v | $GREP -i operates | wc -l | tr -s " "`
else
        NCPUS_P=`$PSRINFO -p`
fi
NCPUS_L=`$KSTAT -p 'cpu_info:::clock_MHz' | wc -l|sed 's/ //g'`
CPU_MODEL=`$KSTAT -p 'cpu_info:*::implementation' | $NAWK '{ print $2 }' | sort | uniq`
SPEED=`$KSTAT -p 'cpu_info:::clock_MHz' | $NAWK '{ print $2 "Mhz" }'| sort | uniq -c |$NAWK '{ print $1 "x" $2 }'| tr -s '\n' ' '`
MEM=`$PRTCONF | $GREP Mem | $NAWK -F':' '{ print $2 }'`
PLAT=`$PRTCONF -pv|$GREP banner-name|$NAWK -F"'" '{ print $2 }'`
PLAT2=`$UNAME -i`
SRELEASE=`$UNAME -sr`
RELEASE=`cat /etc/release | head -1 | tr -s ' '`
NDISKS=`$FORMAT < /dev/null| $GREP "\." | $GREP -v 'Specify|Search|@' | wc -l | tr -s " "`
KERNELTYPE=`$ISAINFO -kv`
OS="Solaris"

DAYS=0
BTS=`$KSTAT -p 'unix:0:system_misc:boot_time'|$NAWK '{ print $2 }'`
DTS=`$TRUSS $DATE 2>&1 | $NAWK '/^time/ {print $NF}'`
((TMP=$DTS - $BTS ))
DAYS=`$ECHO "scale=3;$TMP / ( 60 * 60 * 24)" | bc`
if [ $DAYS -lt 1 ];then
        U=`$ECHO "scale=3;$TMP / ( 60 * 60 )" | bc`
        UPTIME="$U hours"
else
        UPTIME="$DAYS days"
fi
L1=`$KSTAT -p 'unix:0:system_misc:avenrun_1min'|$NAWK '{ print $2 }'`
L5=`$KSTAT -p 'unix:0:system_misc:avenrun_5min'|$NAWK '{ print $2 }'`
L15=`$KSTAT -p 'unix:0:system_misc:avenrun_15min'|$NAWK '{ print $2 }'`
L1=`$ECHO "scale=3; $L1 / 256" | bc`
L5=`$ECHO "scale=3; $L5 / 256" | bc`
L15=`$ECHO "scale=3; $L15 / 256" | bc`
LOAD_AVERAGES=${L1},${L5},${L15}

(
$ECHO "DATE=`date`"
$ECHO "SYSTEM_NAME=$NAME"
$ECHO "CPU_COUNT_PHYSICAL=$NCPUS_P"
$ECHO "CPU_COUNT_LOGICAL=$NCPUS_L"
$ECHO "CPU_SPEED=$SPEED"
$ECHO "CPU_MODEL=$CPU_MODEL"
$ECHO "MEMORY=$MEM"
$ECHO "OS=$OS"
$ECHO "OS_SHORT_RELEASE=$SRELEASE"
$ECHO "OS_LONG_RELEASE=$RELEASE"
$ECHO "DISK_COUNT=$NDISKS"
$ECHO "PLATFORM=$PLAT"
$ECHO "PLATFORM2=$PLAT2"
$ECHO "KERNEL_VERSION=$KERNEL"
$ECHO "KERNEL_TYPE=$KERNELTYPE"
$ECHO "HOSTID=$HOSTID"
$ECHO "UPTIME=$UPTIME"
$ECHO "LOAD_AVERAGES=$LOAD_AVERAGES"
$ECHO "TIMEZONE=`$GREP "TZ=" /etc/TIMEZONE | $NAWK -F"=" '{ print $2 }'`"
) > ${RESULTS}/summary
