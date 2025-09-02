local nodeIndex = {

}

local log = require("logger")

local database = {}
    database.saveEmailJSON = function(destEmail, mailData)
    local dbDirs = "/var/db/users"
    local userDir = fs.combine(dbDirs, destEmail)
        if not fs.exists(userDir) then
            fs.makeDir(userDir)
            log.Info("Directory created for user ".. destEmail)
        end
        local filename = os.date("%Y-%m-%d_%H:%M:%S")
        local filePath = fs.combine(userDir, filename..".json")
        local file = fs.open(filePath, "w")
        local jsonString
            if type(mailData) == "table" then
                jsonString = textutils.serializeJSON(mailData)
            else
                jsonString = mailData
            end
        file.write(jsonString)
        file.close()
        log.Info("Email saved to ".. filePath)

        return filePath
    end

    database.readEmailsJSON = function(userEmail)
        local dbDir = "/var/db/users"
        local userDir = fs.combine(dbDir, userEmail)
        local emailList = {}

        if fs.exists(userDir) then
            local files = fs.list(userDir)
           for _, email in ipairs(files) do
                local path = fs.combine(userDir, email)
                local file = fs.open(path, "r")
                if file then
                    local content = file.readAll()
                    file.close()

                    local mail = textutils.unserializeJSON(content)
                    if mail then
                        table.insert(emailList, mail)
                        log.Info("Email added to emaillist: " .. email)
                        fs.delete(path)
                    else
                        log.Warning("Invalid JSON in file: " .. path)
                        log.Warning("Raw content: " .. content)
                    end
                end
            end
        else
            log.Warning("User dir does not exist: " .. userDir)
        end

        log.Info("Formed email list for " .. userEmail)
        local emailJSON = textutils.serializeJSON(emailList)
        return emailJSON
    end

    database.deleteEmailJSON = function(pathJSON)
        fs.delete(pathJSON)
    end

    database.saveIndexJSON = function(userEmail, nodeID)
        nodeIndex[userEmail] = nodeID
        local indexPath = ("/var/db/nodeIndex.json")
        if not fs.exists(indexPath) then
            local file = fs.open(indexPath, "w")
                file.write(textutils.serializeJSON(nodeIndex))
                file.close()
                log.Info("Index saved to JSON file")
        else
            local file = fs.open(indexPath, "w+")
                file.write(textutils.serializeJSON(nodeIndex))
                file.close()
                log.Info("Index JSON file updated")
        end
    end

    database.loadIndexJSON = function()
        local indexPath = ("/var/db/nodeIndex.json")
        if fs.exists(indexPath) then
            local file = fs.open(indexPath, "r")
            if file then
                local content = file.readAll()
                file.close()
                local data = textutils.unserializeJSON(content)
                if type(data) == "table" then
                    for userEmail, nodeID in pairs(data) do
                        nodeIndex[userEmail] = nodeID
                    end
                    log.Info("Index loaded from JSON file")
                end
            end
        end
    end

    database.readIndex = function(userEmail)
        local nodeID = nodeIndex[userEmail]
        return nodeID
    end

    database.queryAll = function(userEmail, generalWaitTime)
        rednet.broadcast(userEmail,"$QUERY_ALL")
        local nodeID, checkEmail = rednet.receive("$QUERY:response",generalWaitTime)
            if nodeID and (checkEmail == userEmail) then
                nodeIndex[userEmail] = nodeID
                return nodeID
            elseif nodeID ~= nil then
                log.Warning("Unexistant user received from ".. nodeID)
                return nil
            else 
                log.Error("No response from query")
            end
    end

    database.readRepoJSON = function(package)
        local repoPath = ("/repo")
        local packagesPath = fs.combine(repoPath,"packages")
        if not package then
            local repoPackages = textutils.serializeJSON(fs.list(packagesPath))
            if repoPackages ~= {} then
                return repoPackages
            else
                return nil
            end
        else
            local packagePath = fs.combine(packagesPath,package)
            if fs.exists(packagePath) then
                local manifestPath = fs.combine(packagePath,"manifest.json")
                    local file = fs.open(manifestPath, "r")
                    local manifestJSON = file.readAll()
                        file.close()
                        return manifestJSON
            else
                return nil
            end
        end
    end

    database.getRepoJSON = function(package)
        local packetFiles = {}
        local repoPath = "/repo/packages"
        local packagePath = fs.combine(repoPath, package .. "/packets")
        local size = 0
            if fs.exists(packagePath) then
                local files = fs.list(packagePath)
                for _, packet in ipairs(files) do
                    local filePath = fs.combine(packagePath, packet)
                    size = size + fs.getSize(filePath)
                    if not fs.isDir(filePath) then
                        local file = fs.open(filePath, "r")
                        if file then
                            local content = file.readAll()
                            file.close()
                            packetFiles[packet] = content
                        end
                    end
                end
                local packagePath = fs.combine("/repo/packages",package)
                local manifestPath = fs.combine(packagePath,"manifest.json")
                    local file = fs.open(manifestPath, "r")
                    local manifestJSON = file.readAll()
                    local manifest = textutils.unserializeJSON(manifestJSON)
                    file.close()
                return textutils.serializeJSON({
                    package = package,
                    files = packetFiles,
                    size = size,
                    manifest = manifest,
                    executable = manifest.executable
                })
            else
                return nil
            end
    end

return database
