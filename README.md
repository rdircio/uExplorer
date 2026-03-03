## uExplorer

uExplorer is a Solaris host inventory script that connects remotely to a Solaris system, gathers configuration and capacity information, and produces a flattened text dump plus an HTML report.

### What it collects (Solaris 11–aware)

- **General system info**: hostname, OS/version, kernel, CPU (model/count/speed), memory, timezone, uptime, load averages.
- **Network**:
  - NIC counts by type/driver (including modern `net*`/VLAN interfaces).
  - Per–interface details: IPs, MAC, netmasks, status, basic error counters and link properties when available.
- **Zones**:
  - Global and non‑global zones via `zoneadm list -cv`.
  - For each zone: ID, state, zonepath, brand, IP type.
- **Disks & storage**:
  - SCSI disk inventory from `iostat -En` + `format` (ID, path, vendor/product tag, serial, size/GB).
  - Optional Solaris Volume Manager layout (if `metastat` is present).
  - HBA information via EMC `inq.sol64 -hba` when available.
- **ZFS**:
  - Pools from `zpool list` and `zpool status -v` (size, alloc, free, health, leaf devices).
  - Datasets from `zfs list` (used/avail, recordsize, compression, mountpoint).
  - Snapshots (name, used, creation time).
  - ARC snapshot from `kstat` (size, target size, hits/misses, hit ratio).
- **Boot environments**:
  - `beadm list -H` summary (name, active flags, mountpoint, space, policy, created).
- **SMF**:
  - Non‑online services (maintenance/legacy_run/etc) from `svcs -H -o state,FMRI`.
- **Packages / IPS**:
  - Installed and upgradable package counts.
  - Publishers and origins from `pkg publisher`.

All raw data is written into per‑topic files under a timestamped `RESULTS/<hostname>_<timestamp>` directory on the Solaris host, then flattened into a single `flat.txt` file and summarized visually in `report.html`.

### Layout

- `uExplorer.ksh` – main orchestrator to run all collectors, flatten results, and generate HTML.
- `run.bash` – convenience wrapper on your Mac to `rsync` the repo to the Solaris host and run `uExplorer.ksh` there.
- `INCLUDES/` – shared settings and helper definitions:
  - `settings.ksh` – defines `EHOME`, `RESULTS`, and `PROGS`.
  - `unixcmds.ksh` – Solaris‑specific command paths and common utilities (`$NAWK`, `$GREP`, `$IFCONFIG`, etc.).
  - `nic_funcs_solaris.ksh` – helper functions for NIC parsing (speed/duplex/downgrade checks, stats).
- `PROGRAMS/` – individual data collectors:
  - `general.ksh` – general system summary.
  - `nics.ksh` – network interfaces summary and per‑NIC details.
  - `hbainfo.ksh` – HBA details (EMC `inq.sol64`‑based, best effort).
  - `disks.ksh` – disk inventory, size, some `luxadm` linkage, internal meta layout (if `metastat` exists).
  - `inqs.ksh` – EMC/array WWN inventory using `inq.sol64` (runs only if the binary is present/executable).
  - `luxadm.ksh` – `luxadm display` summary for disk WWNs.
  - `swapinfo.pl` – swap/memory usage breakdown (Perl script).
  - `zones.ksh` – Solaris Zones summary.
  - `zfs.ksh` – ZFS pools, datasets, snapshots, and vdev mapping.
  - `zfs_arc.ksh` – ZFS ARC statistics.
  - `bootenvs.ksh` – boot environments via `beadm`.
  - `smf.ksh` – non‑online SMF services.
  - `pkg.ksh` – IPS publisher and package count summary.

### Prerequisites on the Solaris host

Core utilities:

- Standard Solaris 11 install with:
  - `ksh`, `nawk`, `egrep`, `grep`, `ifconfig`, `netstat`, `kstat`, `truss`, `date`, `psrinfo`, `prtconf`,
    `isainfo`, `luxadm`, `df`, `iostat`, `format`, `svcs`, `pkg`.
- Optional but used when available:
  - `zoneadm`, `zonecfg`, `zpool`, `zfs`, `beadm`, `metastat`, EMC `inq.sol64`.

The script degrades gracefully when optional tools are missing (for example, ZFS sections are skipped if `zpool`/`zfs` are absent).

### Running it directly on Solaris

1. **Copy the entire `uExplorer` directory to the Solaris server**, for example:

   ```bash
   # on your workstation
   scp -r uExplorer root@your-solaris-host:/opt/uExplorer
   ```

2. **On the Solaris host**, as root:

   ```bash
   cd /opt/uExplorer
   ./uExplorer.ksh
   ```

`uExplorer.ksh` will:

- Set `EHOME` based on its own path.
- Initialize `RESULTS/<hostname>_<timestamp>` and `PROGS`.
- Run all collectors in `PROGRAMS/`.
- Flatten all per‑file outputs into `RESULTS/.../flat.txt`.
- Generate `RESULTS/.../report.html` and print its full path.

You can then copy the HTML report back to your workstation and open it in a browser, for example:

```bash
scp root@your-solaris-host:/opt/uExplorer/RESULTS/<latest_dir>/report.html ./report-latest.html
```

### Optional: using `run.bash` from your workstation

If you prefer not to manage the copy/SSH steps manually, you can edit and use `run.bash` on your workstation:

- It `rsync`s the local tree to the Solaris host.
- It SSHes to the host and runs `uExplorer.ksh` in the remote directory.

To use it:

1. Edit `run.bash` and adjust:
   - SSH destination (for example `root@your-solaris-host`).
   - Remote path (for example `/opt/uExplorer/`).

2. From your workstation:

   ```bash
   cd /path/to/uExplorer
   ./run.bash
   ```

The collectors are written to prefer Solaris 11 paths and tools, while remaining usable on older Solaris 10 systems where the legacy commands still exist.
