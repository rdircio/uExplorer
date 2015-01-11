#!/bin/ksh

PLAT=`uname -s`
if [ $PLAT = "SunOS" ];then
	IFCONFIG=/usr/sbin/ifconfig
	ECHO=/usr/ucb/echo
	NETSTAT=/usr/bin/netstat
	GREP=/usr/bin/egrep
	KSTAT=/usr/bin/kstat
	TRUSS=/usr/bin/truss
	DATE=/usr/bin/date
	PSRINFO=/usr/sbin/psrinfo
	PRTCONF=/usr/sbin/prtconf
	NDD=/usr/sbin/ndd
	NAWK=/usr/bin/nawk
	UNAME=/usr/bin/uname
	FORMAT=/usr/sbin/format
	SYSDEF=/usr/sbin/sysdef
	ISAINFO=/usr/bin/isainfo
	LUXADM=/usr/sbin/luxadm
fi

