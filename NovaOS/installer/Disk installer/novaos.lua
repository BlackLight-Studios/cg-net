local options = {
    "NovaOS for client",
    "Fix / Update NovaOS",
    "Uninstall NovaOS",
}

local selected = 1

local function drawCenter(text, y)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2)
    term.setCursorPos(x, y)
    term.write(text)
end

local function drawMenu()
    term.clear()
    local _, h = term.getSize()
    local centerY = math.floor(h / 2)
    drawCenter("NovaOS Manager", centerY - 2)
    drawCenter("----------------", centerY)
    
    local w, h = term.getSize()
    local startY = math.floor(h / 2) + 2 -- partire un paio di righe sotto il titolo

    for i, option in ipairs(options) do
        local text = option
        if i == selected then
            text = "> " .. text
        else
            text = "  " .. text
        end
        local x = math.floor((w - #text) / 2)
        term.setCursorPos(x, startY + i - 1)
        term.write(text)
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
            shell.run("/disk/installers/NovaOS_installer.lua")
        elseif selected == 2 then
            term.clear()
            shell.run("/disk/installers/NovaOS_updater.lua")
        elseif selected == 3 then
            term.clear()
            shell.run("/disk/installers/uninstaller.lua")
        end
        break
    end
end
