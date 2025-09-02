local options = {
    "NexusOS Installer",
    "Fix / Update NexusOS",
    "NexusOS for Proxies (NodeOS)",
    "Fix / Update NodeOS"
}

local selected = 1

local function drawMenu()
    term.clear()
    term.setCursorPos(1, 1)
    print("NexusOS Manager")
    print("----------------")
    for i, option in ipairs(options) do
        if i == selected then
            print("> ".. option)
        else
            print("  ".. option)
        end
    end
end

drawMenu()

while true do
    local event, key = os.pullEvent("key")
    if key == keys.up then
        selected = selected - 1
        if selected < 1 then
            selected = #options
        end
        drawMenu()
    elseif key == keys.down then
        selected = selected + 1
        if selected > #options then
            selected = 1
        end
        drawMenu()
    elseif key == keys.enter then
        if selected == 1 then
            term.clear()
            shell.run("/disk/installers/NexusOS_installer.lua")
        elseif selected == 2 then
            term.clear()
            shell.run("/disk/installers/NexusOS_updater.lua")
        elseif selected == 3 then
            term.clear()
            shell.run("/disk/installers/NodeOS_installer.lua")
        elseif selected == 4 then
            term.clear()
            shell.run("/disk/installers/NodeOS_updater.lua")
        end
        break
    end
end
