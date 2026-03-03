#!/bin/ksh

# Collect IPS publisher and package summary information

PDIR=${RESULTS}/PKG
mkdir -p "$PDIR" > /dev/null 2>&1

if ! command -v pkg > /dev/null 2>&1; then
	exit 0
fi

PUB_FILE="${PDIR}/publishers"
SUM_FILE="${PDIR}/summary"
: > "$PUB_FILE"
: > "$SUM_FILE"

# Publishers (basic: name and first origin URI)
pkg publisher 2>/dev/null | $NAWK '
NR <= 3 { next }  # skip header
NF >= 1 {
  name=$1;
  origin=$NF;
  printf "PKG_PUBLISHER_%s=name=%s;origin=%s\n", name, name, origin;
}' >> "$PUB_FILE"

# Package counts
INSTALLED_COUNT=$(pkg list 2>/dev/null | $NAWK 'NR>1 { c++ } END { if (c == "") c=0; print c }')
UPGRADABLE_COUNT=$(pkg list -u 2>/dev/null | $NAWK 'NR>1 { c++ } END { if (c == "") c=0; print c }')

echo "INSTALLED_COUNT=${INSTALLED_COUNT}" >> "$SUM_FILE"
echo "UPGRADABLE_COUNT=${UPGRADABLE_COUNT}" >> "$SUM_FILE"

