#!/bin/ksh

####- These speed constants are not used, but are good to remind us
C_CE=1000 #---gigabit capable
C_BGE=1000 #---gigabit capable
C_HME=100 #---NON gigabit capable
C_GE=1000 #---gigabit capable
C_ERI=100 #---NON gigabit capable
C_QFE=100 #---NON gigabit capable
C_E1000G=1000 #---gigabit capable
C_LE=10 #---NON gigabit capable, ONLY 10hdx
C_IPRB=1000 #---gigabit capable
C_DMFE=1000 #---gigabit capable

stats(){
        INTERFACE=$1
        LINE=`$NETSTAT -in | grep -i $INTERFACE`
        IERR=`echo $LINE | awk '{ print $6 }'`
        OERR=`echo $LINE | awk '{ print $8 }'`
        COLL=`echo $LINE | awk '{ print $9 }'`
#        echo "$IERR,$OERR,$COLL"
	echo "IERR=$IERR"
	echo "OERR=$OERR"
	echo "COLL=$COLL"
}

downgraded(){
	IF=$1
	SP=$2
	DUP=$3
	M=`model $IF`
	if [ $M = "ce" -o $M = "bge" -o $M = "ge" -o $M = "e1000g" -o $M = "iprb" -o $M = "dmfe" ];then
		if  [ $SP -lt 1000 ];then
			echo "DOWNGRADED=true"
		else
			echo "DOWNGRADED=false"
		fi
	else
                if  [ $SP -lt 100 ];then
                        echo "DOWNGRADED=true"
                else
                        echo "DOWNGRADED=false"
                fi
	fi
	if [ $DUP = "half" ];then
		echo "DOWNGRADED=true"
	fi
}

model(){
	INTERFACE=$1
	$ECHO $INTERFACE | awk '/^ce[0-9]+/ { print "ce" }'
	$ECHO $INTERFACE | awk '/^bge[0-9]+/ { print "bge" }'
	$ECHO $INTERFACE | awk '/^hme[0-9]+/ { print "hme" }'
	$ECHO $INTERFACE | awk '/^ge[0-9]+/ { print "ge" }'
	$ECHO $INTERFACE | awk '/^eri[0-9]+/ { print "eri" }'
	$ECHO $INTERFACE | awk '/^qfe[0-9]+/ { print "qfe" }'
	$ECHO $INTERFACE | awk '/^e1000g[0-9]+/ { print "e1000g" }'
	$ECHO $INTERFACE | awk '/^le[0-9]+/ { print "le" }'
	$ECHO $INTERFACE | awk '/^iprb[0-9]+/ { print "iprb" }'
	$ECHO $INTERFACE | awk '/^dmfe[0-9]+/ { print "dmfe" }'
}

instance(){
	INTERFACE=$1
	M=`model $INTERFACE`
	L=`$ECHO $M | wc -c`
	I=`$ECHO $INTERFACE | cut -c ${L}-`
	echo $I
}

