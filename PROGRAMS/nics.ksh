#!/bin/ksh

. $EHOME/INCLUDES/netmask_funcs.ksh
. $EHOME/INCLUDES/nic_funcs_solaris.ksh

NWDIR=${RESULTS}/NETWORK
NICSDIR=${NWDIR}/NICS
mkdir -p $NICSDIR > /dev/null 2>&1

NCE=`$GREP -i "\"ce\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NBGE=`$GREP -i "\"bge\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NHME=`$GREP -i "\"hme\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NGE=`$GREP -i "\"ge\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NERI=`$GREP -i "\"eri\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NQFE=`$GREP -i "\"qfe\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NE1000G=`$GREP -i "\"e1000g\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NLE=`$GREP -i "\"le\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NIPRB=`$GREP -i "\"iprb\"" /etc/path_to_inst|wc -l|sed 's/ //g'`
NDMFE=`$GREP -i "\"dmfe\"" /etc/path_to_inst|wc -l|sed 's/ //g'`

((NIC_PORTS= $NCE + $NBGE + $NHME + $NGE + $NERI + $NQFE + $NE1000G + $NLE + $NIPRB + $NDMFE ))
((GIGABIT_CAPABLE= $NCE + $NBGE + $NGE + $NE1000G + $NIPRB + $NDMFE ))
((NON_GIGABIT_CAPABLE= $NHME + $NERI + $NQFE ))
USED_NIC_PORTS=`$NETSTAT -in | $GREP -v "Name|lo|dman|clpriv" | $GREP . | wc -l| sed 's/ //g'`

(
$ECHO "NIC_PORTS=$NIC_PORTS"
$ECHO "GIGABIT_CAPABLE_PORTS=$GIGABIT_CAPABLE"
$ECHO "100FDX_CAPABLE_PORTS=$NON_GIGABIT_CAPABLE"
$ECHO "USED_NIC_PORTS=$USED_NIC_PORTS"
$ECHO "NCE=$NCE" #---gigabit capable
$ECHO "NBGE=$NBGE" #---gigabit capable
$ECHO "NHME=$NHME" #---NON gigabit capable
$ECHO "NGE=$NGE" #---gigabit capable
$ECHO "NERI=$NERI" #---NON gigabit capable
$ECHO "NQFE=$NQFE" #---NON gigabit capable
$ECHO "NE1000G=$NE1000G" #---gigabit capable
$ECHO "NLE=$NLE" #---NON gigabit capable, ONLY 10hdx
$ECHO "NIPRB=$NIPRB" #---gigabit capable
$ECHO "NDMFE=$NDMFE" #---gigabit capable
) > ${NWDIR}/summary

#---wishlist: UNUSED_GB_PORTS and UNUSED_100FDX_PORTS

$IFCONFIG -a| $GREP ":" |$GREP -v "ether|clpriv|lo|dman" | $NAWK '{ print $1 }' |  sed 's/\(.*\):/\1/' | while read i; do
	F=/tmp/${i}.$$
	$IFCONFIG $i > $F
	I=`cat $F | $GREP -v ":|group" | $NAWK '{ print $2 }'`
	E=`cat $F | $GREP "ether" | $NAWK '{ print $2 }'`
	GP=`cat $F | $GREP "groupname" | $NAWK '{ print $2 }'`
	NMH=`cat $F | $GREP -v ":" | $NAWK '{ print $4 }'`
	TMP=`$ECHO $NMH | sed 's/../ 0x&/g'`
	NMD=`printf "%d.%d.%d.%d\n" $TMP`
	M2L=`Mask2Len $NMD`
	ISVIRTUAL=`$ECHO $i | $NAWK '/:/ { print }'`
	DOWN=`cat $F | $NAWK '/DOWN/ { print }'`
	if [ "$DOWN" ];then
		STATUS="down"
	else
		STATUS="up"
	fi
	MODEL=`model $i`
	INSTANCE=`instance $i`

	FILE=${NICSDIR}/$i
	(
        $ECHO "ID=$i" 
        $ECHO "IP=$I" 
        $ECHO "ETHER=$E" 
        $ECHO "IPMP_GROUP=$GP" 
        $ECHO "NETMASK_HEX=$NMH"
        $ECHO "NETMASK_DEC=$NMD"
        $ECHO "NETMASK_LENGTH=$M2L"
        $ECHO "STATUS=$STATUS"
	if [  ! "$ISVIRTUAL" ];then
		DEV=`$GREP "$INSTANCE \"$MODEL\"" /etc/path_to_inst | $NAWK '{ print $1 }'|sed 's/"//g'`
		speed $MODEL $INSTANCE
		stats $i
	else
		$ECHO "SPEED="
		$ECHO "DUPLEX="
		$ECHO "AUTONEG="
		$ECHO "DOWNGRADED="
		$ECHO "IERR="
		$ECHO "OERR="
		$ECHO "COLL="
	fi	
	$ECHO "DEVICE=$DEV"
	) > $FILE
#	$ECHO "$i"
	rm $F
done
