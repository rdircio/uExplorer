#!/bin/ksh

EHOME=/export/home/rdircio/uExplorer
. $EHOME/INCLUDES/settings.ksh
. $EHOME/INCLUDES/unixcmds.ksh

(
$FORMAT < /dev/null | $GREP -iv search | $GREP -i "\." | $NAWK '{ print $2 }' | while read line;do $LUXADM display /dev/rdsk/"$line"s2; done
) | egrep 'WWN|\/dev' | sed 's/\/dev\/rdsk\///g' | tr -s " "

