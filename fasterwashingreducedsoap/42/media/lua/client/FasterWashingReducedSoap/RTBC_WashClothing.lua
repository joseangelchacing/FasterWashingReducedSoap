require "TimedActions/ISWashClothing"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_MULTIPLIER = 0.5
local MIN_MULTIPLIER = 0.1
local MAX_MULTIPLIER = 2.0

local function getClothingWashTimeMultiplier()
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options.ClothingWashTimeMultiplier

    if type(multiplier) ~= "number" then
        multiplier = DEFAULT_MULTIPLIER
    end

    return math.max(MIN_MULTIPLIER, math.min(MAX_MULTIPLIER, multiplier))
end

local function patchClothingWashDuration()
    if not ISWashClothing or not ISWashClothing.getDuration then
        print("[Faster Washing & Reduced Soap] ERROR: ISWashClothing.getDuration was not found.")
        return
    end

    if ISWashClothing._RTBC_WashDurationPatched then
        return
    end

    local originalGetDuration = ISWashClothing.getDuration

    ISWashClothing.getDuration = function(self)
        local originalDuration = originalGetDuration(self)

        if self.item and instanceof(self.item, "Clothing") then
            if self.character and self.character:isTimedActionInstant() then
                return originalDuration
            end

            return math.max(1, originalDuration * getClothingWashTimeMultiplier())
        end

        return originalDuration
    end

    ISWashClothing._RTBC_WashDurationPatched = true
    print("[Faster Washing & Reduced Soap] Clothing washing duration multiplier patch loaded.")
end

Events.OnGameBoot.Add(patchClothingWashDuration)
