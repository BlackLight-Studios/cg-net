--[[
 local queue is a dictionary with nested tables:
 local queue = {
    [protocol1] = {{table1}, {table2}, ...}
    [protocol2] = {{table1}, {table2}, ...}
    ...
 }
--]]

--[[
 local queue is a dictionary with nested tables:
 local queue = {
    [protocol1] = {{table1}, {table2}, ...}
    [protocol2] = {{table1}, {table2}, ...}
    ...
 }
--]]


local networkmanager = {}

local queue = {}
local defaultNode = nil

networkmanager.openRednet = function()
    local sides = {"left", "right", "top", "bottom", "back", "front"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" then
            if not rednet.isOpen(side) then
                rednet.open(side)
                return true
            else
                return nil
            end
        end
    end
end

networkmanager.listener = function()
    local queuePath = "/sys/networking/.queue.json"
    local file = nil
    if not fs.exists(queuePath) then
        file = fs.open(queuePath, "w")
        file.write(textutils.serialiseJSON(queue))
        file.close()
    else
        file = fs.open(queuePath, "r")
        queue = textutils.unserialiseJSON(file.readAll())
        file.close()
    end
    while true do
        local id, content, protocol = rednet.receive()
        if protocol and protocol:match("^%$") then
            if protocol ~= "$PING" then
                if not queue[protocol] then
                    queue[protocol] = {}
                end
                table.insert(queue[protocol], {ID=id, content=content})
                file = fs.open(queuePath, "w+")
                file.write(textutils.serialiseJSON(queue))
                file.close()
            else
                if content == "Knock... Knock!" then
                    rednet.send(id, "Who's there?", "$PING:ping")
                end
            end
        end
    end
end

networkmanager.getMessage = function(protocol)
    local queuePath = "/sys/networking/.queue.json"
    local file = fs.open(queuePath, "r")
    local queue = textutils.unserialiseJSON(file.readAll())
    file.close()
    local msgs = queue[protocol]
    if msgs and #msgs > 0 then
        local msg = table.remove(msgs, 1)
        file = fs.open(queuePath, "w+")
        file.write(textutils.serialiseJSON(queue))
        file.close()
        return msg
    end
    return nil
end

networkmanager.searchModem = function()
    local rednet = networkmanager.openRednet()
    if rednet then
        return true
    else
        return false
    end
end

networkmanager.searchNode = function(timeout)
    timeout = timeout or 3
    timeout = timeout * 1000
    rednet.broadcast("", "$DISCOVER")
    local start = os.epoch("local")
    local nodes = {}
    while os.epoch("local") - start < timeout do
        local msg = networkmanager.getMessage("$DISCOVER")
        if msg then
            table.insert(nodes, msg.ID)
        end
        sleep(0.05)
    end
    return nodes
end

networkmanager.getInbox = function()
    local emails = {}
    local msg = networkmanager.getMessage("$RELAY_EMAIL")
    while msg do
        if msg then
            table.insert(emails, msg.content)
        end
        msg = networkmanager.getMessage("$RELAY_EMAIL")
        sleep(0.05)
    end
    return emails
end

networkmanager.repo = function(timeout)
    timeout = timeout or 3
    timeout = timeout * 1000
    local start = os.epoch("local")
    local msgJSON
    local msg
    print("Getting packages...")
    while os.epoch("local") - start < timeout do
        msgJSON = networkmanager.getMessage("$REQUEST_PACKETS:nexus")
        if msgJSON then
            msg = textutils.unserialiseJSON(msgJSON.content)
        end
        sleep(0.05)
    end
    return msg
end

networkmanager.setDefaultNode = function(id)
    local defaultNodePath = "/sys/networking/.defaultNode.json"
    if not fs.exists(defaultNodePath) then
        local file = fs.open(defaultNodePath, "w")
        file.write(textutils.serialiseJSON(id))
        file.close()
    else
        local file = fs.open(defaultNodePath, "w+")
        file.write(textutils.serialiseJSON(id))
        file.close()
    end
end

networkmanager.send = function(protocol, data, id)
    local defaultNodePath = "/sys/networking/.defaultNode.json"
    local defaultNode = nil
    if fs.exists(defaultNodePath) then
        local file = fs.open(defaultNodePath, "r")
        defaultNode = textutils.unserialiseJSON(file.readAll())
        file.close()
    end
    if id then
        return rednet.send(id,data,protocol)
    else 
        if defaultNode then
            return rednet.send(defaultNode, data, protocol)
        end
    end
end

networkmanager.requestEmails = function(email,timeout)
    timeout = timeout or 3
    timeout = timeout * 1000
    local start = os.epoch("local")
    networkmanager.send("$REQUEST_EMAILS:client", email)
    local emails = {}
    while os.epoch("local") - start < timeout do
        local msgJSON = networkmanager.getMessage("$REQUEST_EMAILS:nexus")
        if msgJSON then
            local msg = textutils.unserialiseJSON(msgJSON.content)
            local emailList = msg
            for _, email in ipairs(emailList) do
                table.insert(emails, email)
            end
        end
        sleep(0.05)
    end
    return emails
end

networkmanager.receive = function(protocol, timeout)
    timeout = timeout or 3
    timeout = timeout * 1000
    local start = os.epoch("local")
    local msgs = {}
    while os.epoch("local") - start < timeout do
        local msg = networkmanager.getMessage(protocol)
        if msg then
                table.insert(msgs, msg.content)
        end
        sleep(0.05)
    end
    return msgs
end

return networkmanager