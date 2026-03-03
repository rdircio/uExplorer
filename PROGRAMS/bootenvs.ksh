#!/bin/ksh

# Collect boot environment information via beadm (Solaris 11)

BDIR=${RESULTS}/BE
mkdir -p "$BDIR" > /dev/null 2>&1

if ! command -v beadm > /dev/null 2>&1; then
	exit 0
fi

SUMMARY="${BDIR}/summary"
: > "$SUMMARY"

# beadm list -H format (typical):
# <name>\t<active>\t<mountpoint>\t<space>\t<policy>\t<created>
beadm list -H 2>/dev/null | while IFS=$'\t' read NAME ACTIVE MOUNT SPACE POLICY CREATED REST; do
	[ -z "$NAME" ] && continue
	VAL="name=${NAME};active=${ACTIVE};mount=${MOUNT};space=${SPACE};policy=${POLICY};created=${CREATED}"
	echo "BE_${NAME}=${VAL}" >> "$SUMMARY"
done

