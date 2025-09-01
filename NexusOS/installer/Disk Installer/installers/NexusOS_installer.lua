local sysPath = "/sys/.sysver.json"
local sys = nil
if fs.exists(sysPath) then
    local sysFile = fs.open(sysPath, "r")
    local content = sysFile.readAll()
    sysFile.close()
    sys = textutils.unserializeJSON(content)
end

if not sys then
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

print("Welcome to the NexusOS installer!")
os.sleep(0.5)
for _, dir in ipairs(directories) do
    if not fs.exists(dir) then
        fs.makeDir(dir)
        textutils.slowPrint("Created "..dir)
    end
end

if fs.exists("/startup.lua") then fs.delete("/startup.lua") end

print("Installing system files...")
local source = "disk/packages/"
local files = {
    ["startup.lua"] = "/startup.lua",
    ["kernel.lua"] = "/sys/kernel.lua",
    ["sysver.json"] = "/sys/.sysver.json",
    ["recovery.lua"] = "/bin/recovery.lua",
    ["nnet.lua"] = "/sys/networking/nnet.lua",
    ["handlers.lua"] = "/sys/networking/handlers.lua",
    ["database.lua"] = "/sys/networking/database.lua",
    ["logger.lua"] = "/sys/networking/logger.lua"
}
for fileSource, dest in pairs(files) do
    if fs.exists(source .. fileSource) then
        fs.copy(source .. fileSource, dest)
        textutils.slowPrint("Copied " .. fileSource)
    else
        print("Missing system file: " .. fileSource)
    end
end

print("Installation completed! Rebooting system now.")
os.sleep(0.8)
os.reboot()
else
    print("A system is already installed, please select the fix/update option.")
end

