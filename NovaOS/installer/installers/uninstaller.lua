local sysPath = "/sys/.sysver.json"
local sys = nil
if fs.exists(sysPath) then
    local sysFile = fs.open(sysPath, "r")
    local content = sysFile.readAll()
    sysFile.close()
    sys = textutils.unserializeJSON(content)
end

local function drawTitle()
    local w, h = term.getSize()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
    local title = "Welcome to the NovaOS uninstaller!"
        term.setCursorPos(centerX - #title / 2, centerY)
            print(title)
end

local function centerText(text, modY)
    if not modY then modY = 0 end
    local w, h = term.getSize()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
        term.setCursorPos(centerX - #text / 2, centerY + 1 + modY)
            print(text)
end

if sys then
if sys.system == "NovaOS" then
    local directories = {
        "/bin",
        "/sys",
        "/lib",
        "/etc",
        "/var",
    }

    term.clear()
    drawTitle()
    centerText("Are you sure you want to uninstall NovaOS?")
    centerText("This will delete all files!", 1)
    centerText("[y/n]",2)
    local answer = read()
    if answer == "y" or answer == "yes" then
        for _, dir in ipairs(directories) do
            if fs.exists(dir) then
               term.clear()
               drawTitle()
               centerText("Removing directory: ".. dir)
                fs.delete(dir)
                os.sleep(0.4)
            end
        end
        local startupFile = "/startup.lua"
        if fs.exists(startupFile) then
            fs.delete(startupFile)
            term.clear()
            centerText("Removing startup.lua")
            os.sleep(0.4)
        end
        centerText("Uninstallation complete.")
        centerText("Do you wish to reboot?", 1)
        centerText("[y/n]", 2)
        answer = read()
        if answer == "y" or answer == "yes" then
            term.clear()
            os.reboot()
        else
            return
        end
    else
        term.clear()
        drawTitle()
        centerText("Uninstallation cancelled.")
        os.sleep(2)
        return
    end
else
        print("No system found.")
end
end