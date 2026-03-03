#!/bin/ksh

# Collect Solaris zones information (Solaris 10/11)

ZDIR=${RESULTS}/ZONES
mkdir -p "$ZDIR" > /dev/null 2>&1

# zoneadm may not exist (eg. non-Solaris or very old releases)
if ! command -v zoneadm > /dev/null 2>&1; then
	exit 0
fi

# Summary: count zones and emit one summary line per zone
ZONE_SUMMARY="${ZDIR}/summary"
: > "$ZONE_SUMMARY"

zoneadm list -cv 2>/dev/null | $NAWK '
NR==1 { next }  # skip header
{
  id=$1; name=$2; state=$3; path=$4; brand=$5; iptype=$6;
  count++;
  key = "ZONE_" name;
  val = "id=" id ",state=" state ",path=" path ",brand=" brand ",iptype=" iptype;
  printf "%s=%s\n", key, val;
}
END {
  printf "ZONE_COUNT=%d\n", count;
}' >> "$ZONE_SUMMARY"

# Optional: per-zone raw configuration (best-effort)
zoneadm list -p 2>/dev/null | $NAWK -F: '{ print $2 }' | while read ZN; do
	[ -z "$ZN" ] && continue
	ZF="${ZDIR}/${ZN}"
	zonecfg -z "$ZN" info 2>/dev/null > "$ZF"
done

