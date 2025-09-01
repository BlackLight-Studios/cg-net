package.path = package.path .. ";/sys/networking/networkmanager.lua"
local networkmanager = require("networkmanager")
local backgroundServicesPath = "/etc/backgroundservices.json"

local sysPath = fs.open("/sys/.sysver.json", "r")
local sysFile = sysPath.readAll()
local sys = textutils.unserializeJSON(sysFile)
sysPath.close()
local path = shell.path()
shell.setPath(path .. ":/bin")
term.clear()
term.setCursorPos(1,1)
print("This machine is running version "..sys.version.." of "..sys.system)
local function shellLoop()
    while true do
        term.setTextColor(colors.purple)
        local currentDir = shell.dir()
        term.write("nova/")
        term.setTextColor(colors.yellow)
        term.write(currentDir)
        term.setTextColor(colors.purple)
        term.write("> ")
        term.setTextColor(colors.white)
        local cmd = read()
            if cmd == "shutdown" then
                print("Shutting down, bye!")
                os.shutdown()
            elseif cmd == "help" then
                print("Available commands are:")
                print("help - displays this screen")
                print("shutdown - shuts the computer down")
                print("ls - lists the available directories")
                print("cd - moves to a different directory")
                print("mkdir - creates a new directory")
                print("reboot - reboots the system")
            elseif cmd == "ver" then
                print("This machine is running version "..sys.version.." of "..sys.system)
            else
            shell.run(cmd)
        end
    end
end

local backgroundServices = {}

local function background()
    -- add services you wanna have in background in the /etc/backgroundservices.json file! 
    -- add them like this: ["service.lua","service2.lua"]
    -- add services to a "while true" loop if you need to, if you have a while true loop inside the service already you don't need one here
    -- use multishell or openTab to open multiple tabs
    local netman = shell.openTab("/bin/netman.lua")
    shell.switchTab(netman)
    multishell.setTitle(netman, "netman")
    
    local file = nil
    if backgroundServicesPath then
        file = fs.open(backgroundServicesPath, "r")
    else
        file = fs.open("/etc/backgroundservices.json", "w")
        file.write("[]")
        file.close()
        file = fs.open("/etc/backgroundservices.json", "w")
    end
    if file then
        local content = textutils.unserialiseJSON(file.readAll())
        if content ~= "" then
            for _, service in ipairs(content) do
                table.insert(backgroundServices, function() shell.run(service) end)
            end
        end
    end
end

background()

if backgroundServices ~= {} then
    parallel.waitForAll(shellLoop, table.unpack(backgroundServices), networkmanager.listener)
else
    parallel.waitForAll(shellLoop, networkmanager.listener)
end