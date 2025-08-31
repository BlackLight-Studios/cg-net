
local netapi = {}

netapi.defaultNode = nil

netapi.searchModem = function()
    if networkmanager.openRednet() then
        return true
    else
        return false
    end
end

netapi.searchNode = function()
    rednet.broadcast("","$DISCOVER")
    local msg = networkmanager.getMessage("$DISCOVER")
    local answered = {}
    if msg then
        table.insert(answered, msg.ID)
        while msg do
            if msg then
                msg = networkmanager.getMessage("$DISCOVER")
                table.insert(answered, msg.ID)
            end
        end
    end
    return answered
end

netapi.setDefaultNode = function(id)
    netapi.defaultNode = id
end


netapi.send = function(protocol, data, id)
    if id then
        rednet.send(id,data,protocol)
    else 
        if netapi.defaultNode then
            rednet.send(netapi.defaultNode, data, protocol)
        end
    end
    return false
end

netapi.receive = function(protocol)
        local messageTable = networkmanager.getMessage(protocol)
        local id, content = messageTable.ID, messageTable.content
    return id, content
end

return netapi