#!/bin/ksh

# Collect a small ZFS ARC snapshot

ZDIR=${RESULTS}/ZFS
mkdir -p "$ZDIR" > /dev/null 2>&1

if ! command -v kstat > /dev/null 2>&1; then
	exit 0
fi

ARC_FILE="${ZDIR}/arcstats"
: > "$ARC_FILE"

# Check that arcstats exists
if ! kstat -p zfs:0:arcstats:size > /dev/null 2>&1; then
	exit 0
fi

SIZE=$(kstat -p zfs:0:arcstats:size 2>/dev/null | $NAWK '{ print $NF }')
C=$(kstat -p zfs:0:arcstats:c 2>/dev/null | $NAWK '{ print $NF }')
HITS=$(kstat -p zfs:0:arcstats:hits 2>/dev/null | $NAWK '{ print $NF }')
MISSES=$(kstat -p zfs:0:arcstats:misses 2>/dev/null | $NAWK '{ print $NF }')

TOTAL=$((HITS + MISSES))
if [ "$TOTAL" -gt 0 ]; then
	RATIO_NUM=$((HITS * 100))
	ARC_HIT_RATIO=$((RATIO_NUM / TOTAL))
else
	ARC_HIT_RATIO=0
fi

echo "ARC_SIZE_BYTES=${SIZE}" >> "$ARC_FILE"
echo "ARC_TARGET_BYTES=${C}" >> "$ARC_FILE"
echo "ARC_HITS=${HITS}" >> "$ARC_FILE"
echo "ARC_MISSES=${MISSES}" >> "$ARC_FILE"
echo "ARC_HIT_RATIO_PERCENT=${ARC_HIT_RATIO}" >> "$ARC_FILE"

