#!/usr/bin/env bash
# Event-driven streaming resource monitor daemon for g_ant-shell

# Single-instance guard: avoid orphaned duplicates piling up across restarts
if command -v flock >/dev/null 2>&1; then
    LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/g_ant"
    mkdir -p "$LOCK_DIR"
    exec 9>"$LOCK_DIR/resources.lock"
    flock -n 9 || exit 0
fi

exec python3 -u -c '
import json, os, glob, time, socket, sys

def read_cpu_all():
    """Returns list of (name, total_jiffies, idle_jiffies) for cpu and each core."""
    result = []
    with open("/proc/stat", "r") as f:
        for line in f:
            parts = line.split()
            name = parts[0]
            if not name.startswith("cpu"):
                break
            vals = [int(x) for x in parts[1:]]
            total = sum(vals)
            idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
            result.append((name, total, idle))
    return result

# Cache static system info
cpu_model = ""
curr_freq_mhz = 0
core_count = 0
try:
    with open("/proc/cpuinfo", "r") as f:
        for line in f:
            if "model name" in line and not cpu_model:
                cpu_model = line.split(":", 1)[1].strip()
            elif "cpu MHz" in line and curr_freq_mhz == 0:
                try:
                    curr_freq_mhz = float(line.split(":", 1)[1].strip())
                except Exception:
                    pass
            elif "processor" in line:
                core_count += 1
except Exception:
    pass

freq_str = f"{round(curr_freq_mhz/1000, 2)}GHz" if curr_freq_mhz else "N/A"

os_name = "NixOS"
if os.path.exists("/etc/os-release"):
    try:
        with open("/etc/os-release", "r") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    os_name = line.split("=", 1)[1].strip().strip("\"")
    except Exception:
        pass
kernel = os.uname().release

ip_addr = ""
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("1.1.1.1", 80))
    ip_addr = s.getsockname()[0]
    s.close()
except Exception:
    pass

last_cores = {}

parent_pid = os.getppid()

while True:
    try:
        # Die if our parent (quickshell, via exec) is gone
        if os.getppid() != parent_pid:
            break
        time.sleep(1.5)
        snapshot = read_cpu_all()
        if len(snapshot) > 0:
            name, t, i = snapshot[0]
            lt, li = last_cores.get(name, (t, i))
            total_diff = t - lt
            idle_diff = i - li
            last_cores[name] = (t, i)
            if total_diff > 0:
                cpu_overall = int(round(100.0 * (total_diff - idle_diff) / total_diff))
                cpu_overall = max(0, min(100, cpu_overall))
            else:
                cpu_overall = 0

        core_usages = []
        for name, t, i in snapshot[1:]:
            lt, li = last_cores.get(name, (t, i))
            last_cores[name] = (t, i)
            dt = t - lt
            di = i - li
            if dt > 0:
                p = int(round(100.0 * (dt - di) / dt))
                core_usages.append(max(0, min(100, p)))
            else:
                core_usages.append(0)

        mem_total_kb, mem_avail_kb = 0, 0
        with open("/proc/meminfo", "r") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    mem_total_kb = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    mem_avail_kb = int(line.split()[1])
        mem_perc = int(round(100.0 * (mem_total_kb - mem_avail_kb) / mem_total_kb)) if mem_total_kb > 0 else 0
        mem_used_gb = (mem_total_kb - mem_avail_kb) / 1024.0 / 1024.0
        mem_total_gb = mem_total_kb / 1024.0 / 1024.0

        temps = []
        for p in glob.glob("/sys/class/hwmon/hwmon*/temp*_input") + glob.glob("/sys/class/thermal/thermal_zone*/temp"):
            try:
                with open(p, "r") as f:
                    v = int(f.read().strip())
                    if 10000 <= v <= 115000:
                        temps.append(v // 1000)
                    elif 10 <= v <= 115:
                        temps.append(v)
            except Exception:
                pass
        cpu_temp = max(temps) if temps else 0

        with open("/proc/loadavg", "r") as f:
            load = float(f.read().split()[0])
        load_perc = int(round(load * 10))

        fs_perc = 0
        fs_used_gb = 0.0
        fs_total_gb = 0.0
        try:
            st = os.statvfs("/")
            if st.f_blocks > 0:
                fs_perc = int(round(100.0 * (1.0 - (st.f_bavail / st.f_blocks))))
                fs_used_gb = (st.f_blocks - st.f_bavail) * st.f_frsize / 1024.0**3
                fs_total_gb = st.f_blocks * st.f_frsize / 1024.0**3
        except Exception:
            pass

        data = {
            "cpu": cpu_overall,
            "mem": mem_perc,
            "temp": cpu_temp,
            "load": load,
            "load_perc": load_perc,
            "fs": fs_perc,
            "cpu_model": cpu_model,
            "freq": freq_str,
            "arch": os_name,
            "kernel": kernel,
            "ip": ip_addr,
            "cores": core_usages,
            "mem_used": round(mem_used_gb, 1),
            "mem_total": round(mem_total_gb, 1),
            "fs_used": round(fs_used_gb, 1),
            "fs_total": round(fs_total_gb, 1)
        }
        print(json.dumps(data), flush=True)
    except KeyboardInterrupt:
        break
    except Exception:
        time.sleep(2)
'
