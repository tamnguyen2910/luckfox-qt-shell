# Luckfox Shell

A Qt5/QML infotainment shell for the **Luckfox Pico Ultra W** — 6 touch tabs on an 800×480 display, software-rendered on an ARM Cortex-A7, no GPU.

![Status](https://img.shields.io/badge/status-active-success) ![Qt](https://img.shields.io/badge/Qt-5.15-41cd52) ![Platform](https://img.shields.io/badge/platform-ARMv7l-blue)

---

## Overview

Luckfox Shell is a Qt5/QML-based automotive infotainment application for the Luckfox Pico Ultra W platform. It provides a comprehensive in-vehicle entertainment and information system with six touch-optimized modules covering vehicle telemetry, media playback, calendar management, network connectivity, voice recording, and 3D visualization.

---

## App Features

| Tab | Function | Key Features |
|-----|----------|--------------|
| **Dashboard** | System telemetry | Real-time CPU/RAM/disk usage, AHT30 temperature/humidity, network status, top processes |
| **Music** | Music playback | Local file browser (`/media/music`), playback controls, playlist management, ALSA audio |
| **Calendar** | Calendar | Monthly grid + agenda, Vietnamese lunar dates, holiday highlighting, touch-friendly UI |
| **WiFi** | Network management | Network scanning, on-screen QWERTY keyboard, connect/disconnect via `wpa_cli` |
| **Recorder** | Record & playback | Push-to-record, real-time waveform display, file management, ALSA audio |
| **Wireframe** | 3D model | Rotating pyramid + cylinder + cube at 60fps, C++ rendered without GPU |

### UI Design

- **Single-process shell** with vertical tab rail (left edge) and 688×408 content area
- **Touch-friendly**: 48px minimum targets, 12px grid spacing, large touch areas
- **Dark mode** (hardware-locked, no light/dark toggle)
- **Unified design system** (`qml/components/themes/Theme.js` — "Nordic Aurora") shared across all modules

---

## Hardware

- **Board**: Luckfox Pico Ultra W (Rockchip RV1106, ARM Cortex-A7)
- **Display**: 800×480 RGB666 LCD, GT911 capacitive touch (I2C3)
- **Audio**: ALSA (`/dev/snd/...`)
- **Sensors**: AHT30 temperature/humidity (I2C2 @ 0x38)
- **Network**: SDIO WiFi (wpa_supplicant / wpa_cli)
- **Other**: EC11 rotary encoder, USB, MIPI CSI camera, Bluetooth (UART1)

---

## System Architecture

### Directory Structure

```
09_Final_project/
├── luckfox_shell.pro          # qmake project file
├── src/                       # C++ backend
│   ├── main.cpp               # Entry point
│   ├── apptheme.{h,cpp}       # Runtime theme selector
│   ├── lunar.{h,cpp}          # Vietnamese lunar calendar
│   └── ...
├── qml/
│   ├── shell.qml              # Main window + tab rail
│   └── components/
│       ├── themes/Theme.js    # Design system (colors, fonts, sizes)
│       └── ShellTabBar.qml    # Vertical tab rail
├── modules/
│   ├── dashboard/             # System telemetry (CPU, RAM, sensors)
│   ├── music/                 # Music playback (ALSA)
│   ├── calendar/              # Calendar + agenda + lunar
│   ├── wifi/                  # Network management (wpa_cli)
│   ├── voicetest/             # Record/playback (ALSA)
│   ├── wireframe/             # 3D model (QQuickPaintedItem)
│   └── photoframe/            # Photo slideshow
├── scripts/
│   ├── build.sh               # Cross-compile (qmake + make)
│   ├── deploy.sh              # SCP binary to board
│   └── run.sh                 # Run on board via SSH
└── README.md
```

### Data Flow

```
┌─────────────────────────────────────────┐
│              QML Frontend               │
│  shell.qml + modules/*/qml/*.qml       │
│  (Theme.js — unified design system)     │
└────────────────┬────────────────────────┘
                 │ Qt Signals/Properties
┌────────────────┴────────────────────────┐
│            C++ Backend                  │
│  audioplayer · wifimanager · lunar      │
│  sysinforeader · AudioRecorder          │
│  FastDataWorker · SlowDataWorker        │
│  SensorWorker · DeviceManager           │
└────────────────┬────────────────────────┘
                 │ /dev/fb0, /dev/input/*, /dev/snd/*, /sys/class/hwmon/*
┌────────────────┴────────────────────────┐
│          Linux Kernel + Drivers         │
│  AHT30 (I²C) · GT911 touch · ALSA      │
│  WiFi SDIO · Framebuffer               │
└─────────────────────────────────────────┘
```

### Worker Pattern

- **FastDataWorker**: High-rate sensor reads (CPU, RAM)
- **SlowDataWorker**: Low-rate sensor reads (temperature, humidity)
- **SensorWorker**: Aggregates I²C data from AHT30

---

## Tasks Completed

### 1. System-level (Kernel + Drivers)

| Task | Description |
|------|-------------|
| **AHT30 driver** | Custom I²C driver for temperature/humidity sensor (no upstream support) |
| **LCD display** | Enabled RGB route in device tree (disabled by default in IPC dtsi) |
| **Touch GT911** | Added I2C3 touch node to DTS for capacitive touch |
| **WiFi SDIO** | Enabled wireless-sdio driver + wpa_supplicant in buildroot |
| **Buildroot config** | Added Qt5, wpa_supplicant, ALSA to defconfig |

### 2. Qt5/QML Application

| Task | Description |
|------|-------------|
| **Shell framework** | Created shell.qml with tab rail + content area |
| **Design system** | Built Theme.js ("Nordic Aurora") unified across all modules |
| **6 modules** | Dashboard → Music → Calendar → WiFi → Recorder → Wireframe (hardware-reviewed) |
| **Build scripts** | Created build.sh, deploy.sh, run.sh for cross-compilation and SCP |

### 3. Development Workflow

```
Dashboard (1) → Music (2) → Calendar (3) → WiFi (4) → Recorder (5) → Wireframe (6)
     ↓              ↓            ↓             ↓            ↓              ↓
   Build &       Build &      Build &       Build &      Build &        Build &
   Deploy        Deploy       Deploy        Deploy       Deploy         Deploy
     ↓              ↓            ↓             ↓            ↓              ↓
   Review         Review       Review        Review       Review         Review
   hardware       hardware     hardware      hardware     hardware       hardware
```

Each tab was built separately, deployed to the board, and reviewed on real hardware before moving to the next tab.

---

## Build & Deploy

### Prerequisites

- ARM buildroot toolchain (`arm-buildroot-linux-gnueabihf-`)
- Qt5 sysroot from Luckfox buildroot output
- qmake for target (`devices/linux-buildroot-g++` mkspec)
- Libraries: Qt5Core, Qt5Gui, Qt5Quick, Qt5Qml, Qt5Svg, Qt5Network, ALSA

### Build

```bash
# Configure qmake path (or edit inside build.sh)
export LUCKFOX_QMAKE=/path/to/buildroot/output/host/bin/qmake

# Build
bash scripts/build.sh
# → output: build/luckfox-shell
```

### Deploy to Board

```bash
# Configure SSH
export LUCKFOX_SSH_KEY=/path/to/id_ed25519
export LUCKFOX_BOARD_IP=192.168.1.3      # Board IP
export LUCKFOX_BOARD_USER=root

# Deploy (SCP binary + kill old process + chmod)
bash scripts/deploy.sh
```

### Run on Board

```bash
bash scripts/run.sh
# → SSH into board, set env vars, launch app
```

**Env vars on board** (set automatically by `run.sh`):
```
QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0:size=800x480:mmsize=800x480
QT_QPA_FONTDIR=/usr/share/fonts/dejavu/
LD_LIBRARY_PATH=/usr/lib:/usr/lib/qt5/lib:/usr/lib/aarch64-linux-gnu
```
