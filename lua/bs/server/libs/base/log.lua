--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Check if a log folder name is unique and, if it's not the case, return a unique one 
-- These names can repeat if detections occur too fast
local function ValidateFolderName(testName)
    local function ValidateFolderNameAux(newName, i)
        newName = newName:gsub("/:", "_" .. tostring(i + 1) .. "/")

        if not file.Exists(newName, "DATA") then
            return newName
        else
            return ValidateFolderNameAux(testName .. ":", i + 1)
        end
    end

    if testName and file.Exists(testName, "DATA") then
        return ValidateFolderNameAux(testName .. ":", 1)
    end

    return testName
end
table.insert(BS.locals, ValidateFolderName)

-- Make a nice format to the included codes
local function FormatTypesList(snippet, file)
    if not snippet and not file then return end

    local messages = {
        ["snippet"] = "Detected code snippet",
        ["file"] = "Full Lua file" ,
    }

    local indent = "        "
    local result = [[

]] .. (snippet and indent .. (messages["snippet"] .. "\n") or "") .. [[
]] .. (file and indent .. (messages["file"]) or "")

    return result
end
table.insert(BS.locals, FormatTypesList)

-- Make a nice format to the detected functions list
local function FormatDetectedList(inDetected)
    if not inDetected or #inDetected == 0 then return end

    local detected = ""

    for _,v1 in pairs(inDetected) do
        if isstring(v1) then
            detected = detected .. "\n        " .. v1
        elseif istable(v1) then
            for _,v2 in pairs(v1) do
                detected = detected .. "\n        " .. v2
            end
        end
    end

    return detected
end
table.insert(BS.locals, FormatDetectedList)

-- Build the log message
-- I need this to print smaller console logs for warnings while saving the full log
local function FormatLog(info)
    local partialLog
    local fullLog = ""

    -- Create full message
    for _,v in ipairs(info) do
        fullLog = fullLog .. v
    end

    fullLog = "\n" .. string.Trim(fullLog) .. "\n"

    -- Create partial message to warnings, so we don't flood the console with too much information
    if info.type == "warning" then
        --     Alert     function   detected   log dir     trace
        partialLog = "\n" .. string.Trim(info[1] .. info[3] .. info[4] .. info[6] .. info[8]) .. "\n"
    end

    return fullLog, partialLog
end
table.insert(BS.locals, FormatLog)

--[[
    Print live detections to console and files 

    Structure:

        infoIn = {
        *    alert =  Message explaining the detection
            func = Name of the bad function
            detected = List of the prohibited calls detected inside the detected function
        *    type = Detection type. I commonly use "detected", "warning" and "detour"
            folder = Main folder to store this dectetion. I commonly use the detected function name, so it's easier to find the real threats
            trace = Lua function call stack. Due to my persistent trace system, it can contain multiple stacks
            snippet = Detected code snippet
            file = File where detection occurred
        }

        * Required fields

    Note: Using the type "warning" will generate full file logs but smaller console prints
]]
function BS:Report_LiveDetection(infoIn)
    -- Format the report informations
    local timestamp = os.time()
    local date = os.date("%Y-%m-%d", timestamp)
    local timeFormat1 = os.date("%H.%M.%S", timestamp)
    local timeFormat2 = os.date("%Hh %Mm %Ss", timestamp)

    --[[
        dayFolder            e.g.    /03-16-2021/
            typeFile                     log_detected.txt
            mainFolder                   /http.Fetch/
                logFolder                    /23.57.47 - detected/
                    logFile                      [Log].txt
                    luaFile                      Full Lua file.txt
                    snippetFile                  Detected code snippet.txt
    ]]
    local dayFolder = self.folder.data .. "/" .. date .. "/"
    local typeFile = dayFolder .. "/log_" .. infoIn.type .. ".txt"
    local mainFolder = infoIn.folder and dayFolder .. infoIn.folder .. "/"
    local logFolder = mainFolder and ValidateFolderName(mainFolder .. timeFormat1 .. " - " .. infoIn.type .. "/")
    local logFile = logFolder and logFolder .. "/[Log].txt"
    local luaFile =  logFolder and infoIn.file and logFolder .. "Full Lua file.txt"
    local snippetFile =  logFolder and infoIn.snippet and logFolder .. "Detected code snippet.txt"

    local filesGenerated = logFolder and FormatTypesList(infoIn.snippet, infoIn.file)

    local detected = FormatDetectedList(infoIn.detected)

    local info = { -- If you change the fields order, update FormatLog(). Also, use "::" to identify the color position
        self.alert .. " " .. infoIn.alert or "",
        "\n    Date & time:: " .. date .. " | " .. timeFormat2,
        infoIn.trace and "\n    Location:: " .. self:Trace_GetLuaFile(infoIn.trace) or "",
        infoIn.func and "\n    Function:: " .. infoIn.func or "",
        detected and "\n    Trying to call::" .. detected or "",
        infoIn.url and "\n    Url:: " .. infoIn.url or "",
        "\n    Log Folder:: data/" .. (logFolder or dayFolder),
        filesGenerated and "\n    Log Contents:: " .. filesGenerated or "",
        infoIn.trace and "\n    Trace:: " .. infoIn.trace or ""
    }

    local fullLog, partialLog = FormatLog(info)

