require "FasterWashingReducedSoap/RTBC_Diagnostics"
require "TimedActions/ISWashClothing"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_MULTIPLIER = 0.02
local MIN_MULTIPLIER = 0.01
local MAX_MULTIPLIER = 1.0

local function getCleaningLiquidConsumptionMultiplier()
    local options = SandboxVars and SandboxVars.FasterWashingReducedSoap
    local multiplier = options and options.CleaningLiquidConsumptionMultiplier

    if type(multiplier) ~= "number" then
        multiplier = DEFAULT_MULTIPLIER
    end

    return math.max(MIN_MULTIPLIER, math.min(MAX_MULTIPLIER, multiplier))
end

local function patchCleaningLiquidConsumption()
    if not ISWashClothing or not ISWashClothing.useSoap then
        FasterWashingReducedSoap.log("ERROR", "ISWashClothing.useSoap was not found.")
        return
    end

    if ISWashClothing._RTBC_CleaningLiquidConsumptionPatched then
        FasterWashingReducedSoap.log("PATCH", "Clothing soap-use patch already installed; skipping duplicate.")
        return
    end

    ISWashClothing.useSoap = function(self, item, part)
        local blood = 0
        if part then
            blood = item:getBlood(part)
        else
            blood = item:getBloodLevel()
        end

        FasterWashingReducedSoap.log("CLOTHING-WASH", string.format(
            "item=%s part=%s blood=%s soapCandidates=%s",
            FasterWashingReducedSoap.describeItem(item),
            tostring(part),
            FasterWashingReducedSoap.formatValue(blood),
            self.soaps and tostring(self.soaps:size()) or "nil"
        ))

        if blood > 0 then
            for i = 0, self.soaps:size() - 1 do
                local soap = self.soaps:get(i)

                if soap:hasComponent(ComponentType.FluidContainer) then
                    local fluidContainer = soap:getFluidContainer()

                    if fluidContainer and fluidContainer:getAmount() > 0 then
                        local vanillaAmount = ZomboidGlobals.CleanStainCleaningFluidAmount
                        local amountToConsume = vanillaAmount

                        if fluidContainer:contains(Fluid.CleaningLiquid) then
                            local multiplier = getCleaningLiquidConsumptionMultiplier()
                            amountToConsume = vanillaAmount * multiplier
                            FasterWashingReducedSoap.log("LIQUID-CONSUMPTION", string.format(
                                "item=%s amountBefore=%s vanillaPerWash=%s multiplier=%s amountConsumed=%s",
                                FasterWashingReducedSoap.describeItem(soap),
                                FasterWashingReducedSoap.formatValue(fluidContainer:getAmount()),
                                FasterWashingReducedSoap.formatValue(vanillaAmount),
                                FasterWashingReducedSoap.formatValue(multiplier),
                                FasterWashingReducedSoap.formatValue(amountToConsume)
                            ))
                        else
                            FasterWashingReducedSoap.log("FLUID-CONSUMPTION", string.format(
                                "item=%s fluid is not CleaningLiquid; vanillaPerWash=%s amountBefore=%s",
                                FasterWashingReducedSoap.describeItem(soap),
                                FasterWashingReducedSoap.formatValue(vanillaAmount),
                                FasterWashingReducedSoap.formatValue(fluidContainer:getAmount())
                            ))
                        end

                        local newAmount = fluidContainer:getAmount() - amountToConsume

                        if newAmount <= 0.001 then
                            fluidContainer:Empty()
                        else
                            fluidContainer:adjustAmount(newAmount)
                        end

                        sendItemStats(soap)
                        FasterWashingReducedSoap.log("LIQUID-CONSUMPTION", string.format(
                            "item=%s amountAfter=%s emptied=%s sendItemStats=called",
                            FasterWashingReducedSoap.describeItem(soap),
                            FasterWashingReducedSoap.formatValue(fluidContainer:getAmount()),
                            tostring(newAmount <= 0.001)
                        ))
                        return true
                    end
                    FasterWashingReducedSoap.log("FLUID-CONSUMPTION", string.format(
                        "item=%s fluid container missing or empty; checking next candidate",
                        FasterWashingReducedSoap.describeItem(soap)
                    ))
                elseif instanceof(soap, "DrainableComboItem") then
                    local usesBefore = soap:getCurrentUses()
                    if FasterWashingReducedSoap.updateSoapConsumption then
                        FasterWashingReducedSoap.updateSoapConsumption(soap)
                    end
                    local usesAtConsume = soap:getCurrentUses()
                    if usesAtConsume > 0 then
                        soap:UseAndSync()
                        FasterWashingReducedSoap.log("SOLID-CONSUMPTION", string.format(
                            "item=%s usesBeforeNormalization=%s usesAtConsume=%s usesAfter=%s delta=%s UseAndSync=called",
                            FasterWashingReducedSoap.describeItem(soap),
                            FasterWashingReducedSoap.formatValue(usesBefore),
                            FasterWashingReducedSoap.formatValue(usesAtConsume),
                            FasterWashingReducedSoap.formatValue(soap:getCurrentUses()),
                            FasterWashingReducedSoap.formatValue(soap:getUseDelta())
                        ))
                        return true
                    end

                    FasterWashingReducedSoap.log("SOAP-CANDIDATE", string.format(
                        "item=%s has no usable solid uses after normalization",
                        FasterWashingReducedSoap.describeItem(soap)
                    ))
                else
                    FasterWashingReducedSoap.log("SOAP-CANDIDATE", string.format(
                        "item=%s has no usable fluid or solid uses",
                        FasterWashingReducedSoap.describeItem(soap)
                    ))
                end
            end
        else
            FasterWashingReducedSoap.log("CLOTHING-WASH", "No blood on this target/part; vanilla method would not consume soap.")
            return true
        end

        FasterWashingReducedSoap.log("CLOTHING-WASH", "No usable soap candidate; returning false.")
        return false
    end

    ISWashClothing._RTBC_CleaningLiquidConsumptionPatched = true
    FasterWashingReducedSoap.log("PATCH", string.format(
        "clothing soap-use wrapper installed; liquidMultiplier=%s solidMultiplier=%s",
        FasterWashingReducedSoap.formatValue(getCleaningLiquidConsumptionMultiplier()),
        FasterWashingReducedSoap.formatValue(SandboxVars and SandboxVars.FasterWashingReducedSoap and SandboxVars.FasterWashingReducedSoap.SoapConsumptionMultiplier)
    ))
end

-- Install at game boot on each shared Lua runtime, after sandbox values load.
-- Fluid-container replication continues through vanilla sendItemStats().
Events.OnGameBoot.Add(patchCleaningLiquidConsumption)
