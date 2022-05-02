--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Note: I'm using string.find() without patterns. Due to the number of scans they get too intensive.

-- Find whitelisted detetections
local function CheckWhitelist(str, whitelist)
	local found = false

	if str and #whitelist > 0 then
		for _, allowed in ipairs(whitelist)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end
table.insert(BS.locals, CheckWhitelist)

-- Try to find Lua files with obfuscations
-- ignorePatterns is used to scan files that already has other detections
local function CheckCharset(str, ext, list, ignorePatterns)
	if str and ext == "lua" then
		local lines, count = "", 0

		-- Search line by line, so we have the line numbers
		for lineNumber,lineText in ipairs(string.Explode("\n", str, false)) do
			-- Check char by char
			for _,_char in ipairs(string.ToTable(lineText)) do
				-- If we find a suspect character, take a closer look
				if utf8.force(_char) ~= _char then
					-- Let's eliminate as many false positives as possible by searching for common backdoor patterns
					if ignorePatterns or (
					   string.find(lineText, "function", nil, true) or
					   string.find(lineText, "return", nil, true) or
					   string.find(lineText, "then", nil, true) or
					   string.find(lineText, " _G", nil, true) or
					   string.find(lineText, "	_G", nil, true)) then

						count = count + 1
						lines = lines .. lineNumber .. "; "
					end
					break
				end
			end
		end

		if count > 0 then
			local plural = count > 1 and "s" or ""
			table.insert(list, "Uncommon Charset, line" .. plural .. ": " .. lines)
		end
	end
end
table.insert(BS.locals, CheckCharset)

-- Process a string according to our white, black and suspect lists
local function ProcessList(BS, str, IsSuspect, list, list2)
	for k, listValue in pairs(list) do
		if string.find(string.gsub(str, " ", ""), listValue, nil, true) then
			if listValue == "=_G" or listValue == "=_R" then -- Since I'm not using patterns, I do some extra checks on _G and _R to avoid false positives.
				local check = string.gsub(str, "%s+", " ")
				local strStart, strEnd = string.find(check, listValue, nil, true)
				if not strStart then
					strStart, strEnd = string.find(check, listValue == "=_G" and "= _G" or "= _R", nil, true)
				end

				local nextChar = check[strEnd + 1] or "-"

				if nextChar == " " or nextChar == "\n" or nextChar == "\r\n" then
					if not IsSuspect then
						return true
					else
						table.insert(list2, listValue)
					end
				end
			else
				if not IsSuspect then
					return true
				else
					table.insert(list2, listValue)
				end
			end
		end
	end
end
table.insert(BS.locals, ProcessList)

-- Process a string passed by argument
function BS:Scan_Argument(str, funcName, detected, warning)
	if not isstring(str) then return end
	if CheckWhitelist(str, self.whitelists.snippets) then return end

    local IsSuspect = "true"

	if detected then
        -- Check stack blacklists
        local protectStack = self.live.control[funcName].protectStack

        if protectStack then
            for _,stackBanListName in ipairs(protectStack) do
                ProcessList(self, str, IsSuspect, self.live.blacklists.functions[stackBanListName], detected)
            end
        end

        CheckCharset(str, "lua", detected, true)
        ProcessList(self, str, IsSuspect, self.live.blacklists.snippets, detected)
        ProcessList(self, str, IsSuspect, self.live.blacklists.cvars, detected)
    end

	if warning then
    end

	return
end

-- Check if a file isn't suspect (at first)
-- Mainly used to remove false positives from binary files
local function IsSuspectPath(BS, str, ext)
	if BS.scannerDangerousExtensions_Check[ext] then return true end

	for k, term in ipairs(BS.scanner.notSuspect) do
		if string.find(str, term, nil, true) then
			return false
		end
	end

	return true
end
table.insert(BS.locals, IsSuspectPath)

-- Process a string according to our white, black and suspect lists
local function CheckSource(BS, path, ext, detected)
	local src = file.Read(path, "GAME")

	if not isstring(src) then return end
	if CheckWhitelist(src, BS.whitelists.snippets) then return end

	local IsSuspect = IsSuspectPath(BS, src, ext)
	if not IsSuspect then
		detected[2] = detected[2] + BS.scanner.counterWeights.notSuspect
	end

	for k, term in ipairs(BS.scannerBlacklist) do
		if string.find(string.gsub(src, " ", ""), term, nil, true) then
			if term == "=_G" or term == "=_R" then -- Since I'm not using patterns, I do some extra checks on _G and _R to avoid false positives.
				src = string.gsub(src, "%s+", " ")
				local strStart, strEnd = string.find(src, term, nil, true)

				if not strStart then
					strStart, strEnd = string.find(src, term == "=_G" and "= _G" or "= _R", nil, true)
				end

				local nextChar = src[strEnd + 1] or "-"

				if nextChar == " " or nextChar == "\n" or nextChar == "\r\n" then
					table.insert(detected[1], term)
					detected[2] = detected[2] + BS.scanner.blacklist_check[term]
				end
			else
				table.insert(detected[1], term)
				detected[2] = detected[2] + BS.scanner.blacklist_check[term]
			end
		end
	end

	if detected[2] < BS.scanner.thresholds.low then
		detected[2] = 1 -- The detection will be discarded
	end
