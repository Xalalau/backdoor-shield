--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Note: I'm using string.find() without patterns. Due to the number of scans they get too intensive.

-- Check if a file isn't suspect (at first)
-- Mainly used to remove false positives from binary files
local function IsSourceSuspicious(BS, str, ext)
    if BS.scannerDangerousExtensions_EZSearch[ext] then return true end

    for k, term in ipairs(BS.scanner.notSuspicious) do
        if string.find(str, term, nil, true) then
            return false
        end
    end

    return true
end
table.insert(BS.locals, IsSourceSuspicious)

-- Process the file contents according to the blacklists
local function ScanSource(BS, src, ext, detected)
    if not isstring(src) then return end
    
    local IsSourceSuspicious = IsSourceSuspicious(BS, src, ext)
    if not IsSourceSuspicious then
        detected[2] = detected[2] + BS.scanner.counterWeights.notSuspicious
    end

    local foundTerms = BS:Scan_Blacklist(BS, src, BS.scannerBlacklist_FixedFormat)
    for term, linesTab in pairs(foundTerms) do
        local lineNumbers = {}
        local totalFound = 0

        for k, lineTab in ipairs(linesTab) do
            table.insert(lineNumbers, lineTab.lineNumber)
            totalFound = totalFound + lineTab.count
        end

        detected[2] = detected[2] + BS.scanner.blacklist[term] -- Adding multiple weights here will generate a lot of false positives
        table.insert(detected[1], { term, lineNumbers, totalFound })
    end

    if detected[2] < BS.scanner.thresholds.low then
        detected[2] = 1 -- The detection will be discarded
    end
end
table.insert(BS.locals, ScanSource)

-- Build a message with the detections
local function JoinResults(BS, detected)
    local resultString = ""

    if #detected > 0 then
        for k, termTab in ipairs(detected) do
            local isInvisibleCharacter = BS.UTF8InvisibleChars[termTab[1]]
            local weight = isInvisibleCharacter and BS.scanner.extraWeights.invalidChar or BS.scanner.blacklist[termTab[1]]
            local prefix
            local lines
            local indentation = "     "

            if isInvisibleCharacter then
                termTab[1] = "Invisible character " .. termTab[1] .. " (Decimal UTF-16BE)"
            end

            if termTab[2] then
                if BS.scanner.printLines then
                    lines = "\n\n" .. indentation .. indentation
                    for k, lineNumber in SortedPairsByValue(termTab[2]) do
                        lines = lines .. lineNumber .. " "
                    end
                    lines = lines .. "\n"
                end

                weight = weight * termTab[3]
            end

            if weight >= BS.scanner.thresholds.high then
                prefix = "[!!]"
            elseif weight >= BS.scanner.thresholds.medium then
                prefix = "[!]"
            else
                prefix = "[.]"
            end

            resultString = resultString .. "\n" .. indentation .. prefix .. " " .. termTab[1] .. (lines or "")
        end
    end

    return resultString
end
table.insert(BS.locals, JoinResults)

-- Make the coroutine wait so the text can be printed to the console
local function WaitALittle()
    local co = coroutine.running()
    local doLoop = true

    timer.Simple(0.03, function()
        doLoop = false
        local succeeded, errors = coroutine.resume(co)
        if not succeeded then
            print(errors)
        end
    end)

    while doLoop do
        coroutine.yield()
    end
end
table.insert(BS.locals, WaitALittle)

