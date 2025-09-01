local handler = require("handlers")
local log = require("logger")
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

rednet.host("NPL","Nexus-Alpha")

local queue = {}

function LISTENER()
    while true do
        local id, content, protocol = rednet.receive()
        if protocol and not protocol:match(":response$") and not protocol:match(":node$") then
            if not queue[protocol] then
                queue[protocol] = {}
            end
            table.insert(queue[protocol], {id=id, content=content})
        else
            log.Info("Received protocol "..protocol.." ignoring.")
        end
    end
end

function RELAY_EMAILS()
    while true do
        local messages = queue["$RELAY_EMAIL"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local id, receivedData = message.id, message.content
            handler.relayEmails(receivedData)
        end
    end
end

function REQUEST_EMAILS()
    while true do
        local messages = queue["$REQUEST_EMAILS:client"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local recNodeID, userEmail = message.id, message.content
            handler.getEmails(userEmail, recNodeID)
        end
    end
end

function REQUEST_PACKETS()
    while true do
        local messages = queue["$REQUEST_PACKETS:client"]
        os.sleep(0.1)
        if messages and #messages > 0 then
            local message = table.remove(messages, 1)
            local recNodeID, receivedData = message.id, message.content
            handler.getPackets(receivedData, recNodeID)
        end
    end
end

openRednet()
parallel.waitForAll(LISTENER, RELAY_EMAILS, REQUEST_EMAILS, REQUEST_PACKETS)
