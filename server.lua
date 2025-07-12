local allowedMenuAccess = {
    ["discord:"] = true,
}

local allowedBypass = {
    ["discord:"] = true,
}

local function GetDiscordID(playerId)
    for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.find(id, "discord:") then
            return id
        end
    end
    return nil
end

-- Check permission to access menu
RegisterNetEvent('weaponblacklist:checkPerm', function()
    local src = source
    local discordId = GetDiscordID(src)
    local allowed = discordId and allowedMenuAccess[discordId] or false
    TriggerClientEvent('weaponblacklist:checkPermResponse', src, allowed)
end)

-- Check bypass permission
RegisterNetEvent('weaponblacklist:checkBypass', function()
    local src = source
    local discordId = GetDiscordID(src)
    local allowed = discordId and allowedBypass[discordId] or false
    TriggerClientEvent('weaponblacklist:checkBypassResponse', src, allowed)
end)

-- Get current blacklist from DB and send to client
RegisterNetEvent('weaponblacklist:getBlacklist', function()
    local src = source
    local result = MySQL.query.await('SELECT weapon_name FROM weapon_blacklist')
    local list = {}

    for _, row in ipairs(result) do
        table.insert(list, row.weapon_name)
    end

    TriggerClientEvent('weaponblacklist:sendBlacklist', src, list)
end)

-- Add a weapon to the blacklist table
RegisterNetEvent('weaponblacklist:addWeapon', function(weapon)
    MySQL.prepare('INSERT IGNORE INTO weapon_blacklist (weapon_name) VALUES (?)', { weapon })
end)

-- Remove a weapon from the blacklist table
RegisterNetEvent('weaponblacklist:removeWeapon', function(weapon)
    MySQL.prepare('DELETE FROM weapon_blacklist WHERE weapon_name = ?', { weapon })
end)

-- Print identifiers on player connect (debug)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    print("Player connecting: " .. name .. " (" .. src .. ")")
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        print("  " .. v)
    end
end)
