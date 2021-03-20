--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- !! WARNING !! I'm using string.find() with patterns disabled in some functions!
-- I could enable them running string.PatternSafe() but this calls string.gsub()
-- with 13 pattern escape replacements and my scanner is already intensive enouth.

-- Find whitelisted detetections
function BS:Scan_CheckWhitelist(str, whitelist)
	local found = false

	if str and #whitelist > 0 then
		for _,allowed in pairs(whitelist)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

-- Check if a file isn't suspicious (at first)
local function IsSuspicious(str, ext, dangerousExtensions, notSuspect)
	if dangerousExtensions[ext] then return true end

	for k,v in pairs(notSuspect) do
		if string.find(str, v, nil, true) then
			return false
		end
	end

	return true
end
table.insert(BS.locals, IsSuspicious)

-- Try to find Lua files with obfuscations
-- ignorePatterns is used to scan files that already has other detections
local function CheckCharset(str, ext, list, ignorePatterns)
	if str and ext == "lua" then
		local lines, count = "", 0

		-- Search line by line, so we have the line numbers
		for lineNumber,lineText in ipairs(string.Explode("\n", str, false)) do
			-- Check char by char
			for _,_char in ipairs(string.ToTable(lineText)) do
				-- If we find suspicious character, take a closer look
				if utf8.force(_char) ~= _char then
					-- Let's eliminate as many false positives as possible by searching for common backdoor patterns
					if ignorePatterns or (
					   string.find(lineText, "function") or
					   string.find(lineText, "return") or
					   string.find(lineText, "then") or
					   string.find(lineText, " _G") or
					   string.find(lineText, "	_G")) then

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
local function ProcessList(BS, trace, str, IsSuspicious, list, list2)
	for k,v in pairs(list) do
		if string.find(string.gsub(str, " ", ""), v, nil, true) and
		   not BS:Scan_CheckWhitelist(trace, BS.whitelistTraceErrors) and
		   not BS:Scan_CheckWhitelist(str, BS.whitelistSnippets) then

			if v == "=_G" then -- Since I'm not using patterns, I do some extra checks on _G to avoid false positives.
				local check = string.gsub(str, "%s+", " ")
				local strStart, strEnd = string.find(check, "=_G", nil, true)
				if not strStart then
					strStart, strEnd = string.find(check, "= _G", nil, true)
				end

				local nextChar = check[strEnd + 1] or "-"

				if nextChar == " " or nextChar == "\n" or nextChar == "\r\n" then
					if not IsSuspicious then
						return true
					else
						table.insert(list2, v)
					end
				end
			else
				if not IsSuspicious then
					return true
				else
					table.insert(list2, v)
				end
			end
		end
	end
end
table.insert(BS.locals, ProcessList)

-- Process a string according to our white, black and suspect lists
function BS:Scan_String(trace, str, ext, blocked, warning, ignore_suspect)
	if not isstring(str) then return end

	-- Check if we are dealing with binaries
	local IsSuspicious = IsSuspicious(str, ext, self.dangerousExtensions_Check, self.notSuspect)

	-- Search for inappropriate terms for a binary but that are good for backdoors, then we won't be deceived
	if not IsSuspicious then
		IsSuspicious = ProcessList(self, trace, str, IsSuspicious, self.blacklistHigh) or
					   ProcessList(self, trace, str, IsSuspicious, self.blacklistMedium) or
					   ProcessList(self, trace, str, IsSuspicious, self.suspect)
	end

	if IsSuspicious and blocked then
		-- Search for blocked terms
		if blocked[1] then
			ProcessList(self, trace, str, IsSuspicious, self.blacklistHigh, blocked[1])
			if not ignore_suspect then
				ProcessList(self, trace, str, IsSuspicious, self.blacklistHigh_suspect, blocked[1])
			end
		end

		if blocked[2] then
			ProcessList(self, trace, str, IsSuspicious, self.blacklistMedium, blocked[2])
			if not ignore_suspect then
				ProcessList(self, trace, str, IsSuspicious, self.blacklistMedium_suspect, blocked[2])
			end
		end

		-- If blocked terms are found, reinforce the search with a charset check
		if #blocked[1] > 0 and #blocked[2] > 0 then
			CheckCharset(str, ext, blocked[1], true)
		end
	end

	if IsSuspicious and warning then
		-- Loof for suspect terms, wich are also good to reinforce results
		ProcessList(self, trace, str, IsSuspicious, self.suspect, warning)
		if not ignore_suspect then
			ProcessList(self, trace, str, IsSuspicious, self.suspect_suspect, warning)
		end
	end

	return blocked, warning
