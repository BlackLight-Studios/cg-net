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

local function background()
    -- add services you wanna have in background in the /etc/backgroundservices.json file! 
    -- add them like this: ["service.lua","service2.lua"]
    -- add services to a "while true" loop if you need to, if you have a while true loop inside the service already you don't need one here
    -- use multishell or openTab to open multiple tabs
    --[[ example V
    local name = shell.openTab("path")
    shell.switchTab(name)
    multishell.setTitle(name, "title")
    --]]
end

parallel.waitForAll(shellLoop, networkmanager.listener, background)
