# Microsoft OneDrive Plasmoid for KDE Plasma 6

A native, modern KDE Plasma 6 widget (Plasmoid) to monitor and control the [Microsoft OneDrive client for Linux by abraunegg](https://github.com/abraunegg/onedrive).

![KDE Plasma 6](https://img.shields.io/badge/KDE-Plasma%206-blue?logo=kde)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)

---

## Features

- **Native KDE Plasma 6 Experience**:
  - Built with modern **QML, Kirigami, and PlasmaComponents3**.
  - Adapts seamlessly to your desktop theme (Breeze Light, Breeze Dark, custom accent colors).
  - Compact representation for your panel or system tray, with animated sync indicators and status emblems.
  - Rich interactive pop-up (Full representation) with storage usage, activity log, and quick controls.

- **Storage Quota & Free Space**:
  - Visual cloud storage bar showing used space, free space, total capacity, and percentage.

- **Quick Control Actions**:
  - **Sync Now**: Trigger immediate synchronization under systemd or CLI.
  - **Pause / Resume**: Suspend and restart synchronization on the fly.
  - **Open Local Folder**: One-click opening of your local OneDrive directory in **Dolphin**.
  - **Open on Web**: Direct shortcut to your OneDrive files in your browser.
  - **View Logs**: Quick access to live systemd service logs.

- **Recent Activity Feed**:
  - Real-time log of recently synced items (Uploaded, Downloaded, Deleted, Moved, Directories created).
  - Click on any item to view/reveal it directly in Dolphin.

- **Dual Backend Architecture**:
  - **Systemd User Service (Default & Recommended)**: Directly monitors and controls `onedrive.service` via systemd (`systemctl --user`).
  - **Standalone Process Mode**: Fallback mode to monitor an active standalone `onedrive` process.

- **Plasmoid Settings**:
  - Configurable polling intervals, custom directories, notification toggles, and icon styles (Breeze monochrome or official colored logo).

---

## Requirements

1. **KDE Plasma 6** (KDE Plasma 6.0 or newer).
2. **OneDrive Client for Linux (abraunegg)**:
   - Install via your distribution's package manager:
     - **Arch / Manjaro**: `sudo pacman -S onedrive`
     - **Fedora**: `sudo dnf install onedrive`
     - **Ubuntu / Debian**: `sudo apt install onedrive`
   - Initial setup & authentication:
     ```bash
     onedrive
     ```
     Follow the instructions to log in with your Microsoft account.

---

## Installation

### Quick Install (User Mode)

Run the included install script:

```bash
./install.sh
```

This will register and install the applet into `~/.local/share/plasma/plasmoids/org.kde.plasma.onedrive`.

### Adding the Widget to your Panel / Desktop

1. Right-click on your KDE Plasma panel or desktop.
2. Select **Add Widgets...** (or press `Meta+W`).
3. Search for **OneDrive**.
4. Drag and drop it onto your panel or into your System Tray.

### Testing without Panel Placement

You can test the plasmoid in a standalone test window anytime by running:

```bash
plasmawindowed org.kde.plasma.onedrive
```

---

## Configuration & Usage

Right-click on the OneDrive icon in your panel or click the configure button in the pop-up to open settings:

- **Operation Mode**: Choose between *Systemd User Service* (`onedrive.service`) or *Standalone CLI*.
- **Local Sync Folder**: Specify your OneDrive folder (defaults to `~/OneDrive`).
- **Check Interval**: Interval (in seconds) to check sync status and journal logs.
- **Quota Refresh Interval**: Frequency to query cloud storage quota.
- **Panel Icon Style**: Choose between adaptive Breeze monochrome or official blue cloud.

To enable the systemd service to run automatically on user login:

```bash
systemctl --user enable --now onedrive.service
```

---

## Authors & Acknowledgments

- **Author & Maintainer**: Marcus Vinícius ([@deomkds](https://github.com/deomkds) - `mv.cunha2009@gmail.com`)
- **Acknowledgments**:
  - **Daniel Borges de Oliveira**: Original author of the `onedrive_tray` application.
  - **abraunegg**: Creator and maintainer of the excellent [OneDrive Client for Linux](https://github.com/abraunegg/onedrive).

## AI Disclaimer

This project was developed with the assistance of Artificial Intelligence (AI) tools for code modernization, architecture adaptation, and KDE Plasma 6 development.

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0-or-later).
