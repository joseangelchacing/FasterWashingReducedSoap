require "FasterWashingReducedSoap/RTBC_Diagnostics"
require "TimedActions/ISWashClothing"
require "TimedActions/ISWashYourself"

FasterWashingReducedSoap = FasterWashingReducedSoap or {}

local DEFAULT_SOAP_MULTIPLIER = 0.02
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

-- Base.Soap2 has UseDelta = 0.05 in the target vanilla item script.
-- Scale that real vanilla value so 0.02 means 2% of normal consumption.
local VANILLA_SOAP_USE_DELTA = 0.05

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

    if math.abs(currentUseDelta - newUseDelta) >= 0.0000001
        or math.abs(previousUseDelta - newUseDelta) >= 0.0000001 then
        FasterWashingReducedSoap.log("SOAP-DELTA", string.format(
            "item=%s currentDelta=%s savedPreviousDelta=%s targetDelta=%s currentUses=%s preservedAmount=%s",
            FasterWashingReducedSoap.describeItem(soap),
            FasterWashingReducedSoap.formatValue(currentUseDelta),
            FasterWashingReducedSoap.formatValue(previousUseDelta),
            FasterWashingReducedSoap.formatValue(newUseDelta),
            FasterWashingReducedSoap.formatValue(soap:getCurrentUses()),
            FasterWashingReducedSoap.formatValue(remaining)
        ))
    end

    if math.abs(currentUseDelta - newUseDelta) < 0.0000001
        and math.abs(previousUseDelta - newUseDelta) < 0.0000001 then
        modData.RTBC_SoapUseDelta = newUseDelta
        return
    end

    soap:setUseDelta(newUseDelta)
    soap:setCurrentUsesFloat(remaining)

    modData.RTBC_SoapUseDelta = newUseDelta
    FasterWashingReducedSoap.log("SOAP-DELTA", string.format(
        "item=%s appliedDelta=%s resultingUses=%s resultingUsesFloat=%s modDataMarker=%s",
        FasterWashingReducedSoap.describeItem(soap),
        FasterWashingReducedSoap.formatValue(soap:getUseDelta()),
        FasterWashingReducedSoap.formatValue(soap:getCurrentUses()),
        FasterWashingReducedSoap.formatValue(soap:getCurrentUsesFloat()),
        FasterWashingReducedSoap.formatValue(modData.RTBC_SoapUseDelta)
    ))
end

-- Shared with the useSoap patch so normalization also occurs immediately
-- before a solid soap bar is consumed, on whichever side executes the action.
FasterWashingReducedSoap.updateSoapConsumption = updateSoapConsumption

-- Normalize an adjusted soap bar only when the game presents it to the player
-- or is about to consume it. Vanilla can reconstruct UseDelta from the item
-- script after a transfer, while this marker preserves the adjusted amount.
local function normalizeSoapItem(soap, player, trigger)
    if not soap or not instanceof(soap, "DrainableComboItem")
        or soap:getFullType() ~= "Base.Soap2" then
        return false
    end

    local previousDelta = soap:getUseDelta()
    local previousUses = soap:getCurrentUses()
    local previousMarker = soap:getModData().RTBC_SoapUseDelta

    updateSoapConsumption(soap)

    local fieldsChanged = math.abs(previousDelta - soap:getUseDelta()) >= 0.0000001
        or previousUses ~= soap:getCurrentUses()
    local markerChanged = previousMarker ~= soap:getModData().RTBC_SoapUseDelta

    if fieldsChanged and type(sendItemStats) == "function" then
        sendItemStats(soap)
    end

    -- sendItemStats synchronizes item fields; modData uses its own vanilla
    -- synchronization path. This is especially relevant when a client opens
    -- a loot container and repairs an item before taking it.
    local modDataSync = "not-needed"
    if markerChanged and player and isClient and isClient()
        and type(syncItemModData) == "function" then
        local ok, err = pcall(syncItemModData, player, soap)
        modDataSync = ok and "called" or ("failed: " .. tostring(err))
    elseif markerChanged then
        modDataSync = "unavailable-or-not-client"
    end

    if fieldsChanged or markerChanged then
        FasterWashingReducedSoap.log("SOAP-LOAD", string.format(
            "item=%s trigger=%s delta=%s->%s uses=%s->%s fieldsChanged=%s markerChanged=%s syncItemModData=%s",
            FasterWashingReducedSoap.describeItem(soap),
            tostring(trigger),
            FasterWashingReducedSoap.formatValue(previousDelta),
            FasterWashingReducedSoap.formatValue(soap:getUseDelta()),
            FasterWashingReducedSoap.formatValue(previousUses),
            FasterWashingReducedSoap.formatValue(soap:getCurrentUses()),
            tostring(fieldsChanged), tostring(markerChanged), modDataSync
        ))
    end

    return fieldsChanged or markerChanged
