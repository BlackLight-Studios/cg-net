package.path = package.path .. ";/sys/networking/?.lua"
local networkmanager = require("networkmanager")

if not networkmanager.isModemOnline() then
    print("Modem is not online.")
    return
end

local options = {
    "Send an email to an user",
    "Check your inbox",
    "Quit app",
    "Logout",
}

local function drawText(text, modY)
    if not modY then
        term.clear()
    end
    local w, h = term.getSize()
    local centerX, centerY = math.floor(w / 2), math.floor(h / 2)
    local mY = 0
    if modY then mY = modY end
    term.setCursorPos(centerX - #text / 2, centerY + mY)
    print(text)
end 

local appPath = "/bin/nova-mail/.usermail.json"
local email
if not fs.exists(appPath) then
    email = nil
    term.clear()
    drawText("Please create or login", 0)
    drawText("with your email (or username).", 1)
    email = read()
    if email:sub(-11) ~= "@cgmail.mc" and email ~= nil  then
        email = email .. "@cgmail.mc"
    else
        while email == nil or email:sub(-11) ~= "@cgmail.mc" do
            drawText("Invalid address", 0)
        end
        email = email .. "@cgmail.mc"
    end
    if networkmanager.send("$CONNECT",email) then
        local file = fs.open(appPath, "w")
        file.write(textutils.serialiseJSON(email))
        file.close()
    else
        drawText("Failed to connect to email server.")
        os.sleep(1)
        term.clear()
        term.setCursorPos(1,1)
        return
    end
else
    local file = fs.open(appPath, "r")
    email = textutils.unserialiseJSON(file.readAll())
    file.close()
end

local function drawMenu(options, selected)
    term.clear()
    local w, h = term.getSize()
    local startY = math.floor(h/2) - #options
    term.setCursorPos(1,1)
    print("Welcome! ",email)
    term.setCursorPos(1,2)
    print("Your computer id: ",os.getComputerID())
    term.setCursorPos(1,3)
    print(string.rep("-", w))
    for i, option in ipairs(options) do
        local text = (i == selected and "> " or "  ") .. option
        local x = math.floor((w - #text)/2)
        term.setCursorPos(x, startY + i)
        term.write(text)
    end
end

local selectedField = 1

local fields = {
    {label="To", value=""},
    {label="Subject", value=""},
    {label="Body", value=""}
}

local function drawForm()
    term.clear()
    term.setCursorPos(1,19)
    for i, field in ipairs(fields) do
        local text = field.label .. ": " .. field.value
        if i == selectedField then
            term.setTextColor(colors.purple)
            print("> " .. text)
            term.setTextColor(colors.white)
        else
            print("  " .. text)
        end
    end
    term.setCursorPos(1,19)
    term.setTextColor(colors.lightGray)
    print("Press ENTER to edit, F to send, Q to cancel")
    term.setTextColor(colors.white)
end

local function editField(index)
    term.setCursorPos(1, #fields + 3)
    term.clearLine()
    write("Insert " .. fields[index].label .. ": ")
    fields[index].value = read()
end

local function sendEmail(replyUser, replySubject)
    local dest, subject
        if replyUser then
            dest = replyUser
            fields[1].value = replyUser
        end
        if replySubject then
            subject = "re: "..replySubject
            fields[2].value = "re: "..replySubject
        end
    while true do
        drawForm()
        local e, k = os.pullEvent("key")
        if k == keys.up then
            selectedField = (selectedField - 2) % #fields + 1
        elseif k == keys.down then
            selectedField = selectedField % #fields + 1
        elseif k == keys.enter then
            editField(selectedField)
        elseif k == keys.f then
            if fields[1].value ~= nil then
                dest = fields[1].value
                subject = fields[2].value
                local body = fields[3].value
                drawText("Sending email...")
                networkmanager.send("$SEND_EMAIL",{from=email,dest=dest,subject=subject,body=body})
                os.sleep(0.5)
                term.clear()
                term.setCursorPos(1,1)
                break
            end
        elseif k == keys.q then
            term.clear()
            term.setCursorPos(1,1)
            break
        end
    end
end

local function drawInbox(readMails, startIndex, selectedIdx)
    term.clear()
    local w, h = term.getSize()
    local headerLines, footerLines = 2, 1
    local pageSize = math.max(1, h - headerLines - footerLines)

    term.setCursorPos(1, 1); print("Inbox of " .. email)
    term.setCursorPos(1, 2); print(string.rep("-", w))

        for row = 0, pageSize - 1 do
            local i = startIndex + row
            term.setCursorPos(1, 3 + row)
            term.clearLine()
            local mail = readMails[i]
            if mail then
                local line = i .. ") From: " .. mail.from .. " | Subject: " .. mail.subject
                if i == selectedIdx then
                    term.setBackgroundColor(colors.purple)
                    term.setTextColor(colors.white)
                    write(line)
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.white)
                else
                    write(line)
                end
            end
        end

        term.setCursorPos(1, h)
        term.clearLine()
        term.setTextColor(colors.gray)
        write("UP/DOWN to scroll  ENTER to open  Q to back")
        term.setTextColor(colors.white)
end

local function viewMail(readMails, index, oldMailsPath)
    local mail = readMails[index]
    if not mail then return readMails end

    local bodyLines = {}
    for line in (tostring(mail.body) .. "\n"):gmatch("(.-)\n") do
        table.insert(bodyLines, line)
    end
    if #bodyLines == 0 then table.insert(bodyLines, "") end

    local startLine = 1
    while true do
        term.clear()
        local w, h = term.getSize()
        local headerLines, footerLines = 3, 1
        local pageSize = math.max(1, h - headerLines - footerLines)

        term.setCursorPos(1,1); print("From: " .. (mail.from or ""))
        term.setCursorPos(1,2); print("Subject: " .. (mail.subject or ""))
        term.setCursorPos(1,3); print(string.rep("-", w))

        for row = 0, pageSize - 1 do
            local i = startLine + row
            term.setCursorPos(1, 4 + row)
            term.clearLine()
            if bodyLines[i] then write(bodyLines[i]) end
        end

        term.setCursorPos(1, h-1)
        term.clearLine()
        term.setTextColor(colors.gray)
        write("[UP/DOWN] to scroll - [D] to delete \n[Q] to go back - [R] to reply")
        term.setTextColor(colors.white)

        local _, key = os.pullEvent("key")
        if key == keys.up then
            if startLine > 1 then startLine = startLine - 1 end
        elseif key == keys.down then
            if startLine + pageSize - 1 < #bodyLines then startLine = startLine + 1 end
        elseif key == keys.d then
            table.remove(readMails, index)
            local f = fs.open(oldMailsPath, "w")
            f.write(textutils.serialiseJSON(readMails))
            f.close()
            return readMails
        elseif key == keys.q then
            return readMails
        elseif key == keys.r then
            local replyUser = mail.from
            sendEmail(replyUser, mail.subject)
        end
    end
end

local selected = 1
drawMenu(options, selected)

while true do
    local e,k = os.pullEvent("key")
    if k == keys.up then
        selected = (selected - 2) % #options + 1
        drawMenu(options, selected)
    elseif k == keys.down then
        selected = selected % #options + 1
        drawMenu(options, selected)
    elseif k == keys.enter then
        break
    end
end

term.clear()
if selected == 1 then

    sendEmail()

elseif selected == 2 then
    local oldMailsPath = "/bin/nova-mail/.oldmails.json"
    local mails = networkmanager.getInbox()
    local readMails = {}

    if fs.exists(oldMailsPath) then
        local file = fs.open(oldMailsPath, "r")
        readMails = textutils.unserialiseJSON(file.readAll())
        file.close()
    end

    if #mails == 0 then
        mails = networkmanager.requestEmails(email, 1.5)
        if #mails > 0 then
            for _, mail in ipairs(mails) do
                table.insert(readMails, mail)
            end
            local file = fs.open(oldMailsPath, "w+")
            file.write(textutils.serialiseJSON(readMails))
            file.close()
        end
    else
        for _, mail in ipairs(mails) do
            table.insert(readMails, mail)
        end
        local file = fs.open(oldMailsPath, "w+")
        file.write(textutils.serialiseJSON(readMails))
        file.close()
    end

local startIndex, selectedIdx = 1, 1
while true do
    drawInbox(readMails, startIndex, selectedIdx)

    local w, h = term.getSize()
    local headerLines, footerLines = 2, 1
    local pageSize = math.max(1, h - headerLines - footerLines)

    local _, key = os.pullEvent("key")
    if key == keys.q then
        term.clear()
        term.setCursorPos(1, 1)
        break
    elseif key == keys.up then
        if selectedIdx > 1 then selectedIdx = selectedIdx - 1 end
        if selectedIdx < startIndex then startIndex = selectedIdx end
    elseif key == keys.down then
        if selectedIdx < #readMails then selectedIdx = selectedIdx + 1 end
        if selectedIdx > startIndex + pageSize - 1 then
            startIndex = selectedIdx - pageSize + 1
        end
    elseif key == keys.enter then
        if readMails[selectedIdx] then
            readMails = viewMail(readMails, selectedIdx, oldMailsPath)
            if selectedIdx > #readMails then selectedIdx = #readMails end
            if selectedIdx < 1 then selectedIdx = 1 end
            if selectedIdx < startIndex then startIndex = selectedIdx end
            if selectedIdx > 0 and #readMails > 0 then
                if selectedIdx > startIndex + pageSize - 1 then
                    startIndex = math.max(1, selectedIdx - pageSize + 1)
                end
            else
                startIndex = 1
            end
        end
    end
end
elseif selected == 3 then
    term.clear()
    term.setCursorPos(1, 1)
    return 
elseif selected == 4 then
    fs.delete(appPath)
    term.clear()
    term.setCursorPos(1, 1)
    return
end