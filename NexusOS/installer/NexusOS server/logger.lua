--local loggerTab = multishell.launch({},"/nexusos/logger.lua")
--multishell.setFocus(loggerTab)
--multishell.setTitle(loggerTab, "Logs")
term.clear()
term.setCursorPos(1,1)
print("== Nexus logs will be displayed here ==")

local log = {}
    log.Info = function(message)
        if message then
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        print(os.date("%Y-%m-%d_%H:%M:%S").." "..message)
        end
    end

    log.Error = function(message)
        if message then
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.red)
        print(os.date("%Y-%m-%d_%H:%M:%S").." "..message)
        end
    end

    log.Warning = function(message)
        if message then
        term.setTextColor(colors.black)
        term.setBackgroundColor(colors.yellow)
        print(os.date("%Y-%m-%d_%H:%M:%S").." "..message)
        end
    end
return log