end

-- Build a message with the detections
local function JoinResults(tab, alert)
	local resultString = ""

	if #tab > 0 then
		for k,v in pairs(tab) do
			resultString = resultString .. "\n     " .. alert .. " " .. v

			if v == "‪" then
				resultString = resultString .. " Invisible Character"
			end
		end
	end

	return resultString
end
table.insert(BS.locals, JoinResults)

-- Scan a folder
local function RecursiveScan(BS, dir, results, cfgs, extensions, forceIgnore)
	if dir == "data/" .. BS.folder.data then
		return
	end

	local files, dirs = file.Find(dir.."*", "GAME")
	local forceLowRisk = false

	-- Ignore nil folders
	if not dirs then
		return
	-- List lua/bs/ results as low risk
	elseif string.find(dir, "lua/" .. BS.folder.lua) == 1 then
		forceLowRisk = true
	-- Ignore our own addons folder(s) results
	elseif not dirs or
		dir == "addons/" .. BS.folder.data or
		dir == "addons/" .. string.gsub(BS.folder.data, "/", "") .. "-master/" then

		forceIgnore = true
	end

	-- Check directories
	for _, fdir in pairs(dirs) do
		if fdir ~= "/" then -- We can get a / if we start from the root
			RecursiveScan(BS, dir .. fdir .. "/", results, cfgs, extensions, forceIgnore)
		end
	end

	-- Check files
	for k,v in pairs(files) do
		local path = dir .. v

		if not cfgs.addonsFolder[path] then
			local ext = string.GetExtensionFromFilename(v)
			local blocked = {{}, {}}
			local warning = {}
			local pathAux = path

			-- Filter by extension (if they are specified)
			-- Note: used by bs_scan_fast
			if extensions then
				local isValid = false

				for k,v in pairs(extensions) do
					if ext == v then
						isValid = true
						break
					end
				end

				if not isValid then return end
			end

			-- Convert a addons/ path to a lua/ path and save the result to prevent a repeated scanning later
			if cfgs.addonsFolderScan or forceIgnore then
				local correctPath = BS:Utils_ConvertAddonPath(path, true)

				pathAux = correctPath
				cfgs.addonsFolder[correctPath] = true

				if forceIgnore then
					return
				end
			end

			-- Ignore whitelisted contents
			if BS:Scan_CheckWhitelist(pathAux, BS.whitelistSnippets) then
				return 
			end

			-- Print status
			results.totalScanned = results.totalScanned + 1
			if results.totalScanned == results.lastTotalPrinted + 500 then
				print("\n" .. results.totalScanned .. " files scanned...\n")
				results.lastTotalPrinted = results.totalScanned
			end

			-- Scan file
			BS:Scan_String(nil, file.Read(path, "GAME"), ext, blocked, warning)

			local resultString = ""
			local resultsList

			-- Build, print and stock the result
			if #blocked[1] > 0 or #blocked[2] > 0 or #warning > 0 then

				-- Trash:

				-- If it's any file with only detections from BS.suspect_suspect, discard it
				local notImportant = 0

				if (#blocked[1] + #blocked[2] == 0)  then
					for k,v in pairs (warning) do
						if BS.suspect_suspect_Check[v] then
							notImportant = notImportant + 1
						end
					end

					if notImportant == #warning then
						return
					end
				end

				-- If it's a non Lua file with only one suspect detection or a suspect detection
				-- from BS.suspect and other from BS.suspect_suscpect, discard it
				if ext ~= "lua" and (#blocked[1] + #blocked[2] == 0) and (#warning == 1 or #warning == 2 and notImportant) then
					return
				end

				-- Default risks:

				-- Force low risk
				if forceLowRisk then
					resultsList = results.lowRisk
				end

				-- Check for files inside low risk folders
				if not resultsList then
					for _,v in pairs(BS.lowRiskFolders) do
						local start = string.find(pathAux, v)
						if start == 1 then
							resultsList = results.lowRisk

							break
						end
					end
				end

				-- Or if it's not a file in a low risk folder, set a default risk to maybe modify later
				if not resultsList then
					-- Non Lua detections, if they aren't false positive, are VERY unsafe
					if ext ~= "lua" then
						resultsList = results.highRisk
					-- Low risk file
					elseif BS.lowRiskFiles_Check[pathAux] then
						resultsList = results.lowRisk
					-- Set the risk based on the detection precedence
					else
						if #blocked[1] > 0 then resultsList = results.highRisk end
						if not resultsList and #blocked[2] > 0 then resultsList = results.mediumRisk end
						if not resultsList and #warning > 0 then resultsList = results.lowRisk end
					end
				end

				-- Other custom risks:

				if not forceLowRisk then
					-- If we don't have a high risk but there are three or more medium risk detections, set to high risk
					if resultsList ~= results.highRisk and #blocked[2] > 2 then
						resultsList = results.highRisk
					end

					-- If we have a low risk but there are two or more high risk detections, set to medium risk
					if resultsList == results.lowRisk and #blocked[1] >= 2 then
						resultsList = results.mediumRisk
					end
				end

				-- Build

				resultString = path
				resultString = resultString .. JoinResults(blocked[1], "[!!]")
				resultString = resultString .. JoinResults(blocked[2], "[!]")
				resultString = resultString .. JoinResults(warning, "[.]")
				resultString = resultString .. "\n"

				-- Print

				if resultsList ~= results.lowRisk then
					if resultsList == results.highRisk then
						print("[[[ HIGH RISK ]]] ---------------------------------------------------------------------------- <<<")
					end

					print(resultString)
				end

				-- Stack up

				table.insert(resultsList, resultString)
			end
		end
	end 
end
table.insert(BS.locals, RecursiveScan)

-- Process the files recusively inside the aimed folders according to our white, black and suspect lists
-- Note: Low risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:Scan_Folders(args, extensions)
	-- All results
	local results = {
		totalScanned = 0,
		lastTotalPrinted = 0,
		highRisk = {},
		mediumRisk = {},
		lowRisk = {}
	}

	local cfgs = {
		addonsFolder = {}, 	-- Note: results from addons folder take precedence over lua folder.
		addonsFolderScan = #args == 0 and true -- The addons folder will not be scanned if args is set
	}

	-- Select custom folders or a list of default folders
	local folders = not cfgs.addonsFolderScan and args or {
		"lua",
		"gamemode",
		"data",
	}

	-- Deal with bars
	for k,v in pairs(folders) do
		folders[k] = string.gsub(v, "\\", "/")
		if string.sub(folders[k], -1) == "/" then
			folders[k] = folders[k]:sub(1, #v - 1)
		end
	end

	print("\n\n -------------------------------------------------------------------")
	print(self.alert .. " Scanning GMod and all the mounted contents...\n")

	-- Scan addons folder
	-- Manually installed addons have a much higher chance of infection.
	-- Results from the addons folder always have the the full file paths
	-- To avoid scanning a file twice, I record what we're doing and compare later.
	if cfgs.addonsFolderScan then
		RecursiveScan(self, "addons/", results, cfgs, extensions)
		cfgs.addonsFolderScan = false
	end

	-- Scan the other selected folders
	for _,folder in pairs(folders) do
		if folder == "" or file.Exists(folder .. "/", "GAME") then
			RecursiveScan(self, folder == "" and folder or folder .. "/", results, cfgs, extensions)
		end
	end

	-- Console final log
	print("\nTotal files scanned: " .. results.totalScanned)

	self:Report_Folder(results.highRisk, results.mediumRisk, results.lowRisk)

	print("\nLow risk results: ", tostring(#results.lowRisk))
	print("Check the log for more informations.\n")
	print("------------------------------------------------------------------- \n")
end