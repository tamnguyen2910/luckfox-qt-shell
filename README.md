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
- **Display**: 800×480 RGB666 LCD, GT911 capacitive touch (I2C3)
- **Audio**: ALSA (`/dev/snd/...`)
- **Storage**: SD card at `/media/music`, recordings at `/tmp`
- **Sensors**: AHT30 temperature/humidity (I2C2 @ 0x38), potentiometer VR1 (SARADC ch1)
- **Connectivity**: SDIO WiFi (wpa_supplicant / wpa_cli)
- **Other**: EC11 rotary encoder, USB (peripheral), MIPI CSI camera, BT (UART1)

The framebuffer is `/dev/fb0`. The touch device is `/dev/input/eventN` (resolved by Qt).

---

## System-level work (kernel + drivers + buildroot)

This shell app is only the top of a much larger integration. The lower layers live in a separate Luckfox SDK tree and were modified by hand. They are **not** in this repository — the changes live in the buildroot kernel sources and config files, not in the Qt project. If you rebuild the system from scratch, you need to:

### 1. AHT30 I²C humidity/temperature sensor

A custom kernel driver was added (no upstream IIO support for this board at the time).

**Files modified (under `sysdrv/` of the Luckfox SDK):**

- `source/kernel/drivers/iio/humidity/aht30.c` — new I²C client driver
  - Compatible: `aosong,aht30`
  - I²C address `0x38`
  - Commands: `0xBE` init / `0xAC` measure / `0xBA` reset
  - Exposes temp + humidity via `hwmon` sysfs (e.g. `/sys/class/hwmon/hwmonX/name == "aht30"`)
  - 100 kHz I²C bus, 80 ms measurement delay, 20 ms reset delay
- `source/kernel/drivers/iio/humidity/Kconfig` — added `CONFIG_SENSORS_AHT30`
- `source/kernel/drivers/iio/humidity/Makefile` — added the object

**Device tree:** `arch/arm/boot/dts/rv1106g-luckfox-pico-ultra-w.dts`

```dts
&i2c2 {
    status = "okay";
    clock-frequency = <100000>;

    aht30@38 {
        compatible = "aosong,aht30";
        reg = <0x38>;
    };
};
```

**Kernel config (`config/kernel_defconfig`):**

```
CONFIG_SENSORS_AHT30=y
```

**Verify on board after flashing:**

```bash
modprobe aht30                          # or it's built-in
ls /sys/class/hwmon/                    # look for aht30
cat /sys/class/hwmon/hwmonX/temp1_input # millidegrees C
cat /sys/class/hwmon/hwmonX/humidity1_input  # millipercent
```

**App-side consumption:** the Dashboard's AHT30 zone reads from a `SensorWorker` (`src/SensorWorker/`) which polls these sysfs files; the QML `DashboardTab.qml` binds to the worker properties.

A second, separate AHT30 helper exists for the optional MQTT path:

- `package/aht30-mqtt/aht30-mqtt.c` — standalone userspace binary that publishes to MQTT
- `package/aht30-mqtt/aht30-mqtt.mk` — buildroot recipe (the `aht30-mqtt` recipe in `package/Config.in`)

### 2. Display (800×480 RGB666 LCD) + touch (GT911)

The default `rv1106-luckfox-pico-ultra-ipc.dtsi` ships with the RGB route **disabled** (headless IPC). To get the LCD working:

**Device tree (`rv1106g-luckfox-pico-ultra-w.dts`):**

```dts
/* LCD display route (ENABLE — was disabled in ultra-ipc.dtsi) */
&route_rgb {
    status = "okay";
};
```

**Touch:** GT911 on I2C3 (SCL2_M0 / SDA2_M0 in the schematic). Enabled by the `goodix,gt9xx` node in the DTS — it is **not** in the IPC dtsi, so we had to add it. The touch node is consumed by Qt as a `linuxinput` device and registered as `/dev/input/eventN`.

**Display timings** (RGB 800×480 @ ~60 Hz, 50 MHz pixel clock, sync active high, sync DE mode) are in the `route_rgb` and `display_subsystem` nodes inherited from `rv1106.dtsi` and may need a per-panel overlay (e.g. `pinctrl-0 = <&lcd_rgb_dclk &lcd_rgb_vsync &lcd_rgb_hsync ...>`).

### 3. WiFi (SDIO w1-ctrl + wpa_supplicant)

The board has an onboard SDIO WiFi chip. It needs:

- The `wireless-sdio` driver + `bluetooth-platdata` enabled (already on in the DTS for this board)
- A wpa_supplicant build in the buildroot rootfs (recipe `package/wpa_supplicant/`)
- `/etc/wpa_supplicant.conf` with `ctrl_interface=DIR=/var/run/wpa_supplicant`
- The C++ `wifimanager.cpp` here talks to `wpa_cli -i wlan0` over its control socket
- A simulated command path is wired up for development without real radio (`-DSIM_WIFI=1`); production needs the real `wpa_cli` calls enabled

### 4. EC11 rotary encoder (board-specific)

`/ { encoder: rotary-encoder { ... }; }` node in the DTS, disabled for `gpio-keys-encoder` because the chosen pin is the debug-console UART TX. To re-enable, remap SW to a free GPIO (e.g. `gpio1 PA6/PA7`).

### 5. Buildroot config

The Luckfox buildroot defconfig is at `config/buildroot_defconfig`. Notable toggles:

```
BR2_PACKAGE_WPA_SUPPLICANT=y
BR2_PACKAGE_AHT30_MQTT=y        # optional MQTT helper
BR2_PACKAGE_QT5=y
BR2_PACKAGE_QT5BASE_LINUXFB=y   # linuxfb platform
```

### 6. Kernel rebuild

A full kernel rebuild from the SDK root:

```bash
cd /path/to/luckfox-pico
./build.sh kernel                       # just the kernel
./build.sh                              # kernel + buildroot + image
```

The resulting `output/Image` and DTBs land in `output/out/` ready to flash with `rkflash.sh`.

### 7. What to re-check before the next kernel bump

When the SDK is updated, re-verify the following patches still apply:

- `aht30.c` is not yet upstream in the kernel IIO subsystem (as of 4.19-era the SDK uses) — if the kernel version moves, port to the new `iio_chan_spec` API
- `route_rgb` enable line — this is the single line that toggles the whole LCD on; if upstream flips its default, remove our override
- GT911 touch node — may be merged into the base DTS in a future SDK; remove our copy if so
- `wireless-bluetooth` pinctrl (`uart1m0_rtsn` + `uart1_gpios`) — Rockchip refactors these regularly
- `emmc` `rockchip,default-sample-phase = <90>` — panel/emmc-dependent, may need re-tuning for a different flash
- `sdio_pwrseq` `reset-gpios` — if the WiFi module changes, the GPIO may need updating

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
