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

require "FasterWashingReducedSoap/RTBC_Diagnostics"
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
        FasterWashingReducedSoap.log("ERROR", "ISWashClothing.getDuration was not found.")
        return
    end

    if ISWashClothing._RTBC_WashDurationPatched then
        FasterWashingReducedSoap.log("PATCH", "Clothing duration patch already installed; skipping duplicate.")
        return
    end

    local originalGetDuration = ISWashClothing.getDuration

    ISWashClothing.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        -- Preserve vanilla instant/debug actions and non-positive durations.
        if type(originalDuration) ~= "number" or originalDuration <= 1 then
            FasterWashingReducedSoap.log("DURATION", string.format(
                "clothing action item=%s original=%s result=unchanged (instant/non-positive/non-number)",
                FasterWashingReducedSoap.describeItem(self.item),
                FasterWashingReducedSoap.formatValue(originalDuration)
            ))
            return originalDuration
        end

        -- Only scale actual clothing items, not other ISWashClothing targets.
        if self.item and instanceof(self.item, "Clothing") then
            local multiplier = getDurationMultiplier(
                "ClothingWashTimeMultiplier",
                DEFAULT_CLOTHING_MULTIPLIER
            )
            local newDuration = math.max(1, originalDuration * multiplier)
            FasterWashingReducedSoap.log("DURATION", string.format(
                "clothing action item=%s original=%s multiplier=%s result=%s",
                FasterWashingReducedSoap.describeItem(self.item),
                FasterWashingReducedSoap.formatValue(originalDuration),
                FasterWashingReducedSoap.formatValue(multiplier),
                FasterWashingReducedSoap.formatValue(newDuration)
            ))
            return newDuration
        end

        FasterWashingReducedSoap.log("DURATION", string.format(
            "clothing action item=%s original=%s result=unchanged (target is not Clothing)",
            FasterWashingReducedSoap.describeItem(self.item),
            FasterWashingReducedSoap.formatValue(originalDuration)
        ))
        return originalDuration
    end

    ISWashClothing._RTBC_WashDurationPatched = true
    FasterWashingReducedSoap.log("PATCH", string.format(
        "clothing duration wrapper installed; sandbox multiplier=%s",
        FasterWashingReducedSoap.formatValue(getDurationMultiplier("ClothingWashTimeMultiplier", DEFAULT_CLOTHING_MULTIPLIER))
    ))
end

local function patchMyselfWashDuration()
    if not ISWashYourself or type(ISWashYourself.getDuration) ~= "function" then
        FasterWashingReducedSoap.log("ERROR", "ISWashYourself.getDuration was not found.")
        return
    end

    if ISWashYourself._RTBC_MyselfWashDurationPatched then
        FasterWashingReducedSoap.log("PATCH", "Personal-wash duration patch already installed; skipping duplicate.")
        return
    end

    local originalGetDuration = ISWashYourself.getDuration

    ISWashYourself.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        -- Preserve vanilla instant/debug actions and non-positive durations.
        if type(originalDuration) ~= "number" or originalDuration <= 1 then
            FasterWashingReducedSoap.log("DURATION", string.format(
                "personal wash original=%s result=unchanged (instant/non-positive/non-number)",
                FasterWashingReducedSoap.formatValue(originalDuration)
            ))
            return originalDuration
        end

        local multiplier = getDurationMultiplier(
            "MyselfWashTimeMultiplier",
            DEFAULT_SELF_MULTIPLIER
        )
        local newDuration = math.max(1, originalDuration * multiplier)
        FasterWashingReducedSoap.log("DURATION", string.format(
            "personal wash original=%s multiplier=%s result=%s",
            FasterWashingReducedSoap.formatValue(originalDuration),
            FasterWashingReducedSoap.formatValue(multiplier),
            FasterWashingReducedSoap.formatValue(newDuration)
        ))
        return newDuration
    end

    ISWashYourself._RTBC_MyselfWashDurationPatched = true
    FasterWashingReducedSoap.log("PATCH", string.format(
        "personal duration wrapper installed; sandbox multiplier=%s",
        FasterWashingReducedSoap.formatValue(getDurationMultiplier("MyselfWashTimeMultiplier", DEFAULT_SELF_MULTIPLIER))
    ))
end

-- Apply immediately after requiring the vanilla action classes. This ensures
-- constructors calling getDuration() receive the scaled value from the start.
patchClothingWashDuration()
patchMyselfWashDuration()
