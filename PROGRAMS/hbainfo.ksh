#!/bin/ksh

$EHOME/PROGRAMS/INQ/inq.sol64 -hba -fibre -hba_file /tmp/hbainfo.$$ -create > /dev/null 2>&1

cat /tmp/hbainfo.$$ | $GREP -iv 'hba_start|HBA_ENTRY_START|inquiry|HBA_PORT_NUMBER'| $GREP . |while read l;do
	START=`$ECHO $l | grep HBA_NAME=`
	if [ "$START" ];then
		HBAN=`$ECHO $l | $NAWK -F"=" '{ print $2 }'|sed 's/ /_/g'`
		mkdir -p ${RESULTS}/HBAS/${HBAN} > /dev/null 2>&1
		PORT=""
	else
		START=`$ECHO $l | grep HBA_PORT_WWN=`
		if [ "$START" ];then
			PORT=`$ECHO $l | $NAWK -F"=" '{ print $2 }'|sed 's/ /_/g'`
			mkdir -p ${RESULTS}/HBAS/${HBAN}/PORTS > /dev/null 2>&1
		fi
		if [ "$PORT" ];then
#			$ECHO "$HBAN/PORTS/${PORT}:$l"
			$ECHO "$l" >> ${RESULTS}/HBAS/${HBAN}/PORTS/${PORT}
		else
#			$ECHO "$HBAN/summary:$l"
			$ECHO "$l" >> ${RESULTS}/HBAS/${HBAN}/summary
		fi
	fi
done

rm /tmp/hbainfo.$$
