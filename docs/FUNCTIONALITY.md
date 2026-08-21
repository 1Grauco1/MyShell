# G_ant Shell — Functionality Reference

How every feature is triggered and how it works internally.

## Architecture Overview

```
Hyprland binds ──┐
                 ├─> handleCommand() (shell.qml) ──> State singletons ──> Loader ──> Windows
launch.sh / IPC ─┤                                        │
Bar clicks ──────┘                                        └──> Services ──> scripts/* ──> system tools
```

- **shell.qml** is the root. It owns the IPC handler, Hyprland global shortcuts, the central
  command dispatcher (`handleCommand()`), and lazily instantiates every overlay window via
  `Loader` (windows only exist while their state singleton says they are active).
- **services/** are QML singletons holding state + system integration.
- **bar/** renders the top bar and hosts all menus/popups as children.
- **scripts/** contains all external-process logic; QML never calls system tools directly.
- **Settings/** persists user preferences to a single JSON file.

---

## 1. Entry Points — How Features Are Triggered

All popups funnel through one dispatcher, `handleCommand()` in `shell.qml`, reached three ways:

| Trigger | Path |
|---|---|
| CLI / IPC | `launch.sh <cmd>` -> ensures quickshell daemon runs -> `quickshell ipc call g_ant:menu toggle <cmd>` -> `IpcHandler` in shell.qml |
| Hyprland global shortcuts | `GlobalShortcut { appid: "g_ant" }` entries in shell.qml; bind with `bind = SUPER, X, global, g_ant:<name>` |
| Bar clicks | Widgets call services directly (`CenterState.toggle()`, `QuickSettingsService.toggle()`, ...) |

### Super-key tap detection

Hyprland press/release binds call `scripts/super_launcher.sh`:

1. `press` records a millisecond timestamp and clears the combo flag.
2. Any chord routed through `launch.sh <other-command>` pre-marks the combo flag
   (`super_launcher.sh mark_combo` + a stamp file in `~/.cache/g_ant_last_combo`).
3. On `release`: if the combo flag is set, the event is swallowed. Otherwise a clean tap of
   15-600 ms launches the app launcher.

This is why pressing SUPER+W opens wallpaper without the launcher also flashing open.

### launch.sh flow

1. Resolves its own directory, exports `G_ANT_ROOT`, `QML_IMPORT_PATH`.
2. `send_cmd <cmd>`: marks combo (except for `launcher` itself), starts the daemon if not
   running (`pgrep -x quickshell` check), then forwards via IPC.
3. Friendly aliases (`clip`->clipboard, `bt`->bluetooth, `audio`->volume, `prof`->powerprofile,
   `pwr`->battery, `sys`->power); any unknown argument is passed verbatim, making it a generic
   pass-through client.
4. `start` / `stop` / `restart` manage the daemon directly.

### IPC command reference

| Command | Effect |
|---|---|
| `launcher` | Dynamic island app launcher |
| `clipboard` | Dynamic island clipboard history (cliphist) |
| `emoji` | Dynamic island emoji picker |
| `dashboard[:pomodoro\|wallpaper\|translate]` | Control Center (optional tab) |
| `wallpaper` | Control Center, Wallpaper tab |
| `pomodoro` | Control Center, Pomodoro tab |
| `wifi` / `network` | Quick Settings, Wi-Fi tab |
| `bluetooth` / `bt` | Quick Settings, Bluetooth tab |
| `volume` / `audio` | Quick Settings, Audio tab |
| `powerprofile` / `prof` | Quick Settings, Power Profile tab |
| `battery` / `pwr` | Quick Settings, Battery tab |
| `power` / `sys` | Quick Settings, Power menu tab |
| `media` | Media player popup toggle |
| `media-next` / `media-prev` | Next/previous track on tracked MPRIS player |
| `media-play` | Play/pause toggle |
| `media-shuffle` | Toggle shuffle |
| `settings` | Open/close settings window |
| `setconfig <key>=<value>` | Write a setting at runtime, e.g. `setconfig bar.height=36` |
| `close` | Close every popup/menu/island |

Equivalent native shortcut names (appid `g_ant`): `launcher`, `dashboard`, `wallpaper`,
`pomodoro`, `volume`, `close`, `clipboard`, `emoji`, `power`, `settings`, `media`,
`media-next`, `media-prev`, `media-shuffle`, `media-play`.

Suggested hyprland.conf:

```ini
$qs = ~/.config/quickshell/launch.sh

bind = SUPER, TAB,      exec, $qs overview
bind = SUPER, W,        exec, $qs wallpaper
bind = SUPER, V,        exec, $qs volume
bind = SUPER, N,        exec, $qs wifi
bind = SUPER, B,        exec, $qs bluetooth
bind = SUPER, P,        exec, $qs powerprofile
bind = SUPER, ESCAPE,   exec, $qs power
bind = SUPER, S,        exec, $qs settings
# Super tap launcher (press/release/combo binds):
bind = SUPER, super_L,  exec, ~/.config/quickshell/scripts/super_launcher.sh press
bindr = SUPER, super_L, exec, ~/.config/quickshell/scripts/super_launcher.sh release
```

---

## 2. Top Bar (`bar/`)

| Widget | Trigger | Action / Mechanism |
|---|---|---|
| Workspaces dots | Click dot / scroll wheel | `workspace N` dispatch via Hyprland; dots reflect occupied/active state for workspaces 1-5 plus extras |
| Center pill | Left-click | Opens Control Center (`CenterState.toggle("Default")`) |
| Center pill | Right-click | Toggles date reveal (if `clock.showDate`) |
| Center pill (island active) | Automatic morph | Becomes search bar: arrows navigate, Tab cycles launcher->clipboard->emoji, Enter executes |
| Pomodoro chip | Auto-shown while timer runs/beeps | Click dismisses alarm or opens Pomodoro tab |
| Media title | Shown while tracked player plays | Pulse/breath animation on track change |
| Battery pill | Click | Battery QS tab; hidden when full/on AC/in fullscreen; pulsing icon while charging |
| Network pill | LMB / RMB / hover | Wi-Fi tab / flip down-up display / show SSID; throughput polled from `/proc/net/dev` (interval adapts to hover/panel state) |
| Resources avatar | Click | Power-profile tab; animated GIF pill |
| Tray items | LMB / RMB / MMB / hover | activate / context menu popup / secondary action / glass tooltip; red pulse dot on NeedsAttention |
| Update pill | Appears only when updates > 0; click | Opens update list popup (hourly git poll by `check_updates.sh`; buttons run `run_update.sh`) |
| QS cluster: mic | Auto-shown while an app uses mic; click | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| QS cluster: volume | LMB / RMB | Volume tab / sink mute; % label flashes on change |
| QS cluster: bluetooth | Click | Bluetooth tab |
| QS cluster: battery | Label shown at <=20%; click | Battery tab |
| QS cluster: power | LMB / RMB | Power tab / launches `wlogout` |
| Empty bar space | Any click | `MenuService.closeAll()` |

Fullscreen behaviour: when any window is fullscreen, `HyprlandService.isFullscreen` forces
all menus and popups closed.

---

## 3. Overlays & Popups

### Dynamic Island (`windows/DynamicIslandOverlay.qml`)

Toggled by `launcher` / `clipboard` / `emoji` commands or Tab-cycling inside it. A centered
card below the bar with spring entrance animation; backdrop click closes.

- **Launcher**: filters all desktop entries against name/id/generic/comment/categories,
  scores results by usage history (`~/.local/state/g_ant/app_usage.json`) plus exact/prefix/
  substring bonuses, shows top 4. Typing math (`12*3+2`) evaluates via a built-in recursive-
  descent parser and offers "Enter to copy". Launching records usage and executes the entry.
- **Clipboard**: lists `cliphist` history with live search; copy re-inserts to clipboard
  (`cliphist decode | wl-copy`); per-item delete supported.
- **Emoji**: searchable grid from `assets/emojis.json` with category tabs; copies char to
  clipboard.

### Control Center (`bar/Menu/ControlCenter.qml`)

Opened by center-pill click or `dashboard[:tab]` command. Bubble tab switcher:

- **Default** — notifications card (count badge, clear-all, NOTIFY-in-fullscreen /
  OSD-in-fullscreen toggles), MPRIS player card, month calendar with holiday list
  (fetched once per year+country by `fetch_events.sh`), weather card (current + 3-day).
- **Pomodoro** — progress-ring timer bound to `ProductivityService`: click ring/button
  toggles, Skip/Reset, gear expands focus/break/long/cycle steppers and AUTO-advance;
  keys Space=toggle, R=reset, S=skip.
- **Wallpaper** — thumbnail grid over `~/Pictures/Wallpapers` (+ Animated video sub-tab);
  thumbnails generated asynchronously by ffmpeg script with spinner and refresh button;
  click applies static via `swww img` with random transition + auto-retheme
  (`g_ant-theme.sh --autoselect`, matugen Material You colors), or videos via `mpvpaper`
  loop; closes CC after applying; full keyboard navigation.
- **Translate** — source textarea, FROM/TO pickers with swap button, TRANSLATE button
  (`translate.sh`, Google endpoint), detected-language status, copy-result button;
  Ctrl+Enter translates.

Header extras: media-focus bubble and Caffeine ("keep awake") toggles.

### Quick Settings (`bar/Menu/QuickSettingsMenu.qml`)

Opened by cluster pills or the matching command; segmented tab bar drives a StackLayout:

- **Wi-Fi** — scan on open, network rows sorted active-first then known then signal;
  expandable row reveals password field (Enter joins, eye toggles echo, red border on
  failure), CONNECT/FORGET for known networks; header bubbles: speed test (Cloudflare
  10 MB download measurement), refresh spinner, airplane mode.
- **Bluetooth** — power/scan/startup-service toggles, pair->connect on device rows,
  disconnect, forget, battery %, connected-device bar; SERVICE ERROR view with restart
  button when bluetoothd is down.
- **Audio** — Output/Input cards with sliders, mute, device dropdowns
  (`VolumeService.setDefaultDevice`), per-application stream volume sliders.
- **Power Profile** — performance/balanced/powersave cards (`powerprofilesctl`) +
  read-only LIVE SYSTEM panel: CPU/RAM/temp blocks and per-core bars from ResourceService.
- **Battery** — detailed stats (health, cycles, voltage, energy rate, time remaining)
  from `battery_info.py`.
- **Power** — LOCK / BIOS / LOGOUT / SUSPEND / REBOOT / SHUTDOWN tile grid; hover selects,
  click executes through a Process.

### Media Player Popup (`MediaPlayerPopup.qml`)

Toggled only by the `media` command (not hover). 360x360 card: album-art click toggles
playback, prev/play/next, seek slider (or LIVE badge when unseekable), marquee long titles,
shuffle, mute-with-memory, volume slider, loop cycling, multi-player switching dots.
Shortcut mode keys: Space play/pause, left/right track, up/down volume.

### Notification Popup + OSD

- **NotificationPopup** (top-right): fed purely by `NotificationService` signals; same-app
  notifications merge within a 20 s window into a bump counter; items auto-dismiss; hidden
  during fullscreen unless `notifications.fullscreenNotification`.
- **OsdPopup** (top-right): appears on intercepted volume/brightness OSD events; slider
  writes back via `wpctl` / `brightnessctl`; hover pauses the 2.5 s hide timer; compact
  variant in fullscreen when enabled.
- **DismissOverlay**: invisible fullscreen layer registered whenever any menu is open;
  clicking anywhere fires `MenuService.closeAll()` — global click-away dismissal.

### Tray Menu / Update Menu

Anchored `PopupWindow`s under their bar pills. Tray menu supports submenus via StackView;
closes on focus loss (`HyprlandFocusGrab`). Update menu lists new commits per repo and runs
`run_update.sh`.

---

## 4. Services (`services/`) — Internal Mechanics

All are QML singletons. Common patterns:

- **Event stream + watchdog**: long-running monitors (`udevadm monitor`, `bluetoothctl
  monitor`, `nmcli monitor`, `pw-mon`, `resources.sh`) each paired with a 2-3 s restart
  timer if the process dies.
- **Adaptive polling**: expensive work (device lists, scans, profiles) is gated behind the
  `quickSettingsOpen` / `controlCenterOpen` flags in `Variables`; poll intervals come from
  TaskSettings (`fast/medium/slow/lazy/idle`).
- **Atomic persistence** via `scripts/write_file.py` (tmp + rename).

| Service | Purpose | Mechanism |
|---|---|---|
| BatteryService | %, AC, health, temp, time remaining, witty low-battery notifications (20/10/5/3/1%) | `udevadm monitor` events (250 ms debounce) + 15 s charging / 60 s fallback poll -> `battery_info.py` reading sysfs |
| BluetoothService | devices, pair/connect/disconnect/forget, service mgmt | persistent `bluetoothctl monitor` stream + `bt_status.py`; writes via bluetoothctl; enable/restart via pkexec systemctl |
| WifiService | scan, connect/disconnect/forget, airplane, RSSI/IP, speed test | `nmcli monitor` stream + `wifi_nm.py`; speed test = curl 10 MB from Cloudflare; full scans gated to panel-open |
| VolumeService | output/mic volume+mute, device lists, per-app streams, BT detection | `pw-mon \|\| pactl subscribe` stream -> debounced `wpctl` queries; apps from `pw-dump \| pw_app_volumes.py`; stale-write protection during drags |
| ResourceService | CPU/mem/temp/load/fs, per-core stats, IP, kernel | zero polling: streaming daemon `resources.sh` emits one JSON line every 1.5 s (single-instance flock, self-exits if quickshell dies) |
| MediaPlayerService | unified MPRIS tracking, real-playback detection, media focus, popup state | pure `Quickshell.Mpris`; fickle browser players verified by position advancement/stall detection; chat apps blacklisted; 1 s heartbeat timer |
| NotificationService | notification daemon replacement, history, OSD splitting, dedupe/merge | `NotificationServer` callback (event-driven, no timers); OSD values written back via wpctl/brightnessctl |
| HyprlandService | fullscreen detection, monitor hotplug resolution restore | compositor rawEvents (`fullscreen`, `activewindow`, `monitoradded/removed`); applies saved modes via `monitors.sh apply-saved` |
| PowerProfileService | profile get/set | `powerprofilesctl`, polled only while QS panel is open |
| ProductivityService | countdown timer + pomodoro engine, persistence, alarm | internal 1 s timer while running (saves every 10 ticks); alarm sound chain ffplay/mpv/paplay/pw-play; state in `~/.local/state/g_ant/productivity.json` |
| WallpaperService | apply wallpapers, transitions, thumbnails | `swww img` random transition; thumbnails via `generate_thumbnails.py` once at startup; current path saved to `config/current_wallpaper.txt` |
| WeatherService | current + forecast, disk cache | `weather.sh` (Open-Meteo, auto IP-location chain); cache read at startup; refresh every 30 min and on location change |
| TranslateService | on-demand translation + copy result | request/response Process around `translate.sh` |
| CaffeineService | keep-awake inhibit | `systemd-inhibit sleep infinity`; PID in `/dev/shm/g_ant_caffeine.pid`; pgrep state check at startup |
| Variables | env probe, shared flags, interval constants, icon paths | one-shot `detect_env.sh` JSON stream at startup |
| DynamicIslandService / MenuService / QuickSettingsService / CenterState | UI state + mutual exclusion | opening one surface closes the others; Loaders in shell.qml instantiate windows only while active |

---

## 5. Helper Scripts (`scripts/`)

| Script | Purpose | IO summary |
|---|---|---|
| `detect_env.sh` | Distro/kernel/user/timezone/country/screen/icon-path probe | stdout JSON, no args |
| `resources.sh` | Streaming resource daemon (procfs/sysfs direct reads) | one JSON line / 1.5 s; flock single-instance |
| `battery_info.py` | Aggregate battery/AC data from sysfs (no binaries) | stdout JSON |
| `bt_status.py` | Bluez status via bluetoothctl/systemctl (3 s timeouts) | stdout JSON; arg `full` adds device list |
| `wifi_nm.py` | NetworkManager front-end | default: status JSON scan; subcommands: `status`, `connect <ssid> [pw]`, `disconnect`, `forget <ssid>`, `airplane on/off` |
| `pw_devices.py` | Sink/source enumeration from `wpctl status` | stdout JSON |
| `pw_streams.py` | Default sink/source volume/mute + activity/BT flags | stdout JSON |
| `pw_app_volumes.py` | Filters `pw-dump` stdin to per-app audio streams | JSON array on stdout |
| `weather.sh` | Open-Meteo fetch -> wttr.in-shaped JSON; 30 min cache; auto IP geolocation chain | arg `<location\|auto>` |
| `translate.sh` | Google translate endpoint proxy | args `<src> <tgt> <text>`; JSON out |
| `fetch_events.sh` | Public holidays (Nager.Date + religious calendar APIs), 24 h cache, flock serialization | args `[year] [country]`; writes state/events.json |
| `check_updates.sh` | Git update counter for dotfiles + shell repos | env `G_ANT_REPO_DIR` / `G_ANT_SHELL_DIR`; JSON out |
| `run_update.sh` | Clone-or-pull dotfiles repo, run installer | env `G_ANT_DIR` |
| `monitors.sh` | Hyprland monitor control: `list`, `apply <name> WxH@RR`, `apply-saved` (replays `monitor.*.resolution` settings) | uses hyprctl + jq |
| `super_launcher.sh` | Super tap-vs-chord discriminator | args `press/release/combo/mark_combo` |
| `write_file.py` | Atomic writer (tmp + os.replace) | args `<path> <payload>` |
| `generate_thumbnails.py` | ffmpeg wallpaper/video preview generation | used by WallpaperService |
| `g_ant-theme.sh` | matugen Material-You theme pipeline: wallpaper -> palette -> reload Hyprland/quickshell/kitty/GTK scheme | args `[--autoselect] <wallpaper> [color]` |

---

## 6. Settings System (`Settings/`)

- Single flat JSON store: `<shellDir>/settings.json` (override root with `G_ANT_ROOT`),
  dot-namespaced keys such as `"bar.height": 36`.
- `SettingsStore` wraps a FileView: lazy blocking load, corrupt-file recovery to `{}`,
  debounced 500 ms atomic writes.
- Domain singletons expose typed properties that UI widgets bind to; every change persists
  automatically:
  - `AppearanceSettings` — opacities, blur, font/icon sizes, menu radius/padding
  - `BarSettings` — height, radius, margins, entry animation
  - `PillSettings` — pill geometry (height/radius/padding/gap/borders)
  - `BatterySettings` — charge thresholds driving icons/warnings
  - `ClockSettings` — clock/date visibility, 12/24h, format strings, precision
  - `MediaSettings` — title truncation, media-focus automation, volume/loop controls
  - `NotificationSettings` — enable, fullscreen behavior for notifications and OSD
  - `TaskSettings` — adaptive poll intervals (fast 1.5 s ... idle 10 min)
  - `WidgetSettings` — per-widget enable flags, weather location
  - `HyprlandSettings` — gaps/borders/rounding/shadows/blur; pushed live via
    `hyprctl keyword` and applied at startup
  - `PathSettings` — resolved directory/script paths
- GUI editor: settings window (`settings` cmd / SUPER+S) with tabs General, Appearance,
  Bar, Battery, Hyprland, Media, Monitors. Monitors tab applies resolutions live and stores
  them as `monitor.<name>.resolution` keys which `monitors.sh apply-saved` replays on hotplug.
- Runtime tweak without GUI: `launch.sh setconfig <key>=<value>`.

---

## 7. Startup Sequence

1. `launch.sh start` (from `hyprland.conf exec-once`) starts `quickshell -d`.
2. Shell loads; bar slides/fades in (entry animation configurable).
3. Background init: `detect_env.sh` probe, battery udev monitor, bluetooth/nmcli/pipewire
   monitors, resources daemon, weather cache load + delayed fetch, wallpaper thumbnail
   generation, saved monitor resolutions reapplied, pomodoro state restored.
4. Everything else stays dormant until triggered.
