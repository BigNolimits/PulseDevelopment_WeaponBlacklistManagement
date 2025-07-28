print("[WeaponBlacklist] client.lua loaded")

local currentBlacklist = {}

-- Request current blacklist from server
local function loadBlacklist()
    local p = promise.new()
    RegisterNetEvent('weaponblacklist:sendBlacklist', function(list)
        currentBlacklist = list
        p:resolve(true)
    end)
    TriggerServerEvent('weaponblacklist:getBlacklist')
    Citizen.Await(p)
end

local function isWeaponBlacklisted(weaponHash)
    for _, blacklistedName in pairs(currentBlacklist) do
        if weaponHash == GetHashKey(blacklistedName) then
            return true
        end
    end
    return false
end

local function notify(msg, type)
    if Config.UseOXLib then
        exports.ox_lib:notify({
            title = 'Weapon Blacklist',
            description = tostring(msg),
            type = type or 'inform',
            duration = 5000
        })
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(tostring(msg))
        DrawNotification(false, true)
    end
end

local function TriggerServerCallback(name)
    local p = promise.new()
    local eventResponse = name .. 'Response'

    local handler
    handler = RegisterNetEvent(eventResponse, function(result)
        RemoveEventHandler(handler)
        p:resolve(result)
    end)

    TriggerServerEvent(name)
    return Citizen.Await(p)
end

local function isBypass()
    return TriggerServerCallback('weaponblacklist:checkBypass')
end

local function hasMenuPermission()
    return TriggerServerCallback('weaponblacklist:checkPerm')
end

local function openAdminMenu()
    local input = exports.ox_lib:inputDialog('Weapon Blacklist Menu', {
        {type = 'input', label = 'Add Weapon (e.g. WEAPON_RPG)', required = false},
        {type = 'input', label = 'Remove Weapon (e.g. WEAPON_RPG)', required = false}
    })

    if input then
        local toAdd = input[1]
        local toRemove = input[2]

        if toAdd and toAdd ~= '' then
            TriggerServerEvent('weaponblacklist:addWeapon', toAdd:upper())
            notify(toAdd:upper() .. ' added to blacklist.', 'success')
        end

        if toRemove and toRemove ~= '' then
            TriggerServerEvent('weaponblacklist:removeWeapon', toRemove:upper())
            notify(toRemove:upper() .. ' removed from blacklist.', 'success')
        end

        Wait(500)
        loadBlacklist() -- Refresh local list
    end
end

RegisterCommand("weaponmenu", function()
    CreateThread(function()
        local allowed = hasMenuPermission()
        if not allowed then
            notify("You don't have permission to open this menu.", "error")
            return
        end
        openAdminMenu()
    end)
end)

-- Load blacklist from DB on start
CreateThread(function()
    loadBlacklist()
end)

-- Blacklist enforcement loop
CreateThread(function()
    while true do
        Wait(Config.CheckInterval or 1000)

        if isBypass() then goto continue end

        local player = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(player)

        if isWeaponBlacklisted(currentWeapon) then
            RemoveWeaponFromPed(player, currentWeapon)
            notify("You are not allowed to use this weapon.", "error")
            Wait(1000)
        end

        ::continue::
    end
end)
