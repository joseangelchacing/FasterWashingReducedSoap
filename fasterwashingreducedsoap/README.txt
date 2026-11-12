Faster Washing & Reduced Soap Consumption [B42]
By Chapin
For Project Zomboid Build 42.22.2

OVERVIEW
A small quality-of-life mod that makes washing less time-consuming and reduces
the amount of cleaning products consumed. All four settings are configurable
in the Sandbox options.

FEATURES
- Configurable clothing-washing duration.
- Configurable washing-yourself duration.
- Configurable solid-soap consumption.
- Configurable CleaningLiquid consumption when washing clothing.
- Corrected soap-availability estimate so the washing menu accounts for the
  reduced CleaningLiquid consumption.
- Preserves instant timed actions.
- Does not replace or modify vanilla game files.

DEFAULT SANDBOX SETTINGS
- Clothing washing time: 0.5 (50% of normal duration).
- Washing-yourself time: 0.5 (50% of normal duration).
- Solid soap consumption: 0.02 (2% of normal consumption).
- CleaningLiquid consumption: 0.02 (2% of normal consumption).

CONFIGURATION RANGES
- Washing duration multipliers: 0.1 to 2.0.
- Consumption multipliers: 0.01 to 1.0.

SCOPE
- The CleaningLiquid reduction applies to washing clothing.
- The solid-soap reduction applies to the supported washing actions patched
  by the mod.
- Duration and consumption patches are loaded from shared Lua so client and server install the same logic in multiplayer. Full multiplayer gameplay testing is still recommended.

INSTALLATION
1. Subscribe to the mod on Steam Workshop, or extract this folder into:
   C:/Users/<your-user>/Zomboid/mods/
2. Enable "Faster Washing & Reduced Soap Consumption [B42]" in the Mods menu.
3. Configure its options in the Sandbox settings when creating or editing a
   save.

INTERNAL MOD ID
FasterWashingReducedSoap

INTERNAL NAMESPACE
FasterWashingReducedSoap
Legacy RTBC-prefixed item modData and patch-guard keys are intentionally retained internally to preserve compatibility with items and saves created by earlier local versions of this mod.
