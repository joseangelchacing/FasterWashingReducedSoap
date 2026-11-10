require "TimedActions/ISWashYourself"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_MULTIPLIER = 0.5
local MIN_MULTIPLIER = 0.1
local MAX_MULTIPLIER = 2.0

local function getMyselfWashTimeMultiplier()
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options.MyselfWashTimeMultiplier

    if type(multiplier) ~= "number" then
        multiplier = DEFAULT_MULTIPLIER
    end

    return math.max(MIN_MULTIPLIER, math.min(MAX_MULTIPLIER, multiplier))
end

function patchMyselfWashDuration()
    if not ISWashYourself or not ISWashYourself.getDuration then
        print("[Faster Washing & Reduced Soap] ERROR: ISWashYourself.getDuration was not found.")
        return
    end

    if ISWashYourself._RTBC_MyselfWashDurationPatched then
        return
    end

    local originalGetDuration = ISWashYourself.getDuration

    ISWashYourself.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        -- Keep instant actions instant.
        if self.character and self.character:isTimedActionInstant() then
            return originalDuration
        end

        return math.max(1, originalDuration * getMyselfWashTimeMultiplier())
    end

    ISWashYourself._RTBC_MyselfWashDurationPatched = true
    print("[Faster Washing & Reduced Soap] Washing-yourself duration multiplier patch loaded.")
end

Events.OnGameBoot.Add(patchMyselfWashDuration)
