#!/bin/ksh

integer G=0
#-------------------------------------------------------------------------------------------------------
# raise x to y
raiseP(){
	x=$1
	y=$2
	integer total=1
	integer j=0
	while ((j < y));
	do
		(( total*=x ))
		(( j = j + 1 ))
	done
	$ECHO  $total
	return $total
}

#-------------------------------------------------------------------------------------------------------
# Support function for "Len2Mask"
L2M(){
	integer nmask=$1
	if [ nmask -lt 1 ];then
		$ECHO -n  "0"
		return "0"
	fi
	integer ncalc=0
	integer x=7
	while [ $x -ge 0 ];do
		integer P=`raiseP 2 $x`
		(( ncalc= ncalc + P ));
		(( nmask=nmask - 1 ));
		G=$nmask
		if [ $nmask -lt 1 ];then
			$ECHO -n $ncalc
			return $ncalc
		fi
		(( x= x - 1 ));
	done
	$ECHO -n $ncalc
	return $ncalc
}

#-------------------------------------------------------------------------------------------------------
# Converts a mask from "mask length" to decimal
Len2Mask(){
	L=$1
	if [ $L -lt 0 -o $L -gt 32 ];then
		$ECHO "Your mask length can only be 0 - 32"
		break
	fi
	L2M $L
	$ECHO -n "."
	L2M $G
	$ECHO -n "."
	L2M $G
	$ECHO -n "."
	L2M $G
}

#-------------------------------------------------------------------------------------------------------
# Converts a mask from decimal to mask length
Mask2Len(){
	M=$1
	m[0]=`$ECHO $M | awk -F"." '{ print $1 }'`
	m[1]=`$ECHO $M | awk -F"." '{ print $2 }'`
	m[2]=`$ECHO $M | awk -F"." '{ print $3 }'`
	m[3]=`$ECHO $M | awk -F"." '{ print $4 }'`
	loop=0
	mask=0
	while [ $loop -lt 4 ];do
		div=256
		while [ $div -gt 1 ];do
			let "div=$div / 2"
			let "test=${m[$loop]} - div"
			if [ ! $test -lt 0 ];then
				let "mask=$mask +1"
				m[$loop]=$test
			else
				break
			fi
		done
		let "loop=$loop+1"
	done
	$ECHO "$mask"
}

#-------------------------------------------------------------------------------------------------------
# Converts a mask from hex to decimal
hex2dec(){
	NETMASK=$1
	first=`$ECHO $NETMASK| cut -c1-2|tr "[:lower:]" "[:upper:]"`
    	FIRST=`$ECHO "ibase=16; $first"| bc`

    	second=`$ECHO $NETMASK| cut -c3-4|tr "[:lower:]" "[:upper:]"`
    	SECOND=`$ECHO "ibase=16; $second"| bc`

    	third=`$ECHO $NETMASK| cut -c5-6|tr "[:lower:]" "[:upper:]"`
    	THIRD=`$ECHO "ibase=16; $third"| bc`

    	fourth=`$ECHO $NETMASK| cut -c7-8|tr "[:lower:]" "[:upper:]"`
    	FOURTH=`$ECHO "ibase=16; $fourth"| bc`
	echo "${FIRST}.${SECOND}.${THIRD}.${FOURTH}"
}
