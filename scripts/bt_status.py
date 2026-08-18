#!/usr/bin/env python3
import subprocess, json, re, sys

def run(cmd):
    try:
        return subprocess.check_output(cmd, text=True, timeout=3).strip()
    except Exception:
        return ''

do_full = len(sys.argv) > 1 and sys.argv[1] == 'full'

show = run(['bluetoothctl', 'show'])
is_powered = 'Powered: yes' in show
is_scanning = 'Discovering: yes' in show

all_devs_raw = run(['bluetoothctl', 'devices']) if do_full else ''
paired_devs_raw = run(['bluetoothctl', 'paired-devices']) if do_full else ''
connected_devs_raw = run(['bluetoothctl', 'devices', 'Connected'])

paired_addrs = set()
if do_full:
    for line in paired_devs_raw.splitlines():
        if line.startswith('Device '):
            parts = line.split()
            if len(parts) >= 2:
                paired_addrs.add(parts[1])

connected_addrs = set()
for line in connected_devs_raw.splitlines():
    if line.startswith('Device '):
        parts = line.split()
        if len(parts) >= 2:
            connected_addrs.add(parts[1])

devices = []
if do_full:
    seen = set()
    for line in all_devs_raw.splitlines():
        p = line.split()
        if len(p) >= 2 and p[0] == 'Device':
            addr = p[1]
            if addr in seen:
                continue
            seen.add(addr)
            raw_name = ' '.join(p[2:]) if len(p) > 2 else addr
            is_addr_fmt = bool(re.match(r'^[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}$', raw_name))
            has_real_name = len(p) > 2 and not is_addr_fmt
            devices.append({
                'address': addr,
                'name': raw_name,
                'hasName': has_real_name,
                'paired': addr in paired_addrs,
                'connected': addr in connected_addrs,
                'icon': 'bluetooth',
                'battery': -1
            })

conn_name = ''
conn_addr = ''
conn_battery = -1
conn_icon = 'bluetooth'

if connected_addrs:
    first_conn = next(iter(connected_addrs))

    for c_addr in connected_addrs:
        info_raw = run(['bluetoothctl', 'info', c_addr])
        c_name = ''
        c_icon = 'bluetooth'
        c_batt = -1

        for line in info_raw.splitlines():
            l = line.strip()
            if l.startswith('Name: '):
                c_name = l[6:]
            elif l.startswith('Icon: '):
                c_icon = l[6:]
            elif l.startswith('Battery Percentage:'):
                try:
                    if '(' in l and ')' in l:
                        c_batt = int(l.split('(')[1].split(')')[0])
                    else:
                        c_batt = int(l.split(':')[-1].strip())
                except Exception:
                    pass

        if c_addr == first_conn:
            conn_addr = c_addr
            conn_name = c_name
            conn_icon = c_icon
            conn_battery = c_batt

        for d in devices:
            if d['address'] == c_addr:
                d['battery'] = c_batt
                d['icon'] = c_icon
                if c_name and (not d['name'] or d['name'] == c_addr):
                    d['name'] = c_name

service_active = run(['systemctl', 'is-active', 'bluetooth.service']) == 'active'
is_enabled = run(['systemctl', 'is-enabled', 'bluetooth.service']) == 'enabled'

print(json.dumps({
    'powered': is_powered,
    'scanning': is_scanning,
    'connected': len(connected_addrs) > 0,
    'connectedName': conn_name,
    'connectedAddress': conn_addr,
    'connectedBattery': conn_battery,
    'connectedIcon': conn_icon,
    'serviceActive': service_active,
    'isServiceEnabled': is_enabled,
    'devices': devices if do_full else None
}))