end

local function normalizePlayerSoapInventory(player, trigger)
    if not player or not player.getInventory then return false end

    local inventory = player:getInventory()
    if not inventory or not inventory.getSoapList then return false end

    local soaps = inventory:getSoapList(nil, true)
    if not soaps or not soaps.size then return false end

    local normalizedCount = 0
    for i = 0, soaps:size() - 1 do
        if normalizeSoapItem(soaps:get(i), player, trigger) then
            normalizedCount = normalizedCount + 1
        end
    end

    FasterWashingReducedSoap.log("SOAP-LOAD", string.format(
        "player=%s trigger=%s normalizedItems=%d soapCandidates=%d",
        player.getUsername and tostring(player:getUsername()) or tostring(player),
        tostring(trigger), normalizedCount, soaps:size()
    ))
    return true
end

local function normalizeVisibleContainerSoap(inventoryPane, trigger)
    if not inventoryPane or not inventoryPane.inventory then return 0 end

    local containerItems = inventoryPane.inventory:getItems()
    if not containerItems then return 0 end

    local player = getSpecificPlayer and getSpecificPlayer(inventoryPane.player) or nil
    local normalizedCount = 0
    for i = 0, containerItems:size() - 1 do
        if normalizeSoapItem(containerItems:get(i), player, trigger) then
            normalizedCount = normalizedCount + 1
        end
    end

    if normalizedCount > 0 then
        FasterWashingReducedSoap.log("SOAP-LOAD", string.format(
            "trigger=%s visibleContainer=%s normalizedItems=%d",
            tostring(trigger), tostring(inventoryPane.inventory:getType()), normalizedCount
        ))
    end
    return normalizedCount
end

-- OnCreatePlayer is a client event and fires when the local player enters the
-- world. This corrects the local inventory UI immediately after reconnect.
if Events and Events.OnCreatePlayer then
    Events.OnCreatePlayer.Add(function(_, player)
        normalizePlayerSoapInventory(player, "OnCreatePlayer")
    end)
end

-- Inventory and loot panes call refreshContainer() when their visible item
-- list is rebuilt. This covers the main inventory, bags, nearby containers,
-- cabinets and the floor pane without scanning inventories every game tick.
if Events and Events.OnRefreshInventoryWindowContainers then
    Events.OnRefreshInventoryWindowContainers.Add(function(page, reason)
        if not isClient or not isClient() or reason ~= "end" or not page then
            return
        end

        local normalizedCount = normalizeVisibleContainerSoap(page.inventoryPane, "InventoryUI")
        if normalizedCount > 0 then
            FasterWashingReducedSoap.log("SOAP-LOAD", string.format(
                "page=%s reason=%s totalNormalized=%d",
                tostring(page.onCharacter and "player" or "loot"), tostring(reason), normalizedCount
            ))
        end
    end)
end