end
table.insert(BS.locals, CheckSource)

-- Build a message with the detections
local function JoinResults(BS, detected)
	local resultString = ""

	if #detected > 0 then
		for k, term in ipairs(detected) do
			local weight = BS.scanner.blacklist_check[term]
			local prefix

			if weight >= BS.scanner.thresholds.high then
				prefix = "[!!]"
			elseif weight >= BS.scanner.thresholds.medium then
				prefix = "[!]"
			else
				prefix = "[.]"
			end

			resultString = resultString .. "\n     " .. prefix .. " " .. term

			if v == "‪" then
				resultString = resultString .. " Invisible Character"
			end
		end
	end

	return resultString
end
table.insert(BS.locals, JoinResults)

-- Scan a folder
local bsDataFolder = "data/" .. BS.folder.data .. "/"
local bsLuaFolder = "lua/" .. BS.folder.lua .. "/"
local function StartRecursiveFolderScan(BS, dir, results, addonsFolderFiles, extensions, isAddonsFolder)
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
	if CheckWhitelist(dir, BS.whitelists.folders) then
		return
	end

	-- Check directories
	for _, subDir in ipairs(subDirs) do
		if subDir ~= "/" then
			StartRecursiveFolderScan(BS, dir .. subDir .. "/", results, addonsFolderFiles, extensions, isAddonsFolder)
		end
	end

	local isLooseFolder = BS:Trace_IsLoose(dir) -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!! Parar de usar o TRACE como se isso fosse inteligente! Fazer uma lib nova

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
		if CheckWhitelist(path, BS.whitelists.files) then
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
		end

		-- Scan file
		CheckSource(BS, path, ext, detected)

		local resultString = ""
		local resultsList

		-- Build, print and stock the result
		if #detected[1] > 0 then
			local isLooseFile = BS:Trace_IsLoose(dir) -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!! Parar de usar o TRACE como se isso fosse inteligente! Fazer uma lib nova

			-- Loose file counterweight
			if isLooseFile then
				detected[2] = detected[2] + BS.scanner.counterWeights.loose
			end

			-- Discard result if it's from file with only BS.scanner.suspect_suspect detections
			if BS.scanner.discardUnderLowRisk and detected[2] < BS.scanner.thresholds.low then
				results.discarded = results.discarded + 1
				continue
			end

			-- Add extra weight to non Lua files
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
			coroutine.yield()

			-- Stack result
			table.insert(resultsList, resultString)
		end
	end 
end
table.insert(BS.locals, StartRecursiveFolderScan)

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
function BS:Scan_Folders(args, extensions)
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
	for k, folder in pairs(folders) do
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

	-- Start scanning folders
	--   Note: The coroutine is used so that the scanner can pause and display results in real time - Multiplayer only
	local co = coroutine.create(function()
		coroutine.yield()

		for _,folder in ipairs(folders) do
			if folder == "" or file.Exists(folder .. "/", "GAME") then
				StartRecursiveFolderScan(self, folder == "" and folder or folder .. "/", results, addonsFolderFiles, extensions)
			else
				MsgC(self.colors.message, "\n" .. self.alert .. " Folder not found: " .. folder .. "\n\n")
			end
		end
	end)

	local isThinkHibernationInitiallyOn = GetConVar("sv_hibernate_think"):GetBool()

	if not isThinkHibernationInitiallyOn then
		RunConsoleCommand("sv_hibernate_think", "1")
	end

	hook.Add("Think", "BSFileScanner", function()
		if co then
			if coroutine.status(co) == "suspended" then
				coroutine.resume(co)
			else
				co = nil
			end
		end

		if not co then
			hook.Remove("Think", "BSFileScanner")

			if not isThinkHibernationInitiallyOn then
				RunConsoleCommand("sv_hibernate_think", "0")
			end

			-- Console final log
			self:Report_ScanResults(results)
		end
	end)
end