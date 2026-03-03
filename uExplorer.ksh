#!/bin/ksh

EHOME=`cd "$(dirname "$0")" && pwd`
. $EHOME/INCLUDES/settings.ksh
. $EHOME/INCLUDES/unixcmds.ksh

echo "---- Getting General Info"
. ${PROGS}/general.ksh
echo "---- Getting Network Devices Information"
. ${PROGS}/nics.ksh
echo "---- Getting HBA Information"
. ${PROGS}/hbainfo.ksh
echo "---- Getting Disk Information"
df -kl | egrep -v "Filesystem| /$| /tmp$| /devices$| /opt$| /var$| /usr$| /var/opt$| /var/tmp$| /system/contract$| /proc$| /etc/mnttab$| /etc/svc/volatile$| /system/object$| /dev/fd$| /var/run$"
${PROGS}/swapinfo.pl
. ${PROGS}/disks.ksh 
. ${PROGS}/inqs.ksh
. ${PROGS}/luxadm.ksh
echo "---- Getting Zones Information"
. ${PROGS}/zones.ksh
echo "---- Getting ZFS Information"
. ${PROGS}/zfs.ksh
. ${PROGS}/zfs_arc.ksh
echo "---- Getting Boot Environments"
. ${PROGS}/bootenvs.ksh
echo "---- Getting SMF Issues"
. ${PROGS}/smf.ksh
echo "---- Getting Package Information"
. ${PROGS}/pkg.ksh

cd ${RESULTS}
FLAT=${RESULTS}/flat.txt
find . -type f ! -name 'core' ! -name 'core.*' |while read f;do
	cat $f | while read l;do
		F=`echo $f | sed 's/\//:/g'`
		echo "$F:$l"
	done
done | tee "$FLAT"

