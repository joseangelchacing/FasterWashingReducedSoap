# Development Guide

## 1. Project Overview

**Faster Washing & Reduced Soap Consumption [B42]** is a Project Zomboid mod written in Lua.

- **Author:** Chapin
- **Mod ID:** `FasterWashingReducedSoap`
- **Steam Workshop ID:** `3835601428`
- **Target game version:** Build 42.22.2

The project modifies washing and cleaning mechanics to reduce washing time and cleaning-product consumption while preserving the vanilla gameplay structure.

## 2. Project Scope

The mod focuses on washing, cleaning, soap, water consumption, and related gameplay mechanics.

Its architecture should remain open to future improvements in these areas.

Potential future features include:

- Reduced water consumption during washing.
- Different water requirements depending on washing actions.
- Rain effects on washing or cleaning effectiveness.
- Additional improvements to washing and hygiene mechanics.

These are possible future extensions, not currently implemented features.

## 3. Current Features and Configuration

The current implementation provides four configurable Sandbox settings:

| Setting                    | Default |
| -------------------------- | ------: |
| Clothing washing duration  |    0.5x |
| Personal washing duration  |    0.5x |
| Solid soap consumption     |   0.02x |
| CleaningLiquid consumption |   0.02x |

### Duration multipliers

A value of `0.5` means the action takes 50% of its original duration.

Supported configuration range: `0.1` to `2.0`.

### Consumption multipliers

A value of `0.02` means the action consumes 2% of its original amount.

Supported configuration range: `0.01` to `1.0`.

For solid soap, the vanilla `Base.Soap2` reference `UseDelta` is `0.05`. With a consumption multiplier of `0.02`, the intended effective value is:

`0.05 × 0.02 = 0.001`

The liquid cleaner reduction applies to clothing washing. Solid soap reduction applies to supported washing actions modified by the mod.

The implementation must preserve vanilla behavior outside the intended modifications.

## 4. Technical Architecture

The project uses Lua and the Project Zomboid mod structure.

The current implementation uses shared Lua scripts located in `media/lua/shared`. Client and server execution must be considered when developing and testing multiplayer functionality.

Code should be placed in the appropriate execution environment:

- `client`: client-side functionality.
- `server`: server-side functionality.
- `shared`: functionality that must be available to both environments.

The placement of code in `shared` does not automatically guarantee multiplayer synchronization.

Changes involving inventory, item properties, actions, or player state must respect the game's synchronization mechanisms.

Avoid replacing vanilla game files when a compatible extension or patch is possible.

## 5. Development Principles

Prioritize:

1. Correct functionality.
2. Reliability and stability.
3. Compatibility with the target game version.
4. Multiplayer correctness.
5. Simple and readable code.
6. Maintainability and extensibility.
7. Performance and low resource consumption.

Avoid unnecessary dependencies, duplicated logic, excessive abstractions, and overengineering.

Prefer focused changes that solve a clearly identified problem.

## 6. Multiplayer Compatibility

Multiplayer behavior must be considered whenever a feature modifies inventory, item properties, player actions, or shared gameplay state.

Testing should distinguish between:

- Single-player behavior.
- Multiplayer client behavior.
- Server-side execution.
- Dedicated-server behavior.

Full multiplayer compatibility must not be claimed until the relevant scenarios have been tested.

## 7. Logging and Debugging

New or modified functionality should provide useful diagnostic information when appropriate.

Use the prefix:

`[FWRSC]`

Logs should help investigate:

- Script loading and execution environment.
- Sandbox configuration values.
- Original and modified values.
- Important calculations.
- Action execution.
- Success, failure, or skipped execution.
- Unexpected or duplicate execution.

Avoid repetitive messages and excessive console output.

Detailed diagnostic logging should be temporary or configurable when appropriate.

## 8. Testing

Testing should be proportional to the changes introduced.

Distinguish between:

- Static code inspection.
- Syntax checks.
- Automated checks.
- In-game testing.
- Multiplayer testing.
- Dedicated-server testing.

Document important findings and known limitations.

Never describe a feature as tested or verified when it has only been inspected in code.

## 9. Performance and Maintainability

The mod should remain lightweight.

Prefer:

- Minimal runtime overhead.
- Efficient event and method handling.
- Clear separation of responsibilities.
- Reusable logic where it provides genuine value.
- Compatibility with vanilla mechanics and other mods where possible.

New features should fit the existing architecture without introducing unnecessary complexity.

## 10. Documentation

Keep documentation synchronized with the actual implementation.

- `README.md`: public project overview, features, installation, and configuration.
- `DEVELOPMENT.md`: technical architecture and development principles.
- `CHANGELOG.md`: changes introduced over time.
- `README.txt` and Workshop descriptions: mod and installation information for players.

Do not describe planned functionality as implemented.

## 11. Final Principle

The objective is to maintain a reliable, lightweight, understandable, and extensible mod that improves washing and cleaning mechanics without unnecessarily compromising vanilla gameplay.