-- Scan a folder
local bsDataFolder = "data/" .. BS.folder.data .. "/"
local bsLuaFolder = "lua/" .. BS.folder.lua .. "/"
local function StartRecursiveFolderRead(BS, dir, results, addonsFolderFiles, extensions, isAddonsFolder)
    -- Check for the addons folder and keep the value to the subfolders
    if dir == "addons/" then
        isAddonsFolder = true
    end

    -- Ignore bs data folder
    if dir == bsDataFolder then
        return
    end

    local files, subDirs = file.Find(dir .. "*", "GAME")

    -- Ignore nil folders
    if not subDirs then
        return
    -- Ignore our own folders
    elseif string.find(dir, bsLuaFolder, nil, true) or string.find(dir, "backdoor-shield", nil, true) then
        if BS.scanner.ignoreBSFolders then
            return
        end
    end

    -- Ignore whitelisted folders
    if BS:Scan_Whitelist(dir, BS.scanner.whitelists.folders) then
        return
    end

    -- Check directories
    for _, subDir in ipairs(subDirs) do
        if subDir ~= "/" then
            StartRecursiveFolderRead(BS, dir .. subDir .. "/", results, addonsFolderFiles, extensions, isAddonsFolder)
        end
    end

    -- Check if the dir is a loose detection
    local isLooseFolder = false

    for _, looseFolder in ipairs(BS.scanner.loose.folders) do
        local start = string.find(dir, looseFolder, nil, true)

        if start == 1 then
            isLooseFolder = true
            break
        end
    end

    -- Check files
    for k, _file in ipairs(files) do
        local path = dir .. _file

        if addonsFolderFiles[path] then continue end

        local ext = string.GetExtensionFromFilename(_file)
        local detected = {{}, 0}

        -- Ignore invalid extensions
        if extensions then
            local isValidExt = false

            for k, validExt in ipairs(extensions) do
                if ext == validExt then
                    isValidExt = true
                    break
                end
            end

            if not isValidExt then continue end
        end

        -- Ignore whitelisted files
        if BS:Scan_Whitelist(path, BS.scanner.whitelists.files) then
            continue
        end

        -- Loose folder counterweight
        if isLooseFolder then
            detected[2] = detected[2] + BS.scanner.counterWeights.loose
        end

        -- Convert a addons/ path to a lua/ path and save the result to prevent a repeated scanning later
        if isAddonsFolder then
            local path = BS:Utils_ConvertAddonPath(path, true)
            addonsFolderFiles[path] = true
        end

        -- Print status after every cetain number of scanned files
        results.totalScanned = results.totalScanned + 1
        if results.totalScanned == results.lastTotalPrinted + 500 then
            MsgC(BS.colors.message, results.totalScanned .. " files scanned...\n\n")
            results.lastTotalPrinted = results.totalScanned
            WaitALittle()
        end

        -- Check the source
        local src = file.Read(path, "GAME")

        if BS:Scan_Whitelist(src, BS.scanner.whitelists.snippets) then
            continue
        end

        local foundChars = BS:Scan_Characters(BS, src, ext)
        for invalidCharName, linesTab in pairs(foundChars) do
            local lineNumbers = {}
            local totalFound = 0

            for k, lineTab in ipairs(linesTab) do
                table.insert(lineNumbers, lineTab.lineNumber)
                totalFound = totalFound + lineTab.count
            end

            detected[2] = detected[2] + BS.scanner.extraWeights.invalidChar -- Adding multiple weights here will generate a lot of false positives
            table.insert(detected[1], { invalidCharName, lineNumbers, totalFound })
        end

        ScanSource(BS, src, ext, detected)

        local resultString = ""
        local resultsList

        -- Build, print and stock the result
        if #detected[1] > 0 then
            local isLooseFile = BS.scannerLooseFiles_EZSearch[path] and true or false

            -- Loose file counterweight
            if isLooseFile then
                detected[2] = detected[2] + BS.scanner.counterWeights.loose
            end

            -- Discard result if it's from file with only BS.scanner.suspect_suspect detections
            if BS.scanner.discardUnderLowRisk and detected[2] < BS.scanner.thresholds.low then
                results.discarded = results.discarded + 1
                continue
            end

            -- Non Lua files extra weight
            if ext ~= "lua" then
                detected[2] = detected[2] + BS.scanner.extraWeights.notLuaFile
            end

            -- Define detection list
            if detected[2] >= BS.scanner.thresholds.high then
                resultsList = results.highRisk
            elseif detected[2] >= BS.scanner.thresholds.medium then
                resultsList = results.mediumRisk
            else
                resultsList = results.lowRisk
            end

            -- Build result message
            resultString = path
            resultString = resultString .. JoinResults(BS, detected[1])
            resultString = resultString .. "\n"

            -- Report
            BS:Report_ScanDetection(resultString, resultsList, results)
            WaitALittle()

            -- Stack result
            table.insert(resultsList, resultString)
        end
    end 
