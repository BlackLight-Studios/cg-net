local diskPath = "disk/packages/sysver.json"
local diskFile = fs.open(diskPath, "r")
local diskTable = textutils.unserializeJSON(diskFile.readAll())
local diskVer = diskTable.version
diskFile.close()

local function detectSystem()
    local systemFile = "/sys/.sysver.json"
    if not fs.exists(systemFile) then return nil end
        local f = fs.open(systemFile,"r")
        local content = f.readAll()
        local sys = textutils.unserializeJSON(content)
            f.close()
        return sys.system, sys.version
end

local function isUpdaterNewer(updVer, sysVer)
    return tonumber(updVer) > tonumber(sysVer)
end

local srcKernel = "disk/packages/kernel.lua"
local destKernel = "/sys/kernel.lua"

local function updateKernel()
    if fs.exists(srcKernel) then
        local fSrc = fs.open(srcKernel,"r")
        local contentSrc = fSrc.readAll()
        fSrc.close()
        
        local fDest = fs.open(destKernel,"w+")
        fDest.write(contentSrc)
        fDest.close()
        textutils.slowPrint("Updated kernel! Rebooting system now.")
        os.reboot()
    else
        print("Kernel file missing or corrupted in disk/packages")
    end
end

local directories = {
    "/bin",
    "/sys",
    "/sys/db",
    "/sys/db/users",
    "/sys/networking",
    "/etc",
    "/var",
    "/repo",
    "/repo/packages"
}

local function fixSystem()
    for _, dir in ipairs(directories) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
            print("Created "..dir.." directory as it was missing.")
        end
    end
    if not fs.exists("/startup.lua") then
        fs.copy("disk/packages/startup.lua","/startup.lua")
        print("Copied startup.lua as it was missing.") 
    end
    if not fs.exists("/sys/kernel.lua") then
        fs.copy("disk/packages/kernel.lua","/sys/kernel.lua")
        print("MISSING KERNEL! Copying file from diskette.")
    end
end
        local source = "disk/packages/"
        local files = {
        ["sysver.json"] = "/sys/.sysver.json",
        ["recovery.lua"] = "/bin/recovery.lua",
        ["nnet.lua"] = "/sys/networking/nnet.lua",
        ["handlers.lua"] = "/sys/networking/handlers.lua",
        ["database.lua"] = "/sys/networking/database.lua",
        ["logger.lua"] = "/sys/networking/logger.lua"
        }
local function addMissingPackages()
    for fileSource, dest in pairs(files) do
        if fs.exists(source .. fileSource) then
            if not fs.exists(dest) then
                fs.copy(source .. fileSource, dest)
                textutils.slowPrint("Copied " .. fileSource.." as it was missing.")
            end
        else
            print("Missing system file: " .. fileSource)
        end
    end
end

local function updatePackages()
    for fileSource, dest in pairs(files) do
        if fs.exists(source .. fileSource) then
            if not fs.exists(dest) then
                fs.copy(source .. fileSource, dest)
                textutils.slowPrint("Copied " .. fileSource)
            else
                fs.delete(dest)
                fs.copy(source .. fileSource, dest)
                textutils.slowPrint("Updated ".. fileSource)
            end
        else
            print("Missing system file: " .. fileSource)
        end
    end
end


local system, currentVer = detectSystem()

if system == "NexusOS" then
    fixSystem()
    addMissingPackages()
    if isUpdaterNewer(diskVer, currentVer) then
        textutils.slowPrint("Updating from version "..currentVer.." to version "..diskVer)
        updatePackages()
        updateKernel()
    else
    print("System already updated, current version is: "..currentVer)
    end
else
    print("This system is not NexusOS. Skipping updates.")
end
