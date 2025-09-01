local database = require("database")
local log = require("logger")

local handler = {}

--how much each handler that contains an os.sleep (so those that wait for an answer)
local generalWaitTime = 6

    handler.relayEmails = function(inData) --emails from Nodes ($RELAY_EMAIL)
        if inData.dest then
        database.loadIndexJSON()  
        local destEmail = inData.dest
        local pathJSON = database.saveEmailJSON(destEmail, inData)
        local nodeID = database.readIndex(destEmail)
        if nodeID == nil then
            nodeID = database.queryAll(destEmail, generalWaitTime)
            if nodeID ~= nil then
                database.saveIndexJSON(destEmail, nodeID)
                rednet.send(nodeID, destEmail, "$IS_ONLINE")
                local id, response = rednet.receive("$IS_ONLINE:node",generalWaitTime)
                log.Warning(response)
                if response == "Granted" then
                    rednet.send(nodeID, inData, "$SEND_EMAIL")
                    database.deleteEmailJSON(pathJSON)
                    log.Info("Email sent to ".. destEmail.. " and deleted from database")
                elseif response == "Denied" then
                    log.Info("Email not sent to ".. destEmail.. " due to denied access")
                else
                    log.Error("Node "..nodeID.." took too long to answer")
                end
            else
                log.Warning("No user found for ".. destEmail)
            end
        else
            rednet.send(nodeID, destEmail, "$IS_ONLINE")
            local id, response = rednet.receive("$IS_ONLINE:node",generalWaitTime)
            if response == "Granted" then
                rednet.send(nodeID, inData, "$SEND_EMAIL")
                database.deleteEmailJSON(pathJSON)
                log.Info("Email sent to ".. destEmail.. " and deleted from database")
            elseif response == "Denied" then
                log.Info("Email not sent to ".. destEmail.. " due to denied access")
            else
                log.Error("Node "..nodeID.." took too long to answer")            end
        end
    end
    end

     handler.getEmails = function(userEmail, nodeID)
        database.loadIndexJSON()
        local emailsJSON = database.readEmailsJSON(userEmail)
            if emailsJSON and emailsJSON ~= "{}" then
                rednet.send(nodeID, emailsJSON, "$REQUEST_EMAILS:nexus")
            end
        local oldNodeID = database.readIndex(userEmail)
            if oldNodeID ~= nodeID then
                database.saveIndexJSON(userEmail, nodeID)
                log.Info("Changed node for ".. userEmail.. " and updated index")
                if oldNodeID then
                    rednet.send(oldNodeID, userEmail, "$DISCONNECT")
                end
            end
    end

-- pacg <list|install|remove|update> <package>

    handler.getPackets = function(userEmail, inputData, nodeID)
        local action = inputData.action
        local package = nil
        if inputData.package ~= nil then
            package = inputData.package
        end
        if action == "list" then
            if not package then
                local repoList = database.readRepoJSON()
                    rednet.send(nodeID, repoList, "$REQUEST_PACKETS:nexus")
            else
                local packageList = database.readRepoJSON(package)
                    if packageList then
                        rednet.send(nodeID, packageList, "$REQUEST_PACKETS:nexus")
                    else
                        rednet.send(nodeID, textutils.serialiseJSON("No such package"), "$REQUEST_PACKETS:nexus")
                    end
            end
        elseif action == "install" then
            if package then
                local packageInstall = database.getRepoJSON(package)
                    if packageInstall then
                        rednet.send(nodeID, packageInstall, "$REQUEST_PACKETS:nexus")
                    else
                        rednet.send(nodeID, textutils.serialiseJSON("No such package"), "$REQUEST_PACKETS:nexus")
                    end
            end
        end
    end

return handler
