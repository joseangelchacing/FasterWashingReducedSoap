-- Faster Washing & Reduced Soap Consumption
-- Shared timed-action duration patch for single-player and multiplayer.
--
-- IMPORTANT:
-- This file lives under media/lua/shared so both the client and dedicated
-- server apply the same getDuration() multiplier. In multiplayer, the server
-- calculates the authoritative NetTimedAction duration; patching only the
-- client can make the progress bar finish before the server-side action.
--
-- Sandbox multipliers are read when getDuration() is called, not at load time.

require "TimedActions/ISWashClothing"
require "TimedActions/ISWashYourself"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_CLOTHING_MULTIPLIER = 0.5
local DEFAULT_SELF_MULTIPLIER = 0.5
local MIN_DURATION_MULTIPLIER = 0.1
local MAX_DURATION_MULTIPLIER = 2.0

local function getDurationMultiplier(optionName, defaultValue)
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options[optionName]

    if type(multiplier) ~= "number" then
        multiplier = defaultValue
    end

    -- Guard against malformed/out-of-range server settings.
    return math.max(
        MIN_DURATION_MULTIPLIER,
        math.min(MAX_DURATION_MULTIPLIER, multiplier)
    )
end

local function patchClothingWashDuration()
    if not ISWashClothing or type(ISWashClothing.getDuration) ~= "function" then
        print("[Faster Washing & Reduced Soap] ERROR: ISWashClothing.getDuration was not found.")
        return
    end

    if ISWashClothing._RTBC_WashDurationPatched then
        return
    end

    local originalGetDuration = ISWashClothing.getDuration

    ISWashClothing.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        -- Preserve vanilla instant/debug actions and non-positive durations.
        if type(originalDuration) ~= "number" or originalDuration <= 1 then
            return originalDuration
        end

        -- Only scale actual clothing items, not other ISWashClothing targets.
        if self.item and instanceof(self.item, "Clothing") then
            local multiplier = getDurationMultiplier(
                "ClothingWashTimeMultiplier",
                DEFAULT_CLOTHING_MULTIPLIER
            )
            return math.max(1, originalDuration * multiplier)
        end

        return originalDuration
    end

    ISWashClothing._RTBC_WashDurationPatched = true
    print("[Faster Washing & Reduced Soap] Clothing washing duration multiplier patch loaded (shared client/server).")
end

local function patchMyselfWashDuration()
    if not ISWashYourself or type(ISWashYourself.getDuration) ~= "function" then
        print("[Faster Washing & Reduced Soap] ERROR: ISWashYourself.getDuration was not found.")
        return
    end

    if ISWashYourself._RTBC_MyselfWashDurationPatched then
        return
    end

    local originalGetDuration = ISWashYourself.getDuration

    ISWashYourself.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        -- Preserve vanilla instant/debug actions and non-positive durations.
        if type(originalDuration) ~= "number" or originalDuration <= 1 then
            return originalDuration
        end

        local multiplier = getDurationMultiplier(
            "MyselfWashTimeMultiplier",
            DEFAULT_SELF_MULTIPLIER
        )
        return math.max(1, originalDuration * multiplier)
    end

    ISWashYourself._RTBC_MyselfWashDurationPatched = true
    print("[Faster Washing & Reduced Soap] Washing-yourself duration multiplier patch loaded (shared client/server).")
end

-- Apply immediately after requiring the vanilla action classes. This ensures
-- constructors calling getDuration() receive the scaled value from the start.
patchClothingWashDuration()
patchMyselfWashDuration()
