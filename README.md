# Luckfox Shell

A Qt5/QML automotive infotainment shell for the **Luckfox Pico Ultra W** (Rockchip RV1106 SoC, 800×480 framebuffer, software-rendered, no GPU). Six touch-optimized tabs covering vehicle and media essentials.

![Status](https://img.shields.io/badge/status-active-success) ![Qt](https://img.shields.io/badge/Qt-5.15-41cd52) ![Platform](https://img.shields.io/badge/platform-ARMv7l-blue) ![License](https://img.shields.io/badge/license-MIT-informational)

---

## Highlights

- **Single-process shell** with a vertical tab rail (left edge) and a content area filling 688×408
- **Six tabs**: Dashboard, Music, Calendar, WiFi, Recorder, Wireframe
- **Unified design system** (`qml/components/themes/Theme.js` — "Nordic Aurora") shared across all modules
- **Touch-friendly**: 48px minimum targets, 12px grid spacing, large hit areas
- **Dark mode only** (locked — no light/dark toggle on hardware)
- **No GPU, no QtGraphicalEffects** — pure QML + Canvas, software-rendered

---

## Hardware

- **Board**: Luckfox Pico Ultra W
- **SoC**: Rockchip RV1106 (ARM Cortex-A7)
- **Display**: 800×480 RGB LCD (framebuffer `/dev/fb0`)
- **Audio**: ALSA (`/dev/snd/...`)
- **Storage**: SD card at `/media/music`, recordings at `/tmp`

---

## Project layout

```
09_Final_project/
├── luckfox_shell.pro          # qmake project file
├── src/                       # C++ backend (audio, wifi, sensors, ...)
│   ├── main.cpp
│   ├── apptheme.{h,cpp}       # runtime theme selector
│   ├── audioplayer.{h,cpp}    # music playback
│   ├── AudioRecorder.{h,cpp}  # voice capture
│   ├── VoicePlayer.{h,cpp}    # recording playback
│   ├── wifimanager.{h,cpp}    # wifi scan/connect/wpa_supplicant
│   ├── DeviceManager.{h,cpp}  # status/battery/storage
│   ├── sysinforeader.{h,cpp}  # RAM/CPU/disk telemetry
│   ├── FastDataWorker/        # high-rate sensor reads
│   ├── SlowDataWorker/        # low-rate sensor reads
│   ├── SensorWorker/          # I²C sensor aggregation
│   ├── lunar.{h,cpp}          # lunar calendar (Vietnamese)
│   ├── settings.{h,cpp}       # QSettings wrapper
│   └── ...
├── qml/
│   ├── shell.qml              # main window + tab rail
│   └── components/
│       ├── themes/Theme.js    # design system (THE source of color/font/size)
│       └── ShellTabBar.qml    # vertical tab rail
├── modules/
│   ├── dashboard/qml/         # system telemetry
│   ├── music/qml/             # Spotify-style player
│   ├── calendar/qml/          # month + agenda + lunar
│   ├── wifi/qml/              # scan + connect + on-screen keyboard
│   ├── voicetest/qml/         # record / play buttons + waveform
│   └── wireframe/             # C++ 3D scene + QML title overlay
├── scripts/
│   ├── build.sh               # cross-compile via qmake + make
│   ├── deploy.sh              # scp binary to board
│   └── run.sh                 # launch over SSH
└── README.md
```

---

## Build

### Prerequisites

- **Cross-toolchain**: ARM buildroot toolchain (`arm-buildroot-linux-gnueabihf-`)
- **Qt5 sysroot**: built from the Luckfox buildroot output
- **qmake** for the target device (`devices/linux-buildroot-g++` mkspec)
- **make**
- **libs**: Qt5Core, Qt5Gui, Qt5Quick, Qt5Qml, Qt5Svg, Qt5Network, Qt5QmlModels, ALSA (`libasound2`)

### Configure the build environment

The build script uses two variables — either edit `scripts/build.sh` or export them:

```bash
# Path to the qmake binary from the Luckfox buildroot output
export QMAKE=/path/to/buildroot/output/host/bin/qmake

# Path to the project root (defaults to parent of scripts/)
# export LUCKFOX_PROJECT_DIR=/path/to/09_Final_project
```

### Build

```bash
bash scripts/build.sh
# → build/luckfox-shell
```

The build runs `qmake` then `make -j$(nproc)`. Output is a single statically-against-sysroot ELF binary.

---

## Deploy

The deploy script `scp`s the binary to the board and makes it executable.

Configure two variables (either edit the script or export them):

```bash
# Target board (private LAN)
export LUCKFOX_BOARD_IP=192.168.x.x      # default: 192.168.1.3
export LUCKFOX_BOARD_USER=root           # default: root

# SSH key (private key file is NOT committed to this repo)
export LUCKFOX_SSH_KEY=/path/to/id_ed25519
```

Then run:

```bash
bash scripts/deploy.sh
```

> The `SSH_KEY` is a path to your private key on the build host. **Never commit the key itself** to the repo.

---

## Run on board

```bash
bash scripts/run.sh
```

This SSHs into the board, kills any previous instance, exports the required Qt/ALSA env vars, and launches the app in the background. Output is tail-ed into your terminal.

Required env vars on the board (set by `run.sh`):

- `QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0:size=800x480:mmsize=800x480`
- `QT_QPA_FONTDIR=/usr/share/fonts/dejavu/`
- `LD_LIBRARY_PATH=/usr/lib:/usr/lib/qt5/lib:/usr/lib/aarch64-linux-gnu`

---

## The design system

All colors, fonts, sizes, spacing, and radii flow from one file: `qml/components/themes/Theme.js`. Modules import it as a JS namespace:

```qml
import "qrc:/shell/components/themes/Theme.js" as T

readonly property bool dk: appTheme.isDark
readonly property var pal: dk ? T.music.dark : T.music.light

Text {
    font.family: T.font                  // "DejaVu Sans"
    font.pixelSize: T.sizes.title        // 16
    color: pal.text
    anchors.margins: T.spacing.md        // 12
}
```

### Sub-themes

Each module has its own `{dark, light}` palette under `T.<module>`:

| Module      | Keys                                                    |
|-------------|---------------------------------------------------------|
| `T.dashboard` | `cardColor, cardBorder, barColor, hairline, ...`        |
| `T.calendar`  | `bg, surface, accent, todayFill, holiday, ...`          |
| `T.music`     | `bgTop, panelBg, surface, accent, glow, ...`            |
| `T.wifi`      | `accent, cardTop, itemBg, keyBg, dialogBg, error, ...`  |
| `T.recorder`  | `cardTop, waveBg, accent, error, duration, ...`         |
| `T.wireframe` | `title, status`                                          |

### Token reference

| Token        | Value             | Use                            |
|--------------|-------------------|--------------------------------|
| `T.font`     | `"DejaVu Sans"`   | UI text                        |
| `T.fontMono` | `"DejaVu Sans Mono"` | Data values, status bar     |
| `T.sizes`    | `hero=24 ... micro=8` | Pixel sizes per role      |
| `T.spacing`  | `xs=4 ... xxl=32` | 8px grid                       |
| `T.radius`   | `sm=4 ... round=999` | Corner radii                |
| `T.duration` | `instant=80 ... pulse=1500` | Animation timings     |

The active palette is selected at runtime via `appTheme.isDark` (from `src/apptheme.{h,cpp}`).

---

## Modules

### 1. Dashboard
System telemetry: RAM, CPU, storage, AHT30 temperature/humidity sensor, network status, top CPU processes. SVG-style gauges rendered with `Canvas`.

### 2. Music
Local file browser (scans `/media/music`), now-playing bar, playback controls, queue. Uses ALSA via `audioplayer.cpp`.

### 3. Calendar
Month grid + agenda list with Vietnamese lunar dates (`src/lunar.{h,cpp}`). Holiday highlighting. Touch-friendly day cells.

### 4. WiFi
Network scan, list, on-screen QWERTY keyboard for password entry, connect/disconnect. Backed by `wpa_supplicant` and `wpa_cli` (driven by `wifimanager.cpp`).

### 5. Recorder
Push-to-record + playback, live waveform display, file list. Backed by ALSA via `AudioRecorder` / `VoicePlayer`.

### 6. Wireframe
3D rotating wireframe scene (pyramid + cylinder + cube) painted in C++ via `QQuickPaintedItem`. 60fps Timer animation. Demo of GPU-free 3D.

---

## Development workflow

Each tab was redesigned one at a time, then built and deployed for hardware review on the actual board before moving to the next. The 6 tabs in delivery order:

1. Dashboard
2. Music
3. Calendar
4. WiFi
5. Recorder
6. Wireframe

To add a new tab:

1. Create `modules/<name>/qml/<Name>Tab.qml` exporting `Item { id: rootTab; ... }`
2. Register the QRC, add a C++ backend if needed, expose as a QML module
3. Add a sub-theme `T.<name>` in `qml/components/themes/Theme.js`
4. Add the tab entry in `qml/shell.qml` and `qml/components/ShellTabBar.qml`

---

## Known limitations

- **No HTTPS / networking UI** beyond WiFi control — the device is intentionally air-gapped
- **No system update flow** — binary must be deployed via the script
- **No screen rotation** — fixed landscape 800×480
- **No light mode** — the design system defines both, but only dark is exposed on hardware
- **Some `QtQuick.Controls 2.15` quirks** on this buildroot Qt build (e.g. default `Button.background` highlights) — handled per-component where they appear

---

## License

MIT. See `LICENSE` (add when you publish).

---

## Acknowledgments

Built on the Luckfox Pico Ultra W with the Rockchip RV1106 buildroot SDK. Display framebuffer code adapted from the Luckfox SDK examples. Lunar calendar data from the open-source `lunar-cpp` project.
