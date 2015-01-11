#!/bin/ksh

EHOME=/export/home/rdircio/uExplorer
. $EHOME/INCLUDES/settings.ksh
. $EHOME/INCLUDES/unixcmds.ksh


INQ="$EHOME/PROGRAMS/INQ/inq.sol64 -no_dots"
(
$INQ -sym_wwn |$GREP . | while read l;do $ECHO "SYMMETRIX $l";done
$INQ -clar_wwn |$GREP . | while read l;do $ECHO "CLARIION $l";done
$INQ -sw_wwn |$GREP . | while read l;do $ECHO "SW $l";done
$INQ -hds_wwn |$GREP . | while read l;do $ECHO "HDS $l";done
$INQ -s80_wwn |$GREP . | while read l;do $ECHO "S80 $l";done
$INQ -invista_wwn |$GREP . | while read l;do $ECHO "INVISTA $l";done
$INQ -shark_wwn |$GREP . | while read l;do $ECHO "SHARK $l";done
$INQ -compaq_wwn |$GREP . | while read l;do $ECHO "COMPAQ $l";done
$INQ -netapp_wwn |$GREP . | while read l;do $ECHO "NETAPP $l";done
) | $GREP -v '\---------|Device|Inquiry utility|EMC Corporation|For help type' | $NAWK '{ print $1 ";" $2 ";" $NF }'