speed(){
	MODEL=$1
	INSTANCE=$2
	INTERFACE="${MODEL}${INSTANCE}"
	DOWNGRADED="false"
	# Note: "ce" interfaces can be "UP" in "$IFCONFIG" but have link down
	$IFCONFIG $INTERFACE | grep "^$INTERFACE:.*<UP," > /dev/null 2>&1 || continue
	$ECHO $INTERFACE | grep "^cip" > /dev/null 2>&1 && continue
	MODEL=`model $INTERFACE`
	INSTANCE=`instance $INTERFACE`
	if [ $MODEL = "ce" -o $MODEL = "e1000g" ]; then
		kstat $MODEL:$INSTANCE > /tmp/kstat.$$
      DUPLEX=`cat /tmp/kstat.$$ | grep link_duplex | awk '{ print $2 }'`
      case "$DUPLEX" in
         0) DUPLEX="link down" ;;
         1) DUPLEX="half" ;;
         2) DUPLEX="full" ;;
      esac
      SPEED=`cat /tmp/kstat.$$ | grep link_speed | awk '{ print $2 }'`
      case "$SPEED" in
         0) SPEED="link down" ;;
         10) SPEED="10" ;;
         100) SPEED="100" ;;
         1000) SPEED="1000" ;;
      esac
      AUTO=`cat /tmp/kstat.$$ | grep adv_cap_autoneg | awk '{ print $2 }'`
	if [ !"$AUTO" ];then
		ndd -set /dev/${MODEL} instance ${INSTANCE}
		AUTO=`ndd -get /dev/${MODEL} adv_autoneg_cap`
	fi
        case "$AUTO" in
                0) AUTO="off" ;;
                1) AUTO="on" ;;
        esac
	rm /tmp/kstat.$$
   # "dmfe" interfaces
   elif [ "`$ECHO $INTERFACE | awk '/^dmfe[0-9]+/ { print }'`" ] ; then
      if [ "`id | cut -c1-5`" != "uid=0" ] ; then
         $ECHO "You must be the root user to determine ${MODEL}${INSTANCE} speed and duplex information."
	 continue
      fi
      DUPLEX=`ndd /dev/${INTERFACE} link_mode`
      case "$DUPLEX" in
         0) DUPLEX="half" ;;
         1) DUPLEX="full" ;;
      esac
      SPEED=`ndd /dev/${INTERFACE} link_speed`
      case "$SPEED" in
         10) SPEED="10" ;;
         100) SPEED="100" ;;
         1000) SPEED="1000" ;;
      esac
      AUTO=`ndd /dev/${INTERFACE}  adv_autoneg_cap`
        case "$AUTO" in
                0) AUTO="off" ;;
                1) AUTO="on" ;;
        esac
   # "bge" and "iprb" interfaces
   elif [ "`$ECHO $INTERFACE | awk '/^iprb[0-9]+|bge[0-9]+/ { print }'`" ] ; then
      # Determine the bge|iprb interface number
      kstat $MODEL:$INSTANCE > /tmp/kstat.$$
      DUPLEX=`cat /tmp/kstat.$$ | grep duplex | awk '{ print $2 }'`
      SPEED=`cat /tmp/kstat.$$ | grep ifspeed | awk '{ print $2 }'`
      case "$SPEED" in
         10000000) SPEED="10" ;;
         100000000) SPEED="100" ;;
         1000000000) SPEED="1000" ;;
      esac
      AUTO=`cat /tmp/kstat.$$ | grep adv_cap_autoneg | awk '{ print $2 }'`
        case "$AUTO" in
                0) AUTO="off" ;;
                1) AUTO="on" ;;
        esac
	rm /tmp/kstat.$$
   elif [ "`$ECHO $INTERFACE | awk '/^e1000g[0-9]+/ { print }'`" ] ; then
      # The duplex for e1000g devices can only be found with "dladm"
      DUPLEX=`dladm show-dev $INTERFACE | awk '{ print $NF }'`
      SPEED=`kstat e1000g:$INSTANCE | grep ifspeed | awk '{ print $2 }'`
      case "$SPEED" in
         10000000) SPEED="10" ;;
         100000000) SPEED="100" ;;
         1000000000) SPEED="1000" ;;
      esac
   # le interfaces are always 10 Mbit half-duplex
   elif [ "`$ECHO $INTERFACE | awk '/^le[0-9]+/ { print }'`" ] ; then
      DUPLEX="half"
      SPEED="10"
	AUTO="off"
   # All other interfaces
   else
      # Only the root user should run "ndd"
      if [ "`id | cut -c1-5`" != "uid=0" ] ; then
         $ECHO "You must be the root user to determine ${MODEL}${INSTANCE} speed and duplex information."
	 continue
      fi
      ndd -set /dev/$MODEL instance $INSTANCE
      SPEED=`ndd -get /dev/$MODEL link_speed|sed 's/[a-zA-Z]//g'`
      case "$SPEED" in
         0) SPEED="10" ;;
         1) SPEED="100" ;;
         1000) SPEED="1000" ;;
      esac
      DUPLEX=`ndd -get /dev/$MODEL link_mode`
      case "$DUPLEX" in
         0) DUPLEX="half" ;;
         1) DUPLEX="full" ;;
         *) DUPLEX="" ;;
      esac
	if [ $MODEL = "ge" ];then
		AUTO=`ndd -get /dev/$MODEL adv_1000autoneg_cap`
	        case "$AUTO" in
                	0) AUTO="off" ;;
               	 	1) AUTO="on" ;;
        	esac
	else
      		AUTO=`ndd /dev/$MODEL  adv_autoneg_cap`
        	case "$AUTO" in
                	0) AUTO="off" ;;
                	1) AUTO="on" ;;
        	esac
	fi

   fi
   DOWNGRADED=`downgraded $INTERFACE $SPEED $DUPLEX`
#   $ECHO "$SPEED,$DUPLEX,$AUTO,$DOWNGRADED"
    	$ECHO "SPEED=$SPEED"
	$ECHO "DUPLEX=$DUPLEX"
	$ECHO "AUTONEG=$AUTO"
	$ECHO "$DOWNGRADED"
}
