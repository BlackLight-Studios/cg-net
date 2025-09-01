local database = require("database")
local log = require("logger")
local handler = {}

--how much each handler that contains an os.sleep (so those that wait for an answer)
local generalWaitTime = 6

    handler.packetsRelay = function(id, data, parentID)
        if id ~= parentID then
            rednet.send(parentID, data, "$REQUEST_PACKETS:client")
            log.Info("Relaying packet from ".. id.. " to parent ID ".. parentID)
            local senderID, receivedData = rednet.receive("$REQUEST_PACKETS:nexus",generalWaitTime)
                if senderID == parentID then
                    log.Info("Received response from ".. parentID.." and relaying it back to sender.")
                    rednet.send(id, receivedData, "$REQUEST_PACKETS:nexus")
                end
        end
    end

    handler.emailsRelay = function(id, data, parentID,config)
        if id == parentID then
            database.loadIndexJSON()
            local destUser = data.dest
            local destID = database.readIndex(destUser)
            if destID == nil then
                if config and config.children then
                    for _, childID in ipairs(config.children) do
                        rednet.send(childID, data, "$RELAY_EMAIL")
                        log.Info("Email relayed to child ID: "..childID)
                    end
                end
            else
                rednet.send(destID, data, "$RELAY_EMAIL")
                log.Info("Email relayed to user ID: "..destID)
            end
        elseif id ~= parentID then
            rednet.send(parentID, data, "$RELAY_EMAIL")
            log.Info("Email relayed to parent ID: "..parentID)
        end
    end

    handler.requestEmails = function(id, userEmail, parentID)
        rednet.send(parentID, userEmail, "$REQUEST_EMAILS:client")
        log.Info("Requesting emails to parent ID: "..parentID)
        local senderID, receivedData = rednet.receive("$REQUEST_EMAILS:nexus",generalWaitTime)
            if senderID == parentID then
                log.Info("Relaying emails back to sender ID: "..id)
                rednet.send(id, receivedData, "$REQUEST_EMAILS:nexus")
            end
    end

    handler.newUser = function(id, userEmail, parentID)
        database.loadIndexJSON()
        database.connectUser(userEmail, id)
        log.Info("Added new user: "..userEmail.." with ID: "..id.." to index and requesting emails")
        handler.requestEmails(id, userEmail, parentID)
        database.saveIndexJSON()
    end

    handler.disconnectUser = function(id, userEmail, config)
        database.loadIndexJSON()
        local userID = database.readIndex(userEmail)
        if userID ~= nil then
            database.disconnectUser(userEmail)
            log.Info("Disconnected user: "..userEmail.." with ID: "..id.." from index and sending disconnect signal to Nexus")
        else
            if config and config.children then
                for _, childID in ipairs(config.children) do
                    rednet.send(childID, userEmail, "$DISCONNECT")
                    log.Info("Disconnect signal relayed to child ID: "..childID)
                end
            end
        end
        database.saveIndexJSON()
    end

    handler.ping = function(id, data, parentID, config)
        database.loadIndexJSON()
        local userID = database.readIndex(data)
        if data ~= "Granted" then
            if userID ~= nil then
                rednet.send(userID, "Knock... Knock!", "$PING")
                log.Info("Pinging PC with ID: "..userID)
                local senderID, receivedData = rednet.receive("$PONG",generalWaitTime)
                if senderID == userID and receivedData == "Who's there?" then
                    rednet.send(id, "Granted", "$IS_ONLINE:node")
                    log.Info("Relay granted to parent")
                else
                    rednet.send(id, "Denied", "$IS_ONLINE:node")
                    log.Warning("Denied relay from parent as user"..data.."is supposedly offline.")
                end
            elseif config and config.children then
                    for _, childID in ipairs(config.children) do
                        rednet.send(childID, data, "$IS_ONLINE")
                        log.Info("Is_online request relayed to child ID: "..childID)
                    end
            end
        elseif data == "Granted" then
            rednet.send(parentID, "Granted", "$IS_ONLINE:node")
        elseif data == "Denied" then
            rednet.send(parentID, "Denied", "$IS_ONLINE:node")
        end 
    end

    handler.isOnlineResponse = function(id, data, parentID, config)
        if data == "Granted" then
            rednet.send(parentID, "Granted", "$IS_ONLINE:node")
            log.Info("Relay ")
        elseif data == "Denied" then
            rednet.send(parentID, "Denied", "$IS_ONLINE:node")
        end
    end

    handler.query = function(id, userEmail, parentID, config)
        local userID = database.readIndex(userEmail)
        if userID ~= nil then
            log.Info("Answered parent's query with user info. "..userEmail.." "..userID)
            rednet.send(parentID, userEmail, "$QUERY:response")
        else
            if config and config.children then
                for _, childID in ipairs(config.children) do
                    rednet.send(childID, userEmail, "$QUERY_ALL")
                    log.Info("Query relayed to child ID: "..childID)
                end
            end
        end
    end

    handler.queryResponse = function(id, userEmail, parentID)
        rednet.send(parentID, userEmail, "$QUERY:response")
        log.Info("Relayed query response to parent ID: "..parentID)
    end

    handler.discover = function(userID)
        local nodeID = os.getComputerID()
        rednet.send(userID, nodeID, "$DISCOVER")
    end

    handler.coordinates = function()
        local x,y,z = gps.locate()
        return x,y,z
    end

    handler.getParent = function()
        local x,y,z = handler.coordinates()
        local config = database.loadConfigJSON()
        local parentID = config.parent
        local hop = config.hop
        if parentID ~= nil and hop ~= nil then
            return parentID, hop
        end
        local nodeID = os.getComputerID()
        local nexusID = rednet.lookup("NPL","Nexus-Alpha")
        if nexusID ~= nil then
            hop = 1
            log.Info("Found Nexus as suitable parent.")
            return nexusID, hop
        else 
            rednet.broadcast({id = nodeID, cords = {x=x,y=y,z=z}},"$NEW:node")
            log.Info("Broadcasting to search for suitable parents.")
        end
    end

    handler.answerNewNode = function(id, sentID, cords, myHop)
            if id ~= os.getComputerID() then
                local x,y,z = handler.coordinates()
                local nx, ny, nz = cords.x, cords.y, cords.z
                local distance = nil
                if x and y and z and nx and ny and nz then
                    distance = math.sqrt((x-nx)^2 + (y-ny)^2 + (z-nz)^2)
                end
                rednet.send(id, {hop = myHop, distance = distance}, "$JOIN:node")
                log.Info("Sent join request to Node ID: "..id)
            end
    end

    handler.sortCandidates = function(candidates)
        if #candidates == 0 then
            log.Warning("No suitable parent found, please relocate Node.")
        return nil
        end

        table.sort(candidates, function(a, b)
            if a.hop ~= b.hop then
                return a.hop < b.hop
            elseif distance then
                return a.distance < b.distance
            end
        end)

    local best = candidates[1]
    local parentID = best.id
    local myHop = best.hop + 1

        rednet.send(best.id, {id = os.getComputerID()}, "$CHILD")
        if distance then
        log.Info("Selected as suitable parent Node with ID: "..best.id..", hop: "..best.hop.." and distance: "..best.distance..".")
        else
        log.Info("Selected as suitable parent Node with ID: "..best.id..", hop: "..best.hop..".")
        end
    return parentID, myHop
    end

    handler.answerChild = function(id, data, childrenIDS, config)
    local myID = os.getComputerID()
    local alreadyChild = false

    for _, childID in ipairs(childrenIDS) do
        if id == childID then
            alreadyChild = true
            break
        end
    end

    if not alreadyChild then
        table.insert(config.children, id)
        database.saveConfigJSON(config)
        log.Info("Added new child ID: "..id.." to config.json")
    end

    rednet.send(id, myID, "$PARENT")
    log.Info("Sent parent confirmation to Node ID: "..id)
end

    handler.completeConnection = function(id, data, parentID)
        if id == parentID then
            log.Info("Connected to parent Node with ID: "..parentID..".")
        end
    end

return handler
