local sysPath = "/sys/.sysver.json"
local sys = nil
if fs.exists(sysPath) then
    local sysFile = fs.open(sysPath, "r")
    local content = sysFile.readAll()
    sysFile.close()
    sys = textutils.unserializeJSON(content)
end

local w, h = term.getSize()
local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
local title = "Welcome to the NovaOS installer!"
local text = ""

if not sys then
    local directories = {
        "/bin",
        "/bin/pacg",
        "/sys",
        "/sys/networking",
        "/lib",
        "/etc",
        "/var",
    }
    for _, dir in ipairs(directories) do
        if not fs.exists(dir) then
            term.clear()
            text = "Making directories: "..dir
            term.setCursorPos(centerX - #title / 2, centerY)
            print(title)
            term.setCursorPos(centerX - #text / 2, centerY + 2)
            print(text)
            fs.makeDir(dir)
            os.sleep(0.4)
        end
    end

    if fs.exists("/startup.lua") then fs.delete("/startup.lua") end

    local source = "disk/packages/"
    local files = {
        ["startup.lua"] = "/startup.lua",
        ["kernel.lua"] = "/sys/kernel.lua",
        ["sysver.json"] = "/sys/.sysver.json",
        ["networkmanager.lua"] = "/sys/networking/networkmanager.lua",
        ["netman.lua"] = "/bin/netman.lua",
        ["pacg.lua"] = "/bin/pacg.lua",
    }
    for fileSource, dest in pairs(files) do
        if fs.exists(source .. fileSource) then
            term.clear()
            text = "Installing system files... "..fileSource
            term.setCursorPos(centerX - #title / 2, centerY)
            print(title)
            term.setCursorPos(centerX - #text / 2, centerY + 2)
            print(text)
            fs.copy(source .. fileSource, dest)
            os.sleep(0.2)
        else
            term.clear()
            text = "Missing system file: " .. fileSource
            term.setCursorPos(centerX - #title / 2, centerY)
            print(title)
            term.setCursorPos(centerX - #text / 2, centerY + 2)
            print(text)
            os.sleep(1)
        end
    end

    text = "Installation completed! Rebooting."
        term.clear()
        term.setCursorPos(centerX - #title / 2, centerY)
        print(title)
        term.setCursorPos(centerX - #text / 2, centerY + 2)
        print(text)
    os.sleep(0.8)
    os.reboot()
    else
        text = "A system is already installed," 
        term.clear()
        term.setCursorPos(centerX - #text / 2, centerY + 1)
        print(text)
        text = "please select the fix/update option."
        term.setCursorPos(centerX - #text / 2, centerY + 2)
        print(text)
end