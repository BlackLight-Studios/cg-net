local args = {}
local recoveryDir = "/sys/recovery"
local kernelFile = "/sys/kernel.lua"
local backupFile = recoveryDir.."/kernel_backup.lua"

if not fs.exists("/sys/recovery") then
    fs.makeDir(recoveryDir)
end

if args[1] == "create" then
    if fs.exists(backupFile) then
        print("Backup file already exists! Run <update> to update the file.")
    else
        fs.copy(kernelFile, backupFile)
        print("Backup file created.")
    end

elseif args[1] == "restore" then

    if fs.exists(backupFile) then
        fBackup = fs.open(backupFile, "r")
            backupCopy = fBackup.readAll()
            fBackup.close()
        fKernel = fs.open(kernelFile, "w+")
            fKernel.write(backupCopy)
            fKernel.close()
        print("Kernel file restored!")
    else
        print("No recovery medium was found! Please create a new copy or use a diskette and run the _updater.lua file!")
    end
    
elseif args[1] == "update" then

    if not fs.exists(backupFile) then
        print("No recovery medium found, please create a new one with <create>.")
    else
        fuKernel = fs.open(kernelFile, "r")
            updKernelCopy = fuKernel.readAll()
            fuKernel.close()
        fuBackup = fs.open(backupFile, "w+")
            fuBackup.write(updKernelCopy)
            fuBackup.close()
        print("Backup file updated.")
    end
else
    print("Usage: recovery <create|restore|update>")
end                  
            

