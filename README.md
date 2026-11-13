# Faster Washing & Reduced Soap Consumption [B42]

A lightweight Project Zomboid mod that makes washing faster and reduces soap consumption, with configurable gameplay settings.

**Author:** Chapin

**Target version:** Project Zomboid Build 42.22.2

**Mod ID:** `FasterWashingReducedSoap`

**Steam Workshop:** [3835601428](https://steamcommunity.com/sharedfiles/filedetails/?id=3835601428)

---

## Overview

Faster Washing & Reduced Soap Consumption improves the vanilla washing experience by reducing washing times and cleaning-product consumption.

The mod uses configurable Sandbox options and aims to preserve vanilla mechanics while keeping its implementation lightweight and compatible with the game's existing systems.

## Features

- Configurable clothing-washing duration.
- Configurable personal-washing duration.
- Reduced solid soap consumption.
- Reduced CleaningLiquid consumption when washing clothing.
- Independent Sandbox configuration options.
- Preserves vanilla instant timed-action behavior.

## Default Configuration

| Setting                    | Default |
| -------------------------- | ------: |
| Clothing washing duration  |    0.5x |
| Personal washing duration  |    0.5x |
| Solid soap consumption     |   0.02x |
| CleaningLiquid consumption |   0.02x |

### Configuration Ranges

| Setting type            | Minimum | Maximum |
| ----------------------- | ------: | ------: |
| Duration multipliers    |     0.1 |     2.0 |
| Consumption multipliers |    0.01 |     1.0 |

A duration multiplier of `0.5` means the action takes half its original time.

A consumption multiplier of `0.02` means the action consumes 2% of its original amount.

## Technical Information

- **Language:** Lua
- **Game:** Project Zomboid
- **Target build:** 42.22.2
- **Architecture:** Shared Lua scripts for washing duration and soap consumption, loaded in the game's shared script context.
- **Configuration:** Sandbox options

The mod extends existing game mechanics rather than replacing vanilla game files.

The mod's current Lua implementation is located in `media/lua/shared`. These scripts provide shared washing-duration and soap-consumption logic. Full multiplayer gameplay testing is still recommended to verify synchronization and compatibility in different server configurations.

## Project Structure

```text
fasterwashingreducedsoap/              # Git repository
├── .emmyrc.json                       # EmmyLua analyzer configuration
├── .gitignore
├── .pzstudioignore
├── .vscode/
│   ├── extensions.json                # Recommended VS Code extensions
│   └── settings.json                  # Shared editor settings
├── CHANGELOG.md
├── DEVELOPMENT.md
├── README.md
├── project.json                       # PZ Studio project and Workshop metadata
├── workshop/
│   ├── description.txt
│   └── preview.png
└── fasterwashingreducedsoap/          # Packaged game mod
    ├── 42/
    │   ├── media/
    │   │   ├── lua/shared/FasterWashingReducedSoap/
    │   │   │   ├── RTBC_CleaningLiquidConsumption.lua
    │   │   │   ├── RTBC_Diagnostics.lua
    │   │   │   ├── RTBC_SoapConsumption.lua
    │   │   │   └── RTBC_WashDuration.lua
    │   │   ├── lua/shared/Translate/
    │   │   │   ├── EN/Sandbox.json
    │   │   │   ├── EN/Sandbox_EN.txt
    │   │   │   ├── ES/Sandbox.json
    │   │   │   └── ES/Sandbox_ES.txt
    │   │   └── sandbox-options.txt
    │   └── mod.info
    ├── common/
    │   ├── icon.png
    │   └── poster.png
    ├── README.txt
    ├── WORKSHOP_DESCRIPTION_EN.txt
    └── WORKSHOP_DESCRIPTION_ES.txt
```

## Development Environment

The project is developed using:

- Lua
- Visual Studio Code
- Project Zomboid PZ Studio
- EmmyLua
- Project Zomboid Umbrella type definitions
- Git and GitHub

See [DEVELOPMENT.md](DEVELOPMENT.md) for technical architecture and development guidelines.

See [CHANGELOG.md](CHANGELOG.md) for project changes.

## Future Development

The project may expand to include additional washing and cleaning improvements, such as:

- Reduced water consumption.
- Different water requirements for washing actions.
- Rain effects on washing or cleaning effectiveness.
- Other improvements related to hygiene and cleaning mechanics.

These are potential future features and are not currently implemented.

## Installation

### Steam Workshop

Subscribe to the mod through the [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3835601428).

### Manual Installation

Place the mod folder in your Project Zomboid mods directory:

```text
C:/Users/<your-user>/Zomboid/mods/
```

Enable the mod from the in-game Mods menu.

## Author

**Chapin**

- GitHub: [joseangelchacing](https://github.com/joseangelchacing)
- Steam Workshop: [Faster Washing & Reduced Soap Consumption](https://steamcommunity.com/sharedfiles/filedetails/?id=3835601428)

---

A small quality-of-life improvement for the everyday realities of surviving in Project Zomboid.
