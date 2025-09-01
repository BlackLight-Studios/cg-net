local handler = require("handlers")
local log = require("logger")
local database = require("database")

local function openRednet()
    local sides = {"left", "right", "top", "bottom", "back", "front"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" then
            if not rednet.isOpen(side) then
                rednet.open(side)
                break
            end
        end
    end
end

local config = database.loadConfigJSON()
local parentID = config.parent
local hop = config.hop

if not parentID then
    parentID, hop = handler.getParent()
    database.saveConfigJSON()
end


local queue = {}

function LISTENER()
    while true do
        local id, content, protocol = rednet.receive()
        if protocol and not protocol:match(":nexus$") and not protocol:match(":ping$") then
            if not queue[protocol] then
                queue[protocol] = {}
            end
            table.insert(queue[protocol], {id=id, content=content})
        else
            log.Info("Received protocol "..protocol.." ignoring.")
        end
    end
end

function NEW_NODE()
    while true do
        local messages = queue["$NEW:node"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, content = message.id, message.content
            local sentID, cords = content.id, content.cords
            handler.answerNewNode(id, sentID, cords, hop)
        end
    end
end

function JOIN()
    while true do
        local candidates = {}
        local messages = queue["$JOIN:node"]
            os.sleep(0.1)
            while messages and #messages > 0 do
                local message = table.remove(messages, 1)
                local content = message.content
                table.insert(candidates, {
                    id = message.id,
                    hop = content.hop,
                    distance = content.distance
                })
            end

            if #candidates > 0 then
                parentID, hop = handler.sortCandidates(candidates)

                config.parent = parentID
                config.hop = hop
                config.children = config.children or {}

                database.saveConfigJSON(config)
            end
    end
end

function CHILD()
    while true do
        local messages = queue["$CHILD"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            local childrenIDs = config.children
            handler.answerChild(id, data, childrenIDs, config)
        end
    end
end

function PARENT()
    while true do
        local messages = queue["$PARENT"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            handler.completeConnection(id, data, parentID)
        end
    end
end

-- everyone that answers $JOIN:node will send their hop and ~distance.

function SEND_EMAIL()
    while true do
        local messages = queue["$SEND_EMAIL"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            log.Info("Received email from ".. id)
            handler.emailsRelay(id, data, parentID,config)
        end
    end
end

function RELAY_EMAILS()
    while true do
        local messages = queue["$RELAY_EMAIL"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            log.Info("Received email from ".. id)
            handler.emailsRelay(id, data, parentID,config)
        end
    end
end

function QUERY()
    while true do
        local messages = queue["$QUERY_ALL"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, userEmail = message.id, message.content
            log.Info("Received query from parent.")
            handler.query(id, userEmail, parentID, config)
        end
    end
end

function QUERY_RESPONSE()
    while true do
        local messages = queue["$QUERY:response"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, userEmail = message.id, message.content
            log.Info("Received query response from children with id: "..id)
            handler.queryResponse(id, userEmail, parentID)
        end
    end
end

function PING()
    while true do
        local messages = queue["$IS_ONLINE"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            handler.ping(id, data, parentID, config)
        end
    end
end

function IS_ONLINE_RESPONSE()
    while true do
        local messages = queue["$IS_ONLINE:node"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, data = message.id, message.content
            handler.isOnlineResponse(id, data, parentID, config)
        end
    end
end

function DISCONNECT()
    while true do
        local messages = queue["$DISCONNECT"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, userEmail = message.id, message.content
            log.Info("Received disconnect request from ".. id)
            handler.disconnectUser(id, userEmail, config)
        end
    end
end

function REQUEST_EMAILS()
    while true do
        local messages = queue["$REQUEST_EMAILS:client"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, userEmail = message.id, message.content
            log.Info("Received request for emails from ".. id)
            handler.requestEmails(id, userEmail, parentID)
        end
    end
end

function CONNECT()
    while true do
        local messages = queue["$CONNECT"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, userEmail = message.id, message.content
            log.Info("Received connection request from ".. id)
            handler.newUser(id, userEmail, parentID) 
        end
    end
end


function RELAY_PACKETS()
    while true do
        local messages = queue["$REQUEST_PACKETS:client"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, receivedData = message.id, message.content
            handler.packetsRelay(id, receivedData, parentID)
        end
    end
end

function DISCOVER()
    while true do
        local messages = queue["$DISCOVER"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id = message.id
            handler.discover(id)
        end
    end
end
-- mainly for NovaOS ^^

openRednet()
parallel.waitForAll(LISTENER, NEW_NODE, JOIN, CHILD, PARENT, SEND_EMAIL, RELAY_EMAILS, QUERY, QUERY_RESPONSE, PING, IS_ONLINE_RESPONSE, DISCONNECT, REQUEST_EMAILS, CONNECT, RELAY_PACKETS, DISCOVER)