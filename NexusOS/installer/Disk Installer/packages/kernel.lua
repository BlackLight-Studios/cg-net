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
        term.setTextColor(colors.blue)
        currentDir = shell.dir()
        term.write("nexus/")
        term.setTextColor(colors.yellow)
        term.write(currentDir)
        term.setTextColor(colors.blue)
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

local function backgroundServices()
        local nnet = shell.openTab("/sys/networking/nnet.lua")
        shell.switchTab(nnet)
        multishell.setTitle(nnet, "Logs")
end
parallel.waitForAll(shellLoop, backgroundServices)
    
