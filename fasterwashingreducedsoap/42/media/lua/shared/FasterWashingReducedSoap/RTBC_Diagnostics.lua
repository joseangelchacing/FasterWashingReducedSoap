FasterWashingReducedSoap = FasterWashingReducedSoap or {}

-- Set this to false to silence this mod's diagnostic output after testing.
FasterWashingReducedSoap.DiagnosticsEnabled = false

local function getRuntimeSide()
    local client = isClient and isClient() or false
    local server = isServer and isServer() or false

    if client and server then return "HOST" end
    if server then return "SERVER" end
    if client then return "CLIENT" end
    return "SINGLEPLAYER/LOCAL"
end

function FasterWashingReducedSoap.log(category, message)
    if not FasterWashingReducedSoap.DiagnosticsEnabled then
        return
    end

    print(string.format(
        "[FWR][%s][%s] %s",
        getRuntimeSide(),
        tostring(category),
        tostring(message)
    ))
end

function FasterWashingReducedSoap.formatValue(value)
    if type(value) == "number" then
        return string.format("%.6f", value)
    end
    return tostring(value)
end

function FasterWashingReducedSoap.describeItem(item)
    if not item then
        return "nil"
    end
    if item.getFullType then
        local fullType = tostring(item:getFullType())
        if item.getID then
            return string.format("%s#%s", fullType, tostring(item:getID()))
        end
        return fullType
    end
    return tostring(item)
end

FasterWashingReducedSoap.log("DIAGNOSTICS", "Verbose mod diagnostics enabled. Set DiagnosticsEnabled=false in RTBC_Diagnostics.lua to silence them.")

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        FasterWashingReducedSoap.log("RUNTIME", string.format(
            "multiplayerRole=%s isClient=%s isServer=%s",
            getRuntimeSide(),
            tostring(isClient and isClient() or false),
            tostring(isServer and isServer() or false)
        ))
    end)
end
