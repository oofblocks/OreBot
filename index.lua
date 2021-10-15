local discordia = require('discordia')
local client = discordia.Client()

discordia.extensions()

local commands = require('./commands.lua')
local config = require('./config.lua')
local checkData = require('./checkData.lua')

function wait(a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

client:on('ready', function()
	print('Logged in as '.. client.user.username)
    client:setGame{ name = 'in ' .. #client.guilds .. ' servers | ' .. config.prefix .. 'help', type = 3 }
end)

client:on('messageCreate', function(message)

    if author == client.user then return end

    local id = message.author.id

    checkData(id)

	local content = message.content
    local args = content:split(' ')

    local command = nil

    for name, cmd in pairs(commands) do
        if args[1]:lower() == config.prefix .. name then
            command = cmd
            break
        end
        for _, a in pairs(cmd.aliases) do
            if args[1]:lower() == config.prefix .. a then
                command = cmd
                break
            end
        end
    end

    if command then
        command.callback(message, args)
    end

end)

client:run('Bot ' .. config.token)