#!/bin/ksh

NAME=`uname -n`
DATE=`date '+%m_%d_%y_%H:%M:%S_%Z'`
RESULTS=${EHOME}/RESULTS/${NAME}_${DATE}
PROGS=${EHOME}/PROGRAMS
mkdir -p $RESULTS > /dev/null 2>&1