end
table.insert(BS.locals, StartRecursiveFolderRead)

-- Remove back slashs and slashes from ends
local function SanitizeSlashes(folders)
    for k, folder in pairs(folders) do
        folders[k] = string.gsub(folder, "\\", "/")

        if string.sub(folders[k], 1, 1) == "/" then
            folders[k] = folders[k]:sub(2, #folder)
        end

        if string.sub(folders[k], -1) == "/" then
            folders[k] = folders[k]:sub(1, #folder - 1)
        end
    end
end
table.insert(BS.locals, ProcessBars)

-- Process the files recusively inside the aimed folders according to our white, black and suspect lists
-- Note: Low-risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:Scanner_Start(args, extensions)
    -- All results
    local results = {
        totalScanned = 0,
        lastTotalPrinted = 0,
        highRisk = {},
        mediumRisk = {},
        lowRisk = {},
        discarded = 0
    }

    -- List of scanned files in addons folder. It forces the scanner to skip the same files inside lua folder
    local addonsFolderFiles = {}

    -- Select custom folders or a list of default folders
    local folders = #args > 0 and args or self.scanner.foldersToScan

    SanitizeSlashes(folders)

    if not folders then
        MsgC(self.colors.message, "\n" .. self.alert .. " no folders selected.\n\n")
        return
    end

    -- Deal with bars
    for k, folder in ipairs(folders) do
        folders[k] = string.gsub(folder, "\\", "/")
        if string.sub(folders[k], 1, 1) == "/" then
            folders[k] = folders[k]:sub(2, #folder)
        end
        if string.sub(folders[k], -1) == "/" then
            folders[k] = folders[k]:sub(1, #folder - 1)
        end
    end

    -- If no folders are selected, we're going to use the default ones from foldersToScan
    -- In both cases we are going to put "addons" in the first position if it's present, because:
    --   Manually installed addons have a much higher chance of infection;
    --   Results from the addons folder always have the the full file paths;
    --   I record what we're doing and compare later to avoid scanning a file twice.
    local i = 2
    local foldersAux = {}
    for _,folder in ipairs(folders) do
        if folder == "addons" then
            foldersAux[1] = folder
            i = i - 1
        else
            foldersAux[i] = folder
        end

        i = i + 1
    end
    if not foldersAux[1] then
        foldersAux[1] = foldersAux[#foldersAux]
        foldersAux[#foldersAux] = nil
    end
    folders = foldersAux

    MsgC(self.colors.header, "\n" .. self.alert .. " Scanning GMod and all the mounted contents...\n\n\n")

    -- Note: The coroutine is used so that the scanner can pause and display results in real time - Multiplayer only
    local co = coroutine.create(function()
        local isThinkHibernationInitiallyOn = GetConVar("sv_hibernate_think"):GetBool()

        if not isThinkHibernationInitiallyOn then
            RunConsoleCommand("sv_hibernate_think", "1")
        end

        WaitALittle()

        -- Start scanning folders
        for _,folder in ipairs(folders) do
            if folder == "" or file.Exists(folder .. "/", "GAME") then
                StartRecursiveFolderRead(self, folder == "" and folder or folder .. "/", results, addonsFolderFiles, extensions)
            else
                MsgC(self.colors.message, "\n" .. self.alert .. " Folder not found: " .. folder .. "\n\n")
            end
        end

        if not isThinkHibernationInitiallyOn then
            RunConsoleCommand("sv_hibernate_think", "0")
        end

        -- Console final log
        self:Report_ScanResults(results)
    end)

    coroutine.resume(co)
end