# Generate simple HTML report
HTML=${RESULTS}/report.html
(
echo '<!DOCTYPE html>'
echo '<html><head><meta charset="UTF-8"><title>uExplorer System Report</title>'
echo '<style>body{font-family:Arial,Helvetica,sans-serif;margin:20px;background:#f5f5f5;color:#333}h1{color:#222}h2{margin-top:1.5em}table{border-collapse:collapse;margin-bottom:1.5em;background:#fff}th,td{border:1px solid #ccc;padding:4px 8px}th{background:#eee;text-align:left}.section{padding:12px 16px;background:#fff;border:1px solid #ddd;margin-bottom:16px;border-radius:4px}</style>'
echo '</head><body>'
echo '<h1>uExplorer System Report</h1>'

echo '<div class="section"><h2>General Summary</h2><table>'
$NAWK -F':' '
/^\.:summary:/ {
  # payload is everything after "summary:"
  idx = index($0, "summary:");
  if (idx > 0) {
    payload = substr($0, idx + length("summary:"));
    # split payload at first "=" into KEY and VALUE (VALUE may contain spaces/colons)
    eq = index(payload, "=");
    if (eq > 0) {
      key = substr(payload, 1, eq-1);
      val = substr(payload, eq+1);
      if (key != "") {
        printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
      }
    }
  }
}
# collect ZFS pool totals
/^\.:ZFS:pools:/ {
  ip = index($0, "ZFS:pools:");
  if (ip > 0) {
    payp = substr($0, ip + length("ZFS:pools:"));
    ep = index(payp, "=");
    if (ep > 0) {
      kp = substr(payp, 1, ep-1);
      vp = substr(payp, ep+1);
      if (kp ~ /^ZFS_POOL_/) {
        n = split(vp, pf, ";");
        size=""; alloc=""; freev="";
        for (i=1; i<=n; i++) {
          split(pf[i], f, "=");
          if (f[1]=="size") size=f[2];
          else if (f[1]=="alloc") alloc=f[2];
          else if (f[1]=="free") freev=f[2];
        }
        if (size != "") totsize += toBytes(size);
        if (alloc != "") totalalloc += toBytes(alloc);
        if (freev != "") totalfree += toBytes(freev);
      }
    }
  }
}
# collect ZFS vdev base disks
/^\.:ZFS:vdevs:/ {
  iv = index($0, "ZFS:vdevs:");
  if (iv > 0) {
    payv = substr($0, iv + length("ZFS:vdevs:"));
    ev = index(payv, "=");
    if (ev > 0) {
      kv = substr(payv, 1, ev-1);
      vv = substr(payv, ev+1);
      if (kv ~ /^ZFS_VDEV_/) {
        dev = vv;
        gsub(/s[0-9]+$/,"",dev);
        zfsdisk[dev]=1;
      }
    }
  }
}
# collect disk sizes from PROGRAMS/disks.ksh output
/:PROGRAMS:disks.ksh:/ {
  idd = index($0, "PROGRAMS:disks.ksh:");
  if (idd > 0) {
    payd = substr($0, idd + length("PROGRAMS:disks.ksh:"));
    ed = index(payd, "=");
    if (ed > 0) {
      kd = substr(payd, 1, ed-1);
      vd = substr(payd, ed+1);
      if (kd=="ID") {
        curdisk = vd;
      } else if (kd=="SIZEGB" && curdisk != "") {
        szgb = vd + 0;
        disksize[curdisk]=szgb;
      }
    }
  }
}
END {
  if (totsize > 0) {
    printf "<tr><th>Total ZFS pool size (GiB)</th><td>%.1f</td></tr>\n", totsize / (1024*1024*1024);
  }
  if (totalalloc > 0) {
    printf "<tr><th>Total ZFS disk used (GiB)</th><td>%.1f</td></tr>\n", totalalloc / (1024*1024*1024);
  }
  if (totalfree > 0) {
    printf "<tr><th>Total ZFS disk free (GiB)</th><td>%.1f</td></tr>\n", totalfree / (1024*1024*1024);
  }
  # sum non-ZFS disk capacities (in GiB directly from SIZEGB)
  for (d in disksize) {
    base=d;
    if (base in zfsdisk) {
      continue;
    }
    nonzfs_total += disksize[d];
  }
  if (nonzfs_total > 0) {
    printf "<tr><th>Total non-ZFS disk size (GiB)</th><td>%.1f</td></tr>\n", nonzfs_total;
  }
}
function toBytes(s,   num,unit) {
  num = s;
  unit = "";
  if (s ~ /[KMGTP]$/) {
    unit = substr(s, length(s), 1);
    num = substr(s, 1, length(s)-1);
  }
  num += 0;
  if (unit=="K") return num * 1024;
  if (unit=="M") return num * 1024 * 1024;
  if (unit=="G") return num * 1024 * 1024 * 1024;
  if (unit=="T") return num * 1024 * 1024 * 1024 * 1024;
  return num;
}
' "$FLAT"
echo '</table></div>'

echo '<div class="section"><h2>Network Summary</h2><table>'
$NAWK '
/^\.:NETWORK:summary:/ {
  idx = index($0, "NETWORK:summary:");
  if (idx > 0) {
    payload = substr($0, idx + length("NETWORK:summary:"));
    eq = index(payload, "=");
    if (eq > 0) {
      key = substr(payload, 1, eq-1);
      val = substr(payload, eq+1);
      if (key != "") {
        printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
      }
    }
  }
}' "$FLAT"
echo '</table></div>'

echo '<div class="section"><h2>Network Interfaces</h2>'
$NAWK '
/^\.:NETWORK:NICS:/ {
  idx = index($0, "NETWORK:NICS:");
  if (idx <= 0) next;
  rest = substr($0, idx + length("NETWORK:NICS:"));
  eq = index(rest, "=");
  if (eq <= 0) next;
  left = substr(rest, 1, eq-1);  # <id>[:...]:KEY
  val  = substr(rest, eq+1);     # VALUE
  # find last colon in left to split id and key
  lastc = 0;
  for (i=1; i<=length(left); i++) {
    ch = substr(left, i, 1);
    if (ch == ":") lastc = i;
  }
  if (lastc <= 0) next;
  id  = substr(left, 1, lastc-1);
  key = substr(left, lastc+1);
  if (key == "") next;
  ids[id]=1;
  store[id, key]=val;
}
END {
  for (id in ids) {
    printf "<h3>%s</h3><table>\n", id;
    for (k in store) {
      split(k, parts, SUBSEP);
      if (parts[1] != id) continue;
      key = parts[2];
      val = store[k];
      printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
    }
    printf "</table>\n";
  }
}' "$FLAT"
echo '</div>'

echo '<div class="section"><h2>Zones</h2><table>'
$NAWK '
/^\.:ZONES:summary:/ {
  idx = index($0, "ZONES:summary:");
  if (idx > 0) {
    payload = substr($0, idx + length("ZONES:summary:"));
    eq = index(payload, "=");
    if (eq > 0) {
      key = substr(payload, 1, eq-1);
      val = substr(payload, eq+1);
      if (key != "") {
        printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
      }
    }
  }
}' "$FLAT"
echo '</table></div>'

echo '<div class="section"><h2>ZFS Pools</h2>'
$NAWK '
/^\.:ZFS:pools:/ {
  idx = index($0, "ZFS:pools:");
  if (idx <= 0) next;
  payload = substr($0, idx + length("ZFS:pools:"));
  eq = index(payload, "=");
  if (eq <= 0) next;
  key = substr(payload, 1, eq-1);
  val = substr(payload, eq+1);
  if (key !~ /^ZFS_POOL_/) next;
  pool = key;
  sub(/^ZFS_POOL_/,"",pool);
  n = split(val, fields, ";");
  printf "<h3>%s</h3><table>\n", pool;
  for (i=1; i<=n; i++) {
    split(fields[i], f, "=");
    if (f[1] != "") {
      printf "<tr><th>%s</th><td>%s</td></tr>\n", f[1], f[2];
    }
  }
  printf "</table>\n";
}' "$FLAT"
echo '</div>'

echo '<div class="section"><h2>ZFS Datasets</h2>'
$NAWK '
/^\.:ZFS:datasets:/ {
  idx = index($0, "ZFS:datasets:");
  if (idx <= 0) next;
  payload = substr($0, idx + length("ZFS:datasets:"));
  eq = index(payload, "=");
  if (eq <= 0) next;
  key = substr(payload, 1, eq-1);
  val = substr(payload, eq+1);
  if (key !~ /^ZFS_DSET_/) next;
  ds = key;
  sub(/^ZFS_DSET_/,"",ds);
  n = split(val, fields, ";");
  printf "<h3>%s</h3><table>\n", ds;
  for (i=1; i<=n; i++) {
    split(fields[i], f, "=");
    if (f[1] != "") {
      printf "<tr><th>%s</th><td>%s</td></tr>\n", f[1], f[2];
    }
  }
  printf "</table>\n";
}' "$FLAT"
echo '</div>'

echo '<div class="section"><h2>ZFS ARC Statistics</h2><table>'
$NAWK '
/^\.:ZFS:arcstats:/ {
  idx = index($0, "ZFS:arcstats:");
  if (idx > 0) {
    payload = substr($0, idx + length("ZFS:arcstats:"));
    eq = index(payload, "=");
    if (eq > 0) {
      key = substr(payload, 1, eq-1);
      val = substr(payload, eq+1);
      if (key != "") {
        printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
      }
    }
  }
}' "$FLAT"
echo '</table></div>'

echo '<div class="section"><h2>Boot Environments</h2>'
$NAWK '
/^\.:BE:summary:/ {
  idx = index($0, "BE:summary:");
  if (idx <= 0) next;
  payload = substr($0, idx + length("BE:summary:"));
  eq = index(payload, "=");
  if (eq <= 0) next;
  namekey = substr(payload, 1, eq-1);
  val = substr(payload, eq+1);
  be = namekey;
  sub(/^BE_/,"",be);
  n = split(val, fields, ";");
  printf "<h3>%s</h3><table>\n", be;
  for (i=1; i<=n; i++) {
    split(fields[i], f, "=");
    if (f[1] != "") {
      printf "<tr><th>%s</th><td>%s</td></tr>\n", f[1], f[2];
    }
  }
  printf "</table>\n";
}' "$FLAT"
echo '</div>'

echo '<div class="section"><h2>SMF Problem Services</h2><table>'
$NAWK '
/^\.:SMF:problems:/ {
  idx = index($0, "SMF:problems:");
  if (idx <= 0) next;
  payload = substr($0, idx + length("SMF:problems:"));
  eq = index(payload, "=");
  if (eq <= 0) next;
  val = substr(payload, eq+1);  # everything after first "="
  n = split(val, fields, ";");
  state=""; fmri="";
  for (i=1; i<=n; i++) {
    split(fields[i], f, "=");
    if (f[1]=="state") state=f[2];
    else if (f[1]=="fmri") fmri=f[2];
  }
  if (fmri != "") {
    printf "<tr><td>%s</td><td>%s</td></tr>\n", state, fmri;
  }
}' "$FLAT"
echo '</table></div>'

echo '<div class="section"><h2>IPS / Packages</h2>'
echo '<h3>Summary</h3><table>'
$NAWK '
/^\.:PKG:summary:/ {
  idx = index($0, "PKG:summary:");
  if (idx > 0) {
    payload = substr($0, idx + length("PKG:summary:"));
    eq = index(payload, "=");
    if (eq > 0) {
      key = substr(payload, 1, eq-1);
      val = substr(payload, eq+1);
      if (key != "") {
        printf "<tr><th>%s</th><td>%s</td></tr>\n", key, val;
      }
    }
  }
}' "$FLAT"
echo '</table>'
echo '<h3>Publishers</h3><table>'
$NAWK '
/^\.:PKG:publishers:/ {
  idx = index($0, "PKG:publishers:");
  if (idx <= 0) next;
  payload = substr($0, idx + length("PKG:publishers:"));
  eq = index(payload, "=");
  if (eq <= 0) next;
  val = substr(payload, eq+1);  # after first "="
  n = split(val, fields, ";");
  name=""; origin="";
  for (i=1; i<=n; i++) {
    split(fields[i], f, "=");
    if (f[1]=="name") name=f[2];
    else if (f[1]=="origin") origin=f[2];
  }
  if (name != "") {
    printf "<tr><td>%s</td><td>%s</td></tr>\n", name, origin;
  }
}' "$FLAT"
echo '</table></div>'

echo '</body></html>'
) > "$HTML"

echo "HTML report written to: $HTML"
