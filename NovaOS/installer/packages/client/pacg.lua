package.path = package.path .. ";/sys/networking/?.lua"
local networkmanager = require("networkmanager")

if not networkmanager.isModemOnline() then
    print("Modem is not online.")
    return
end

local args = {...}
local pacgPath = "/bin/pacg"
local binariesPath = "/bin"
local nexusFile

local function writeFiles(pkg, installFiles, updater)
    for packetName, file in pairs(installFiles.files) do
        if fs.exists(fs.combine(binariesPath, pkg, file)) and updater then
            fs.delete(fs.combine(binariesPath, pkg, file))
        end
            local w, h = term.getSize()
            local maxBarWidth = w - string.len(packetName) - 8
            local progress = 0
            local percent = math.floor(progress/installFiles.size * 100)
            local filledBarWidth = math.floor(percent/100 * maxBarWidth)
            local x, y = term.getCursorPos()
            local dirName = string.gsub(installFiles.executable,".lua", "")
            local path = fs.combine(binariesPath, dirName)
            term.setCursorPos(1, y)
            local iX, iY = term.getCursorPos()
                while progress < installFiles.size do
                    term.setCursorPos(iX, iY)
                    print(packetName.." ["..string.rep("#",filledBarWidth)..string.rep("-",maxBarWidth-filledBarWidth).."] "..percent.."%")
                    progress = progress + math.random(1, installFiles.size/2)
                    percent = math.floor(progress/installFiles.size * 100)
                    filledBarWidth = math.floor(percent/100 * maxBarWidth)
                    os.sleep(math.random(1,2))
                end
                if not fs.exists(path) then
                    fs.makeDir(path)
                end
                if installFiles.executable ~= pkg..".lua" then
                    local f = fs.open(fs.combine(binariesPath,dirName,file), "w+")
                    f.write(file)
                    f.close()
                else
                    local executable = installFiles.executable
                    local f = fs.open(fs.combine(binariesPath,executable), "w")
                    f.write(file)
                    f.close()
                end
            end
end

if args[1] == "list" then
    if not args[2] then
        networkmanager.send("$REQUEST_PACKETS:client", {action="list"})
    else
        networkmanager.send("$REQUEST_PACKETS:client", {action="list", package=args[2]})
    end
    local nexusSentData = networkmanager.repo()
    if type(nexusSentData) == "table" then
        if not args[2] then
            for title, package in pairs(nexusSentData) do
                local x, y = term.getCursorPos()
                term.setCursorPos(1, y)
                print(title.." "..package)
            end
        else
            for title, line in pairs(nexusSentData) do
                local x, y = term.getCursorPos()
                term.setCursorPos(1, y)
                print(title..": "..line)
            end
        end
    elseif type(nexusSentData) == "string" then
        print(nexusSentData)
    else 
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.red)
        print("Error while parsing Nexus repository.")
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
    end
elseif args[1] == "install" then
    if not args[2] then
        print("Package to install not specified after 'install' command.")
        return
    end
    for i = 2, #args do
        local pkg = args[i]
        if not fs.exists(fs.combine(binariesPath,pkg)) then
            networkmanager.send("$REQUEST_PACKETS:client", {action="install", package=pkg})
            local installFiles = networkmanager.repo()
            local manifestTable = installFiles.manifest
            if type(installFiles) == "table" then
                print("Installing "..installFiles.package..", size of: "..math.floor((installFiles.size/1024)).." MB")
                    writeFiles(pkg, installFiles, false)
                    if not fs.exists(fs.combine(binariesPath,pkg,"manifest.json")) then
                        local file = fs.open(fs.combine(binariesPath,pkg,"manifest.json"),"w")
                        file.write(textutils.serialiseJSON(manifestTable))
                        file.close()
                    end
            else
                print("Error while installing package "..pkg..".")
            end
        else
                print("Package "..pkg.." already installed.")
        end
    end
elseif args[1] == "remove" then
    if not args[2] then
        print("Package to remove not specified after 'remove' command.")
        return
    else
        for i = 2, #args do
            local pkg = args[i]
            if fs.exists(fs.combine(binariesPath,pkg)) then
                fs.delete(fs.combine(binariesPath,pkg))
                print("Package "..pkg.." removed.")
            else
                print("Package "..pkg.." not found.")
            end
            if fs.exists(fs.combine(binariesPath,pkg..".lua")) then
                fs.delete(fs.combine(binariesPath,pkg..".lua"))
                print("Lua script for "..pkg.." removed.")
            else
                print("Lua script for "..pkg.." not found.")
            end
        end
    end
elseif args[1] == "update" then
    if not args[2] then
        print("Package to install not specified after 'update' command.")
        return
    end
    for i = 2, #args do
        local pkg = args[i]
        if fs.exists(fs.combine(binariesPath,pkg)) then
            networkmanager.send("$REQUEST_PACKETS:client", {action="install", package=pkg})
            local installFiles = networkmanager.repo()
            local manifestTable = installFiles.manifest
            local PCversion
            if fs.exists(fs.combine(binariesPath,pkg,"manifest.json")) then
                    local file = fs.open(fs.combine(binariesPath,pkg,"manifest.json"),"r")
                    PCversion = textutils.unserialiseJSON(file.readAll())
                    file.close()
            end
            if type(installFiles) == "table" then
                if manifestTable.version ~= PCversion.version then
                print("Updating "..installFiles.package..", size of: "..math.floor((installFiles.size/1024)).." MB")
                    writeFiles(pkg, installFiles, true)
                    if fs.exists(fs.combine(binariesPath,pkg,"manifest.json")) then
                        local file = fs.open(fs.combine(binariesPath,pkg,"manifest.json"),"w+")
                        file.write(textutils.serialiseJSON(manifestTable))
                        file.close()
                    end
                else
                    print("No updates available for package "..pkg..".")
                end
            else
                print("Error while installing package "..pkg..".")
            end
        else
                print("Package "..pkg.." doesn't exist")
        end
    end
else
    print("Usage: ")
    print("pacg <list> -Lists the entire Nexus' repository.")
    print("pacg <list> [package] -Prints out the details of a specific package.")
    print("pacg <install> [package1] [package2]...")
    print("pacg <remove> [package1] [package2]...")
    print("pacg <update> [package1] [package2]...")
end