-- Inventory transfers can replace the client-side item state after the pane
-- refresh callback. Normalize once more when the vanilla transfer action ends.
-- ISInventoryTransferAction is client-only, so load and patch it only on clients.
local function patchSoapInventoryTransfer()
    if not isClient or not isClient() then return end

    local ok, transferModule = pcall(require, "TimedActions/ISInventoryTransferAction")
    if not ok or not ISInventoryTransferAction
        or type(ISInventoryTransferAction.perform) ~= "function" then
        FasterWashingReducedSoap.log("ERROR", "Could not hook ISInventoryTransferAction.perform for soap transfer normalization.")
        return
    end

    if ISInventoryTransferAction._RTBC_SoapTransferPatched then
        FasterWashingReducedSoap.log("PATCH", "Soap transfer normalization already installed; skipping duplicate.")
        return
    end

    local originalPerform = ISInventoryTransferAction.perform
    ISInventoryTransferAction.perform = function(self, ...)
        local result = originalPerform(self, ...)
        local player = self.character
        local items = self.items
        local normalizedCount = 0

        if self.item then
            if normalizeSoapItem(self.item, player, "TransferComplete") then
                normalizedCount = normalizedCount + 1
            end
        elseif items then
            for _, item in ipairs(items) do
                if normalizeSoapItem(item, player, "TransferComplete") then
                    normalizedCount = normalizedCount + 1
                end
            end
        end

        FasterWashingReducedSoap.log("SOAP-TRANSFER", string.format(
            "destination=%s normalizedItems=%d item=%s",
            self.destContainer and tostring(self.destContainer:getType()) or "unknown",
            normalizedCount,
            FasterWashingReducedSoap.describeItem(self.item)
        ))
        return result
    end

    ISInventoryTransferAction._RTBC_SoapTransferPatched = true
    FasterWashingReducedSoap.log("PATCH", "Soap transfer-completion normalization installed.")
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(patchSoapInventoryTransfer)
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
            local uses = soap:getCurrentUses()
            total = total + uses
            FasterWashingReducedSoap.log("SOAP-ESTIMATE", string.format(
                "solid item=%s uses=%s delta=%s",
                FasterWashingReducedSoap.describeItem(soap),
                FasterWashingReducedSoap.formatValue(uses),
                FasterWashingReducedSoap.formatValue(soap:getUseDelta())
            ))
        elseif soap then
            local fluidContainer = soap:getFluidContainer()

            if fluidContainer and fluidContainer:contains(Fluid.CleaningLiquid) then
                local vanillaAmount = ZomboidGlobals.CleanStainCleaningFluidAmount
                local multiplier = getCleaningLiquidConsumptionMultiplier()
                local amountPerWash = vanillaAmount * multiplier

                if type(amountPerWash) == "number" and amountPerWash > 0 then
                    local estimatedUses = fluidContainer:getAmount() / amountPerWash
                    total = total + estimatedUses
                    FasterWashingReducedSoap.log("SOAP-ESTIMATE", string.format(
                        "liquid item=%s amount=%s vanillaPerWash=%s multiplier=%s modPerWash=%s estimatedUses=%s",
                        FasterWashingReducedSoap.describeItem(soap),
                        FasterWashingReducedSoap.formatValue(fluidContainer:getAmount()),
                        FasterWashingReducedSoap.formatValue(vanillaAmount),
                        FasterWashingReducedSoap.formatValue(multiplier),
                        FasterWashingReducedSoap.formatValue(amountPerWash),
                        FasterWashingReducedSoap.formatValue(estimatedUses)
                    ))
                end
            else
                FasterWashingReducedSoap.log("SOAP-ESTIMATE", string.format(
                    "ignored item=%s (not solid soap or CleaningLiquid)",
                    FasterWashingReducedSoap.describeItem(soap)
                ))
            end
        end
    end

    FasterWashingReducedSoap.log("SOAP-ESTIMATE", string.format(
        "totalEstimatedWashes=%s solidMultiplier=%s liquidMultiplier=%s",
        FasterWashingReducedSoap.formatValue(total),
        FasterWashingReducedSoap.formatValue(getSoapConsumptionMultiplier()),
        FasterWashingReducedSoap.formatValue(getCleaningLiquidConsumptionMultiplier())
    ))
    return total
end

local function patchSoapConsumption()
    if not ISWashClothing or not ISWashClothing.GetSoapRemaining then
        FasterWashingReducedSoap.log("ERROR", "ISWashClothing.GetSoapRemaining was not found.")
        return
    end

    if ISWashClothing._RTBC_SoapConsumptionPatched then
        FasterWashingReducedSoap.log("PATCH", "Soap availability patch already installed; skipping duplicate.")
        return
    end

    ISWashClothing.GetSoapRemaining = getSoapRemainingWithAdjustedLiquid

    ISWashClothing._RTBC_SoapConsumptionPatched = true
    local solidMultiplier = getSoapConsumptionMultiplier()
    local targetUseDelta = VANILLA_SOAP_USE_DELTA * solidMultiplier
    FasterWashingReducedSoap.log("SOAP-CONFIG", string.format(
        "Base.Soap2 vanillaUseDelta=%s sandboxMultiplier=%s targetUseDelta=%s expectedDurability=%s times vanilla; liquidMultiplier=%s",
        FasterWashingReducedSoap.formatValue(VANILLA_SOAP_USE_DELTA),
        FasterWashingReducedSoap.formatValue(solidMultiplier),
        FasterWashingReducedSoap.formatValue(targetUseDelta),
        FasterWashingReducedSoap.formatValue(1 / solidMultiplier),
        FasterWashingReducedSoap.formatValue(getCleaningLiquidConsumptionMultiplier())
    ))
    FasterWashingReducedSoap.log("PATCH", string.format(
        "soap availability patch installed; solidMultiplier=%s liquidMultiplier=%s",
        FasterWashingReducedSoap.formatValue(solidMultiplier),
        FasterWashingReducedSoap.formatValue(getCleaningLiquidConsumptionMultiplier())
    ))
