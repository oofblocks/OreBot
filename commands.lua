local prefix = require('./config.lua').prefix
local json = require('json')
local upgrades = require('./upgrades.lua')
local ores = require('./ores.lua')
local textures = require('./textures.lua')
local discordia = require('discordia')

return {

    ['mine'] = {
        aliases = {'m'};
        callback = function(message, args)
            local memberId = message.author.id

            local open = io.open('data.json', 'r')
            local parse = json.parse(open:read())
            open:close()

            local miningLevel = parse[memberId]['Upgrades']['Mining']
            local pickaxe = parse[memberId]['Pickaxe']

            local result = {}
            local lottery = {}

            for ore, data in pairs(ores) do
                if miningLevel >= data.MinLevel then
                    table.insert(lottery, ore)
                end
            end

            for _, ore in pairs(lottery) do
                local altType = nil
                if math.random(1, ores[ore]['Rarity']*5) == 1 and not ores[ore]["NoAlter"] then
                    altType = "Ionized"
                elseif math.random(1, ores[ore]['Rarity']*25) == 1 and not ores[ore]["NoAlter"] then
                    altType = "Spectral"
                end

                local amount = math.floor(2 + miningLevel * ores[ore]['Rarity'] * math.random(2, 7)/1000)

                if amount > 0 then
                    table.insert(result, {
                        Ore = ore;
                        Amount = amount;
                        AltType = nil
                    })
                end
                if altType then
                    table.insert(result, {
                        Ore = ore;
                        Amount = 1 + math.floor(amount / math.random(75,250));
                        AltType = altType
                     })
                 end
            end

            local oresMined = 0
            local string = ""

            for i, v in pairs(result) do
                oresMined = oresMined + v.Amount
                local icons = ""
                if v.AltType then
                    icons = icons .. "<:" .. v.AltType .. ":" .. textures[v.AltType] .. ">"
                end
                icons = icons .. "<:" .. v.Ore .. ":" .. textures[v.Ore] .. ">"
                string = string .. icons .. " | " .. (v.AltType and v.AltType .. " " or "") .. v.Ore .. ": " .. v.Amount .. "\n"
                if v.AltType then
                    parse[memberId][v.AltType .. "Inventory"][v.Ore] = parse[memberId][v.AltType .. "Inventory"][v.Ore] + v.Amount
                else
                    parse[memberId]["Inventory"][v.Ore] = parse[memberId]["Inventory"][v.Ore] + v.Amount
                end
            end

            message:reply{
                embed = {
                   fields = {  
                     {name = message.author.name .. "'s Mining Session"; value = string}  
                   };
                   thumbnail = {
                    url = message.author.avatarURL
                   };
                   footer = {
                       text = tostring(oresMined) ..  " ores found"
                   };
                   color = discordia.Color.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)).value
                }
            }

            open = io.open("data.json", "w")
            open:write(json.stringify(parse))
            open:close()

        end
    };

    ['upgrade'] = {
        aliases = {'upg', 'up', 'u'};
        callback = function(message, args)
            local memberId = message.author.id

            local open = io.open('data.json', 'r')
            local parse = json.parse(open:read())
            open:close()

            if #args == 1 then
                local fields = {}
                for upgrade, level in pairs(parse[memberId]["Upgrades"]) do
                    table.insert(fields, {name = upgrade, value = "Level " ..  tostring(level), inline = true})
                end
                return message:reply{
                    embed = {
                        fields = fields;
                        footer = {
                            text = "To find the cost of an upgrade, use " .. prefix .. "level [upgrade]!"
                        };
                        color = discordia.Color.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)).value
                    }
                }
            else
                local upg = string.lower(args[2]):gsub("^%l", string.upper)
                if upg and upgrades[upg] then
                    local level = parse[memberId]["Upgrades"][upg]
                    if level == #upgrades[upg] then
                        return message:reply("You are at the max level!")
                    end
                    local cost = upgrades[upg][level + 1]
                    local score = 0
                    for ore, count in pairs(parse[memberId]["Inventory"]) do
                        if cost[ore] and count >= cost[ore] then
                            score = score + 1
                        end
                    end

                    local luaIsDumb = 0
                    for _, _ in pairs(cost) do
                        luaIsDumb = luaIsDumb + 1
                    end

                    if score == luaIsDumb then
                        parse[memberId]["Upgrades"][upg] =  parse[memberId]["Upgrades"][upg] + 1
                        for ore, count in pairs(cost) do
                            parse[memberId]["Inventory"][ore] = parse[memberId]["Inventory"][ore] - count
                        end
                        open = io.open("data.json", "w")
                        open:write(json.stringify(parse))
                        open:close()            
                        return message:reply{
                            embed = {
                                fields = {
                                    {name = "Successfully upgraded your " .. upg .. " level!", value = "Your " .. upg .. " level is now level " .. tostring(level + 1) .. "!"}
                                };
                                color = discordia.Color.fromRGB(0,255,0).value
                            };
                        }      
                    end
                    return message:reply("You cannot afford this!")
                end
            end
        end
    };

    ['level'] = {
        aliases = {'lvl', 'l'};
        callback = function(message, args)
            if #args == 2 then
                local memberId = message.author.id

                local open = io.open('data.json', 'r')
                local parse = json.parse(open:read())
                open:close()

                local upg = string.lower(args[2]):gsub("^%l", string.upper)
                if upg and upgrades[upg] then
                    local level = parse[memberId]["Upgrades"][upg]
                    local cost = upgrades[upg][level + 1]
                    
                    local string = ""

                    if cost then
                        for ore, amount in pairs(cost) do
                            string = string .. "<:" .. ore .. ":" .. textures[ore] .. "> | " .. ore .. " (" .. parse[memberId]["Inventory"][ore] .. "/" .. cost[ore] .. ")\n"
                        end
                    else
                        string = "You are at the maximum level!"
                    end

                    return message:reply{
                            embed = {
                                fields = {
                                    {
                                        name = "Your " .. upg .. " level is currently at level " .. tostring(level);
                                        value = string
                                    }
                                };
                                thumbnail = {
                                    url = message.author.avatarURL
                                };
                            }
                        }
                 end
            end
            return message:reply("Invalid upgrade!")
        end
    };

    ['inventory'] = {
        aliases = {'inv', 'i'};
        callback = function(message, args)
            local memberId = message.author.id

            local open = io.open('data.json', 'r')
            local parse = json.parse(open:read())
            open:close()

            local type = (args[2] and string.lower(args[2]):gsub("^%l", string.upper) or "")
            local inventory = parse[memberid][type .. "Inventory"]
            if not inventory then
                inventory = parse[memberid]["Inventory"]
            end
            
            function shallowCopy(table)
                local t = {}
                for k, v in pairs(table) do
                    t[k] = v
                end
                return t
            end
            local inventoryCopy = shallowCopy(inventory)
            
            table.sort(inventoryCopy, function(a, b)
                return a:byte() < b:byte()
            end)

            local pages = {{}}
            local currentPage = 1

            local count = 0
            for ore, amount in pairs(inventoryCopy) do
                if amount > 0 then
                    count = count + 1
                    if count > 2 then
                        currentPage = currentPage + 1
                        table.insert(pages, currentPage, {})
                        count = 0
                    end
                    table.insert(pages[currentPage], {Ore = ore; Amount = amount})
                end
            end
            
            local page = 1

            function getString()
                local string = ""
                for _, data in pairs(pages[page]) do
                    string = string .. "<:" .. data.Ore .. ":" .. textures[data.Ore] .. "> | " .. data.Ore .. ": " .. data.Amount .. "\n"
                end
                if string == "" then
                    string = "You have no ores!"
                end
                return string
            end

            local typeStr = " "
            if type ~= "" then
                typeStr = " " .. type .. " "
            end

            local inventory = message:reply{
                embed = {
                    fields = {
                        {name = message.author.name .. "'s" .. typeStr .. "Inventory"; value = getString()}
                    };
                    thumbnail = {
                        url = message.author.avatarURL
                    };
                    footer = {
                        text = "Showing page " .. tostring(page) .. " of " .. tostring(#pages)
                    };
                    color = discordia.Color.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)).value
                }
            }

            inventory:addReaction("\226\172\133\239\184\143")
            inventory:addReaction("\226\158\161\239\184\143")

            client:on('reactionAdd', function(reaction, userid)
                if userid == client.user.id then return end
                local x = page

                print(reaction.emojiHash)

                if reaction.message.id == inventory.message.id and userid == memberId then
                    if reaction.emojiHash == "\226\172\133\239\184\143" then
                        if page > 1 then
                            page = page - 1
                        end
                    elseif reaction.emojiHash == "\226\158\161\239\184\143" then
                        if page < #pages then
                            page = page + 1
                        end
                    end
                end
                if page ~= x then
                    inventory:setEmbed{
                        fields = {
                            {name = message.author.name .. "'s" .. typeStr .. "Inventory"; value = getString()}
                        };
                        thumbnail = {
                            url = message.author.avatarURL
                        };
                        footer = {
                            text = "Showing page " .. tostring(page) .. " of " .. tostring(#pages)
                        };
                        color = discordia.Color.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)).value
                    }
                end
            end)         
        end
    }
}
