local json = require('json')

local ores = require('./ores.lua')
local upgrades = require('./upgrades.lua')

local defaultData = {
    Coins = 0;
    Inventory = {};
    IonizedInventory = {};
    SpectralInventory = {};
    Upgrades = {};
    Pickaxes = {};
    Pickaxe = "Stone"
}

for ore, _ in pairs(ores) do
    defaultData.Inventory[ore] = 0
    defaultData.IonizedInventory[ore] = 0
    defaultData.SpectralInventory[ore] = 0
end

for upgrade, _ in pairs(upgrades) do
    defaultData.Upgrades[upgrade] = 0
end

return function(memberId)
    local open = io.open('data.json', 'r')
    local parse = json.parse(open:read())
    open:close()

    local data = parse[memberId]

    if data then
        for k, v in pairs(defaultData) do
            if not data[k] then
                data[k] = v
            end
        end
        for ore, _ in pairs(ores) do
            data.Inventory[ore] = data.Inventory[ore] or 0
            data.IonizedInventory[ore] = data.IonizedInventory[ore] or 0
        end
        
        for upgrade, _ in pairs(upgrades) do
            data.Upgrades[upgrade] = data.Upgrades[upgrade] or 0
        end
    else
        data = defaultData
    end
    parse[memberId] = data

    open = io.open('data.json', 'w')
    open:write(json.stringify(parse))
    open:close()
end