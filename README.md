# qs-wallpaper-picker

A Quickshell wallpaper picker for Hyprland with support for image and video wallpapers, animated transitions, and optional dynamic theming through matugen.

## Preview

<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/d14fce0d-4ef9-4cca-8c41-94e4ffd893bd" />


## Features

- Local wallpaper browsing
- Image and video wallpaper support
- Animated transitions with `awww`
- Video wallpapers with `mpvpaper`
- Optional dynamic colors using `matugen`
- Optional Hyprland reload
- Optional Waybar reload
- Fully configurable through `config/Settings.qml`

## Requirements

- Hyprland
- Quickshell
- awww
- mpvpaper
- matugen (optional)
- Waybar (optional)

## Installation

Clone the repository:

```bash
git clone https://github.com/magetsu002/qs-wallpaper-picker.git
cd qs-wallpaper-picker
```

Create your local config:

```bash
cp config/Settings.qml.example config/Settings.qml
```

Edit it:

```bash
nano config/Settings.qml
```

Set your wallpaper directory:

```qml
property string wallpaperDir: homeDir + "/Wallpapers"
```

## Usage

Run the picker with:

```bash
quickshell -p Main.qml
```

You can also bind it to a key in Hyprland for faster access.

## Configuration

All behavior is controlled through:

```
config/Settings.qml
```

You can enable or disable:

- dynamic colors
- matugen integration
- Hyprland reload
- Waybar reload
- other system reloads

## Dynamic Theming

Enable these options if you want wallpaper-based recoloring and reloads:

```qml
property bool enableDynamicColors: true
property bool enableMatugen: true
property bool enableHyprReload: true
property bool enableWaybarReload: true
```

Disable them if you only want wallpaper changes without recoloring:

```qml
property bool enableDynamicColors: false
property bool enableMatugen: false
property bool enableHyprReload: false
property bool enableWaybarReload: false
```

## Important Notes / Warnings

- Do not run multiple wallpaper or theming tools at the same time (e.g. pywal, other matugen scripts, custom watchers).  
  This can cause unexpected color overrides or race conditions.

- If your Waybar or Hyprland colors change even when disabled in `Settings.qml`, you likely have:
  - another matugen instance
  - a background script
  - or a file watcher modifying `colors.css` / `colors.conf`

- This tool assumes it is the **single source of truth** for:
  - wallpaper changes
  - dynamic color generation (if enabled)

- If you use custom Waybar launch scripts, ensure the path in `Settings.qml` is correct.

- Always keep your `Settings.qml` local and do not commit it.

## Credits

Wallpaper picker UI design adapted from:  
https://github.com/ilyamiro/nixos-configuration

Ported and extended for Arch Linux, Hyprland, and Quickshell.

## License

MIT
