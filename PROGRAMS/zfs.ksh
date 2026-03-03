#!/bin/ksh

# Collect ZFS pool and dataset information

ZDIR=${RESULTS}/ZFS
mkdir -p "$ZDIR" > /dev/null 2>&1

if ! command -v zpool > /dev/null 2>&1 || ! command -v zfs > /dev/null 2>&1; then
	exit 0
fi

POOLS_FILE="${ZDIR}/pools"
DATASETS_FILE="${ZDIR}/datasets"
SNAPS_FILE="${ZDIR}/snapshots"
VDEVS_FILE="${ZDIR}/vdevs"
: > "$POOLS_FILE"
: > "$DATASETS_FILE"
: > "$SNAPS_FILE"
: > "$VDEVS_FILE"

# Pools summary from zpool list
zpool list -H 2>/dev/null | while read NAME SIZE ALLOC FREE CAP HEALTH REST; do
	[ -z "$NAME" ] && continue
	echo "ZFS_POOL_${NAME}=name=${NAME};size=${SIZE};alloc=${ALLOC};free=${FREE};cap=${CAP};health=${HEALTH}" >> "$POOLS_FILE"
done

# Datasets summary from zfs list
zfs list -H -o name,used,avail,refer,recordsize,compress,mountpoint 2>/dev/null | while read NAME USED AVAIL REFER RECSZ COMP MNT; do
	[ -z "$NAME" ] && continue
	echo "ZFS_DSET_${NAME}=name=${NAME};used=${USED};avail=${AVAIL};refer=${REFER};recordsize=${RECSZ};compress=${COMP};mountpoint=${MNT}" >> "$DATASETS_FILE"
done

# Snapshots (basic info)
zfs list -H -t snapshot -o name,used,creation 2>/dev/null | while read NAME USED CREATED; do
	[ -z "$NAME" ] && continue
	echo "ZFS_SNAP_${NAME}=name=${NAME};used=${USED};created=${CREATED}" >> "$SNAPS_FILE"
done

# Vdev devices from zpool status -v (only real leaf devices)
zpool status -v 2>/dev/null | $NAWK '
/^  pool:/    { pool=$2; next }
/^\tpool/     { pool=$2; next }
/^\s*config:/ { next }
/^\s*NAME/    { next }
/^\s*state:/  { next }
/^\s*scan:/   { next }
/^\s*errors:/ { next }
/^\s*$/       { next }
{
  # Expect lines like: "  c1d0  ONLINE  0  0  0"
  name=$1;
  state=$2;
  if (name=="" || state=="") next;
  # skip pool name and aggregate vdevs
  if (name==pool) next;
  if (name ~ /^(mirror|raidz|raidz1|raidz2|raidz3|logs|log|spares|spare)$/) next;
  printf "ZFS_VDEV_%s=dev=%s\n", name, name;
}' >> "$VDEVS_FILE"

