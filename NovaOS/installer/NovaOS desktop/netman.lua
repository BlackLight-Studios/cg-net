package.path = package.path .. ";/sys/networking/networkmanager.lua"
local networkmanager = require("networkmanager")

local options = {
    "Search for a Modem",
    "Connect to a Node"
}

local function drawText(text)
    term.clear()
    local w, h = term.getSize()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
        term.setCursorPos(centerX - #text / 2, centerY + 2)
        print(text)
end 

local function drawMenu(options, selected)
    term.clear()
    local w, h = term.getSize()
    local startY = math.floor(h/2) - #options
    for i, option in ipairs(options) do
        local text = (i == selected and "> " or "  ") .. option
        local x = math.floor((w - #text)/2)
        term.setCursorPos(x, startY + i)
        term.write(text)
    end
end

local selected = 1
drawMenu(options, selected)

while true do
    local e,k = os.pullEvent("key")
    if k == keys.up then
        selected = selected - 1
        if selected < 1 then selected = #options end
        drawMenu(options, selected)
    elseif k == keys.down then
        selected = selected + 1
        if selected > #options then selected = 1 end
        drawMenu(options, selected)
    elseif k == keys.enter then
        break
    end
end

term.clear()
if selected == 1 then
    if networkmanager.openRednet() then
        drawText("Modem online!")
    else
        drawText("Please make sure your modem is connected.")
    end
elseif selected == 2 then
    term.clear()
    drawText("Searching for nodes...")
    local nodes = networkmanager.searchNode(3)
    if #nodes == 0 then
        drawText("No node answered.")
        return
    end
    print("Nodes found:")
    for i, id in ipairs(nodes) do
        print(i .. ": " .. id)
    end

    print("Choose a node number:")
    local choice = tonumber(read())
    local selectedNode = nodes[choice]
    if selectedNode then
        print("Selected node: " .. selectedNode)
        networkmanager.setDefaultNode(selectedNode)
    else
        print("Invalid choice")
    end
end
