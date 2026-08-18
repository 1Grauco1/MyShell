#!/usr/bin/env python3
import glob, json, os, sys

bat_paths = glob.glob('/sys/class/power_supply/BAT*')
ac_paths = (glob.glob('/sys/class/power_supply/AC*') +
            glob.glob('/sys/class/power_supply/ADP*') +
            glob.glob('/sys/class/power_supply/Mains*'))

ac_online = False
if ac_paths and os.path.exists(ac_paths[0] + '/online'):
    try:
        with open(ac_paths[0] + '/online') as f:
            ac_online = f.read().strip() == '1'
    except Exception:
        pass

def read_val(path, filenames, default=0):
    for name in filenames:
        p = os.path.join(path, name)
        if os.path.exists(p):
            try:
                with open(p) as f:
                    return f.read().strip()
            except Exception:
                pass
    return default

total_now = 0
total_full = 0
total_design = 0
total_rate = 0
total_volt = 0
total_cycles = 0
statuses = []

for b in bat_paths:
    if not os.path.isdir(b):
        continue
    cap = int(read_val(b, ['capacity'], 0))
    stat = str(read_val(b, ['status'], 'unknown')).lower()
    cycles = int(read_val(b, ['cycle_count'], 0))
    volt = int(read_val(b, ['voltage_now', 'voltage_avg'], 0))
    rate = abs(int(read_val(b, ['power_now', 'current_now'], 0)))
    now = int(read_val(b, ['energy_now', 'charge_now'], 0))
    full = int(read_val(b, ['energy_full', 'charge_full'], 0))
    design = int(read_val(b, ['energy_full_design', 'charge_full_design'], 0))

    total_now += now
    total_full += full
    total_design += design
    total_rate += rate
    total_volt += volt
    total_cycles += cycles
    statuses.append(stat)

temp = 0
for hw in glob.glob('/sys/class/hwmon/hwmon*/temp1_input'):
    try:
        with open(hw) as f:
            temp = int(f.read().strip()) / 1000
            break
    except Exception:
        pass

print(json.dumps({
    'acOnline': ac_online,
    'now': total_now,
    'full': total_full,
    'design': total_design,
    'rate': total_rate,
    'volt': total_volt,
    'cycles': total_cycles,
    'statuses': statuses,
    'temp': temp,
    'count': len(bat_paths)
}))