end

local function patchPersonalWashSoapLoggingAndConsumption()
    if not ISWashYourself or type(ISWashYourself.washPart) ~= "function" then
        FasterWashingReducedSoap.log("ERROR", "ISWashYourself.washPart was not found.")
        return
    end

    if ISWashYourself._RTBC_SelfSoapConsumptionPatched then
        FasterWashingReducedSoap.log("PATCH", "Personal-wash soap patch already installed; skipping duplicate.")
        return
    end

    local originalWashPart = ISWashYourself.washPart
    ISWashYourself.washPart = function(self, visual, part)
        local blood = visual:getBlood(part)
        local dirt = visual:getDirt(part)
        local selectedSoap
        local usesBefore

        if blood > 0 and self.soaps then
            for i = 0, self.soaps:size() - 1 do
                local soap = self.soaps:get(i)
                if instanceof(soap, "DrainableComboItem") then
                    updateSoapConsumption(soap)
                    if soap:getCurrentUses() > 0 then
                        selectedSoap = soap
                        usesBefore = soap:getCurrentUses()
                        break
                    end
                end
            end
        end

        local result = originalWashPart(self, visual, part)

        if blood > 0 then
            if selectedSoap then
                FasterWashingReducedSoap.log("PERSONAL-WASH-SOAP", string.format(
                    "part=%s result=%s soap=%s bloodBefore=%s dirtBefore=%s usesBefore=%s usesAfter=%s delta=%s UseAndSync=vanilla-called",
                    tostring(part),
                    tostring(result),
                    FasterWashingReducedSoap.describeItem(selectedSoap),
                    FasterWashingReducedSoap.formatValue(blood),
                    FasterWashingReducedSoap.formatValue(dirt),
                    FasterWashingReducedSoap.formatValue(usesBefore),
                    FasterWashingReducedSoap.formatValue(selectedSoap:getCurrentUses()),
                    FasterWashingReducedSoap.formatValue(selectedSoap:getUseDelta())
                ))
            else
                FasterWashingReducedSoap.log("PERSONAL-WASH-SOAP", string.format(
                    "part=%s result=%s bloodBefore=%s dirtBefore=%s no usable solid soap; vanilla action ran",
                    tostring(part),
                    tostring(result),
                    FasterWashingReducedSoap.formatValue(blood),
                    FasterWashingReducedSoap.formatValue(dirt)
                ))
            end
        elseif dirt > 0 then
            FasterWashingReducedSoap.log("PERSONAL-WASH", string.format(
                "part=%s result=%s bloodBefore=%s dirtBefore=%s soapConsumption=not-required (vanilla uses soap for blood only)",
                tostring(part),
                tostring(result),
                FasterWashingReducedSoap.formatValue(blood),
                FasterWashingReducedSoap.formatValue(dirt)
            ))
        elseif result then
            FasterWashingReducedSoap.log("PERSONAL-WASH", string.format(
                "part=%s result=true bloodBefore=%s dirtBefore=%s soapConsumption=not-required",
                tostring(part),
                FasterWashingReducedSoap.formatValue(blood),
                FasterWashingReducedSoap.formatValue(dirt)
            ))
        end

        return result
    end

    ISWashYourself._RTBC_SelfSoapConsumptionPatched = true
    FasterWashingReducedSoap.log("PATCH", "Personal-wash solid-soap instrumentation and normalization installed.")
end

-- Install at game boot on each shared Lua runtime, after sandbox values load.
-- The client and server each wrap their local vanilla class; item replication
-- continues through the vanilla UseAndSync/sendItemStats paths.
Events.OnGameBoot.Add(patchSoapConsumption)
Events.OnGameBoot.Add(patchPersonalWashSoapLoggingAndConsumption)
