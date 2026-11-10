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
        print("[Faster Washing & Reduced Soap] ERROR: ISWashClothing.useSoap was not found.")
        return
    end

    if ISWashClothing._RTBC_CleaningLiquidConsumptionPatched then
        return
    end

    ISWashClothing.useSoap = function(self, item, part)
        local blood = 0
        if part then
            blood = item:getBlood(part)
        else
            blood = item:getBloodLevel()
        end

        if blood > 0 then
            for i = 0, self.soaps:size() - 1 do
                local soap = self.soaps:get(i)

                if soap:hasComponent(ComponentType.FluidContainer) then
                    local fluidContainer = soap:getFluidContainer()

                    if fluidContainer and fluidContainer:getAmount() > 0 then
                        local vanillaAmount = ZomboidGlobals.CleanStainCleaningFluidAmount
                        local amountToConsume = vanillaAmount

                        if fluidContainer:contains(Fluid.CleaningLiquid) then
                            amountToConsume = vanillaAmount * getCleaningLiquidConsumptionMultiplier()
                        end

                        local newAmount = fluidContainer:getAmount() - amountToConsume

                        if newAmount <= 0.001 then
                            fluidContainer:Empty()
                        else
                            fluidContainer:adjustAmount(newAmount)
                        end

                        sendItemStats(soap)
                        return true
                    end
                elseif soap:getCurrentUses() > 0 then
                    soap:UseAndSync()
                    return true
                end
            end
        else
            return true
        end

        return false
    end

    ISWashClothing._RTBC_CleaningLiquidConsumptionPatched = true
    print("[Faster Washing & Reduced Soap] Cleaning liquid consumption patch loaded.")
end

Events.OnGameBoot.Add(patchCleaningLiquidConsumption)
