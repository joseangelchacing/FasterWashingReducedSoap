require "TimedActions/ISWashClothing"
require "TimedActions/ISWashYourself"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_SOAP_MULTIPLIER = 0.2
local DEFAULT_CLEANING_LIQUID_MULTIPLIER = 0.02

local function getSoapConsumptionMultiplier()
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options.SoapConsumptionMultiplier

    if type(multiplier) ~= "number" then
        multiplier = DEFAULT_SOAP_MULTIPLIER
    end

    return math.max(0.01, math.min(1.0, multiplier))
end

local function getCleaningLiquidConsumptionMultiplier()
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options.CleaningLiquidConsumptionMultiplier

    if type(multiplier) ~= "number" then
        multiplier = DEFAULT_CLEANING_LIQUID_MULTIPLIER
    end

    return math.max(0.01, math.min(1.0, multiplier))
end

local VANILLA_SOAP_USE_DELTA = 0.005

local function getNewSoapUseDelta()
    return VANILLA_SOAP_USE_DELTA * getSoapConsumptionMultiplier()
end

local function updateSoapConsumption(soap)
    if not soap or not instanceof(soap, "DrainableComboItem") then
        return
    end

    if soap:getFullType() ~= "Base.Soap2" then
        return
    end

    local modData = soap:getModData()
    local newUseDelta = getNewSoapUseDelta()
    local currentUseDelta = soap:getUseDelta()
    local savedUseDelta = modData.RTBC_SoapUseDelta

    local previousUseDelta = currentUseDelta

    if type(savedUseDelta) == "number" and savedUseDelta > 0 then
        previousUseDelta = savedUseDelta
    end

    local remaining = soap:getCurrentUses() * previousUseDelta

    if math.abs(currentUseDelta - newUseDelta) < 0.0000001
        and math.abs(previousUseDelta - newUseDelta) < 0.0000001 then
        modData.RTBC_SoapUseDelta = newUseDelta
        return
    end

    soap:setUseDelta(newUseDelta)
    soap:setCurrentUsesFloat(remaining)

    modData.RTBC_SoapUseDelta = newUseDelta
end

-- Return the number of usable washing actions represented by the soap list.
-- Solid soap uses getCurrentUses(), which is already adjusted by updateSoapConsumption().
-- Cleaning liquid is converted using the exact per-action amount used by our
-- RTBC_CleaningLiquidConsumption patch, rather than vanilla's fixed amount * 10.
local function getSoapRemainingWithAdjustedLiquid(soaps)
    local total = 0

    if not soaps then
        return total
    end

    for i = 0, soaps:size() - 1 do
        local soap = soaps:get(i)

        if instanceof(soap, "DrainableComboItem") then
            updateSoapConsumption(soap)
            total = total + soap:getCurrentUses()
        else
            local fluidContainer = soap:getFluidContainer()

            if fluidContainer and fluidContainer:contains(Fluid.CleaningLiquid) then
                local vanillaAmount = ZomboidGlobals.CleanStainCleaningFluidAmount
                local multiplier = getCleaningLiquidConsumptionMultiplier()
                local amountPerWash = vanillaAmount * multiplier

                if type(amountPerWash) == "number" and amountPerWash > 0 then
                    total = total + (fluidContainer:getAmount() / amountPerWash)
                end
            end
        end
    end

    return total
end

local function patchSoapConsumption()
    if not ISWashClothing or not ISWashClothing.GetSoapRemaining then
        print("[Faster Washing & Reduced Soap] ERROR: GetSoapRemaining was not found.")
        return
    end

    if ISWashClothing._RTBC_SoapConsumptionPatched then
        return
    end

    ISWashClothing.GetSoapRemaining = getSoapRemainingWithAdjustedLiquid

    ISWashClothing._RTBC_SoapConsumptionPatched = true
    print("[Faster Washing & Reduced Soap] Soap consumption and availability estimate patch loaded.")
end

Events.OnGameBoot.Add(patchSoapConsumption)