--[[
    Full log preview (e.g.):

    [Backdoor Shield] Execution detected!
        Date & Time: 03-14-2021 | 23h 57m 47s
        Location: addons/ariviaf4/lua/autorun/_arivia_load.lua:111
        Function: http.Fetch
        Trying to call:
            CompileString
            http.Fetch
        Url: https://gvac.cz/link/fuck.php?key=McIjefKcSOKuWbTxvLWC
        Log Folder: data/backdoor-shield/03-14-2021/http.Fetch/23.57.47 - detected/
        Log Contents:
            Detected code snippet
            Full Lua file
        Trace:
          (+)
          stack traceback:
            addons/backdoor-shield/lua/bs/server/modules/detouring/functions.lua:80: in function 'Fetch'
            addons/ariviaf4/lua/autorun/_arivia_load.lua:111: in function <addons/ariviaf4/lua/autorun/_arivia_load.lua:111>

          stack traceback:
            addons/backdoor-shield/lua/bs/server/modules/detouring/functions.lua:80: in function 'Fetch'
            addons/ariviaf4/lua/autorun/_arivia_load.lua:111: in function <addons/ariviaf4/lua/autorun/_arivia_load.lua:111>

    Note: the stack traceback is repeated to mimic the persistent trace behaviour.
]]

    -- Print to console
    for linePos,lineText in ipairs(string.Explode("\n", partialLog or fullLog)) do
        local lineParts = string.Explode("::", lineText)

        if linePos == 2 then
            local alertInfo = infoIn.type == "detected" and {
                color = self.colors.highRisk,
                prefix = " [HIGH] "
            } or {
                color = self.colors.mediumRisk,
                prefix = " [Medium] "
            }
            MsgC(alertInfo.color, "▉▉▉", self.colors.value, alertInfo.prefix .. lineText .. "\n")
        elseif #lineParts > 0 then
            if not lineParts[2] then
                MsgC(self.colors.value, lineParts[1] .. "\n")
            else
                MsgC(self.colors.key, lineParts[1] .. ":", self.colors.value, lineParts[2] .. "\n")
            end
        else
            print(lineText)
        end
    end

    -- Clean color identificator
    fullLog = string.gsub(fullLog, "::", ":")

    -- Update counter
    if infoIn.type == "warning" then
        self.liveCount.warnings = self.liveCount.warnings + 1
    else
        self.liveCount.detections = self.liveCount.detections + 1
    end

    -- Send a GUI update
    if self.live.alertAdmins then
        for _,ply in pairs(player.GetHumans()) do
            if ply:IsAdmin() then
                net.Start("BS_AddNotification")
                net.WriteString(tostring(self.liveCount.detections))
                net.WriteString(tostring(self.liveCount.warnings))
                net.Send(ply)
            end
        end
    end

    -- Create directories
    if infoIn.folder and not file.Exists(logFolder, "DATA") then
        file.CreateDir(logFolder)
    end

    -- Update type log life
    file.Append(typeFile, fullLog)

    -- Create log file
    if logFile then 
        file.Write(logFile, fullLog)
    end

    -- Copy Lua file
    if luaFile and infoIn.file and file.Exists(infoIn.file, "GAME") then
        local f = file.Open(infoIn.file, "r", "GAME")
        if not f then return end

        file.Write(luaFile, f:Read(f:Size()))

        f:Close()
    end

    -- Create snippet file
    if snippetFile and infoIn.snippet then
        file.Write(snippetFile, infoIn.snippet)
    end
end

-- Print scan detections to console
function BS:Report_ScanDetection(resultString, resultsList, results)
    if resultsList ~= results.lowRisk or self.scanner.printLowRisk then
        for lineCount, lineText in pairs(string.Explode("\n", resultString)) do
            if lineCount == 1 then
                local lineInfo = resultsList == results.highRisk and { " [HIGH] ", self.colors.highRisk } or -- Linux compatible colors
                                 resultsList == results.mediumRisk and { " [Medium] ", self.colors.mediumRisk } or
                                 resultsList == results.lowRisk and { " [low] ", self.colors.lowRisk }

                MsgC(lineInfo[2], "▉▉▉", self.colors.value, lineInfo[1] .. lineText .. "\n")
            else
                print(lineText)
            end
        end
    end
end

-- Print scan results to console and file
function BS:Report_ScanResults(results)
    MsgC(self.colors.header, "\nScan results:\n\n")

    MsgC(self.colors.key, "    Files scanned: ", self.colors.value, results.totalScanned .. "\n\n")

    MsgC(self.colors.key, "    Detections:\n")
    MsgC(self.colors.key, "      | High-Risk   : ", self.colors.value, #results.highRisk .. "\n")
    MsgC(self.colors.key, "      | Medium-Risk : ", self.colors.value, #results.mediumRisk .. "\n") 
    MsgC(self.colors.key, "      | Low-Risk    : ", self.colors.value, #results.lowRisk .. "\n")
    MsgC(self.colors.key, "      | Discarded   : ", self.colors.value, results.discarded .. "\n\n")

    local timestamp = os.time()
    local date = os.date("%Y-%m-%d", timestamp)
    local time = os.date("%Hh %Mm %Ss", timestamp)
    local logFile = self.folder.data .. "/Scan_" .. date .. "_(" .. time .. ").txt"

    local topSeparator = "\n\n\n\n\n"
    local bottomSeparator = "\n-----------------------------------------------------------------------------------\n\n"

    local message = [[
[HIGH RISK detections] ]] .. bottomSeparator ..[[
]] .. table.ToString(results.highRisk, "Results", true) .. [[
]] .. topSeparator .. "[MEDIUM RISK detections]" .. bottomSeparator .. [[
]] .. table.ToString(results.mediumRisk, "Results", true) .. [[
]] .. topSeparator .. "[LOW RISK detections]" .. bottomSeparator .. [[
]] .. table.ToString(results.lowRisk, "Results", true)

    file.Append(logFile, message)

    MsgC(self.colors.key, "    Saved as: ", self.colors.value, "data/" .. logFile .. "\n\n")

    MsgC(self.colors.message, "Check the log file for more information.\n\n")
end