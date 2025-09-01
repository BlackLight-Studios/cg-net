term.clear()
term.setCursorPos(1,1)
local diskFile = ("/disk/novaos.lua")
if fs.exists(diskFile) then
    print("Detected disk with NovaOS executable, do you wish to Update/Fix your system? [y/n]")
    answer = read()
    if answer == "y" then
        shell.run(diskFile)
    end
end

shell.run("sys/kernel.lua")

