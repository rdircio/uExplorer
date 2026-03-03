#!/bin/ksh

# Collect SMF services that are not online

SDIR=${RESULTS}/SMF
mkdir -p "$SDIR" > /dev/null 2>&1

if ! command -v svcs > /dev/null 2>&1; then
	exit 0
fi

PROBLEMS="${SDIR}/problems"
: > "$PROBLEMS"

# svcs -H -o state,FMRI
svcs -H -o state,FMRI 2>/dev/null | $NAWK '
$1 != "online" {
  state=$1;
  fmri=$2;
  if (fmri != "") {
    count++;
    printf "SMF_PROBLEM_%03d=state=%s;fmri=%s\n", count, state, fmri;
  }
}' >> "$PROBLEMS"

