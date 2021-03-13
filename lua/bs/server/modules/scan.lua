--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Check if a file isn't suspicious at first 
local function IsSuspicious(str, ext, dangerousExtensions, notSuspect)
	if dangerousExtensions[ext] then return true end

	for k,v in pairs(notSuspect) do
		if string.find(str, v, nil, true) then
			return false
		end
	end

	return true
end

local function CheckWhitelist(str, whitelist)
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

local function ProcessList(BS, trace, str, IsSuspicious, list, list2)
	for k,v in pairs(list) do
		if string.find(string.gsub(str, " ", ""), v, nil, true) and
		   not CheckWhitelist(trace, BS.whitelistTraceErrors) and
		   not CheckWhitelist(str, BS.whitelistContents) then

			if v == "=_G" then -- Hack: recheck _G with some spaces
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

-- Process a string according to our white, black and suspect lists
function BS:Scan_String(trace, str, ext, blocked, warning, ignore_suspect)
	if not isstring(str) then return end

	local IsSuspicious = IsSuspicious(str, ext, self.DANGEROUSEXTENTIONS_Check, self.notSuspect)

	if not IsSuspicious then
		IsSuspicious = ProcessList(self, trace, str, IsSuspicious, self.blacklistHigh) or
					   ProcessList(self, trace, str, IsSuspicious, self.blacklistMedium) or
					   ProcessList(self, trace, str, IsSuspicious, self.suspect)
	end

	if IsSuspicious and blocked then
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
	end

	if IsSuspicious and warning then
		ProcessList(self, trace, str, IsSuspicious, self.suspect, warning)
		if not ignore_suspect then
			ProcessList(self, trace, str, IsSuspicious, self.suspect_suspect, warning)
		end
	end

	return blocked, warning
end

-- Build a message with the detections in a file
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

-- Scan a folder
local function RecursiveScan(BS, dir, results, cfgs, forceIgnore)
	if dir == "data/" .. BS.FOLDER.DATA then
		return
	end

	local files, dirs = file.Find(dir.."*", "GAME")
	local forceLowRisk = false

	-- Ignore nil folders
	if not dirs then
		return
	-- List lua/bs/ results as low risk
	elseif string.find(dir, "lua/" .. BS.FOLDER.LUA, nil, true) == 1 then
		forceLowRisk = true
	-- Ignore our own addons folder(s) results
	elseif not dirs or
		dir == "addons/" .. BS.FOLDER.DATA or
		dir == "addons/" .. string.gsub(BS.FOLDER.DATA, "/", "") .. "-master/" then

		forceIgnore = true
	end

	-- Check directories
	for _, fdir in pairs(dirs) do
		if fdir ~= "/" then -- We can get a / if we start from the root
			RecursiveScan(BS, dir .. fdir .. "/", results, cfgs, forceIgnore)
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

			-- Convert the path of a file in the addons folder to a game's mounted one.
			-- I'll save it and prevent us from scanning twice.
			if cfgs.addonsFolderScan or forceIgnore then
				local correctPath = BS:Utils_ConvertAddonPath(path, true)

				pathAux = correctPath
				cfgs.addonsFolder[correctPath] = true

				if forceIgnore then
					return
				end
			end

			-- Ignore whitelisted contents
			if CheckWhitelist(pathAux, BS.whitelistContents) then
				return 
			end

			-- Print status
			results.totalScanned = results.totalScanned + 1
			if results.totalScanned == results.lastTotalPrinted + 500 then
				print("\n" .. results.totalScanned .. " files scanned...\n")
				results.lastTotalPrinted = results.totalScanned
			end

			-- Scanning
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

				-- If it's a non Lua file with only one suspect detection or a suspect detection from
				-- BS.suspect and other from BS.suspect_suscpec, discard it
				if rext ~= "lua" and (#blocked[1] + #blocked[2] == 0) and (#warning == 1 or #warning == 2 and notImportant) then
					return
				end

				-- Default risks:

				-- Force low risk
				if forceLowRisk then
					resultsList = results.lowRisk
				end

				-- Files inside low risk folders
				if not resultsList then
					for _,v in pairs(BS.lowRiskFolders) do
						local start = string.find(pathAux, v, nil, true)
						if start == 1 then
							resultsList = results.lowRisk

							break
						end
					end
				end

				-- Or if it's not a low risk folder
				-- let's set a default risk to modify later
				if not resultsList then
					-- non Lua detections are VERY unsafe
					if ext ~= "lua" then
						resultsList = results.highRisk
					-- or check if it's a low risk file
					elseif BS.lowRiskFiles_Check[pathAux] then
						resultsList = results.lowRisk
					-- or set the risk based on the detection precedence
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

-- Process the files recusively inside the aimed folders according to our white, black and suspect lists
-- Low risk files will be reported in the logs as well, but they won't flood the console with warnings
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
		addonsFolder = {}, 	-- Note: results from addons folder have precedence.
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
	print(self.ALERT .. " Scanning GMod and all the mounted contents...\n")

	-- Manually installed addons have a much higher chance of infection.
	-- Results from the addons folder always have the the full file paths
	-- To avoid scanning a file twice, I record what we're doing and compare later.
	if cfgs.addonsFolderScan then
		RecursiveScan(self, "addons/", results, cfgs)
		cfgs.addonsFolderScan = false
	end

	-- Scan the other selected folders
	for _,folder in pairs(folders) do
		if folder == "" or file.Exists(folder .. "/", "GAME") then
			RecursiveScan(self, folder == "" and folder or folder .. "/", results, cfgs)
		end
	end

	print("\nTotal files scanned: " .. results.totalScanned)

	self:Report_Folder(results.highRisk, results.mediumRisk, results.lowRisk)

	print("\nLow risk results: ", tostring(#results.lowRisk))
	print("Check the log for more informations.\n")
	print("------------------------------------------------------------------- \n")
end