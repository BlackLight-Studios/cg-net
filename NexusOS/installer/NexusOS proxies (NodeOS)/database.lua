local userIndex = {

}

local log = require("logger")
local database = {}

    database.saveIndexJSON = function()
        local indexPath = ("/var/db/userIndex.json")
        if not fs.exists(indexPath) then
            local file = fs.open(indexPath, "w")
                file.write(textutils.serializeJSON(userIndex))
                file.close()
                log.Warning("userIndex.json created")
        else
            local file = fs.open(indexPath, "w+")
                file.write(textutils.serializeJSON(userIndex))
                file.close()
        end
    end

    database.loadIndexJSON = function()
        local indexPath = ("/var/db/userIndex.json")
        if fs.exists(indexPath) then
            local file = fs.open(indexPath, "r")
            if file then
                local content = file.readAll()
                file.close()
                local data = textutils.unserializeJSON(content)
                if type(data) == "table" then
                    for userEmail, userID in pairs(data) do
                        userIndex[userEmail] = userID
                    end
                end
            end
        end
    end

    database.saveConfigJSON = function(config)
        local jsonPath = ("/etc/config.json")
        if not fs.exists(jsonPath) then
            local file = fs.open(jsonPath, "w")
                file.write(textutils.serializeJSON(config))
                file.close()
                log.Warning("config.json created")
        else
            local file = fs.open(jsonPath, "w+")
                file.write(textutils.serializeJSON(config))
                file.close()
        end
    end

    database.loadConfigJSON = function()
        local config = {parent = nil, children = {}, hop = nil}
        local jsonPath = ("/etc/config.json")
        if fs.exists(jsonPath) then
            local file = fs.open(jsonPath, "r")
            if file then
                local content = file.readAll()
                file.close()
                local data = textutils.unserializeJSON(content)
                if type(data) == "table" then
                    config = {
                        parent = data.parent or nil,
                        children = data.children or {},
                        hop = data.hop or nil
                    }
                    return config
                end
            end
        end
        return config
    end

    database.readIndex = function(userEmail)
        local userID = userIndex[userEmail]
        return userID
    end

    database.connectUser = function(userEmail, userID)
        userIndex[userEmail] = userID
    end

    database.disconnectUser = function(userEmail)
        userIndex[userEmail] = nil
    end

return database
