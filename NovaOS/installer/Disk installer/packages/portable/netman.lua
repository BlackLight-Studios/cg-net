package.path = package.path .. ";/sys/networking/networkmanager.lua"
local networkmanager = require("networkmanager")

local autoSearch = true
local options = {
    "Auto-search: "..tostring(autoSearch),
    "Search for a Modem",
    "Connect to a Node",
    "Quit app"
}

local function editAuto()
    autoSearch = not autoSearch
    options[1] = "Auto-search: " .. tostring(autoSearch)
end

local function search()
    while autoSearch do
        local nodes = networkmanager.searchNode(3)
            if #nodes > 0 then
                networkmanager.setDefaultNode(nodes[1])
            else
                networkmanager.setDefaultNode(nil)
            end
        os.sleep(300)
    end
end

local function drawText(text, modY)
    if not modY then
        modY = 0
    end
    local w, h = term.getSize()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
        term.setCursorPos(centerX - #text / 2, centerY + 2 + modY)
        print(text)
end 

local function drawMenu(options, selected)
    local w, h = term.getSize()
    term.clear()
    drawText("Network Manager",-(h/2+1))
    term.setCursorPos(1, 1)
    print("Connected to Node "..networkmanager.defaultNode(true))
    print(string.rep("-", w))
    local startY = math.floor(h/2) - #options
    for i, option in ipairs(options) do
        local text = (i == selected and "> " or "  ") .. option
        local x = math.floor((w - #text)/2)
        term.setCursorPos(x, startY + i)
        term.write(text)
    end
end

local running = true

local function main()
    while running do
        local selected = 1
        drawMenu(options, selected)

        while running do
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

        if selected == 1 then
            editAuto()
        elseif selected == 2 then
            if networkmanager.openRednet() == true then
                term.clear()
                drawText("Modem online!")
                drawText("Press any key to return.",1)
                os.pullEvent("key")
            elseif networkmanager.openRednet() == "open" then
                term.clear()
                drawText("Modem already online!")
                drawText("Press any key to return.",1)
                os.pullEvent("key")
            else
                term.clear()
                drawText("Please make sure your modem is connected.")
                drawText("Press any key to return.",1)
                os.pullEvent("key")
            end
        elseif selected == 3 then
            term.clear()
            drawText("Searching for nodes...")
            local nodes = networkmanager.searchNode(3)
            if #nodes == 0 then
                drawText("No node answered.")
            else
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
        elseif selected == 4 then
            term.clear()
            term.setCursorPos(1,1)
            running = false
        end
        sleep(0.05)
    end
end

parallel.waitForAny(search, main)