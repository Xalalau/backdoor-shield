--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

-- Check if a file isn't suspicious at first 
local function IsSuspicious(str, notSuspect)
	for k,v in pairs(notSuspect) do
		if string.find(str, v, nil, true) then
			return false
		end
	end

	return true
end

local function CheckTraceWhitelist(trace, whitelistTraceErrors)
	local found = false

	if trace then
		for _,allowed in pairs(whitelistTraceErrors)do
			if string.find(trace, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

local function CheckFilesWhitelist(str, whitelistFiles)
	local found = false

	if trace then
		if str and #whitelistFiles > 0 then
			for _,allowed in pairs(whitelistFiles)do
				if string.find(str, allowed, nil, true) then
					found = true

					break
				end
			end
		end
	end

	return found
end

local function ProcessList(list, list2, str, trace, bs)
	for k,v in pairs(list) do
		if string.find(string.gsub(str, " ", ""), v, nil, true) and
		   not CheckTraceWhitelist(trace, bs.whitelistTraceErrors) and
		   not CheckFilesWhitelist(trace, bs.whitelistFiles) then

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
function BS:Scan_String(trace, str, blocked, warning)
	if not str then return end

	local IsSuspicious = IsSuspicious(str, self.notSuspect)

	if not IsSuspicious then
		IsSuspicious = ProcessList(self.blacklistHigh, nil, str, trace, self) or
					   ProcessList(self.blacklistMedium, nil, str, trace, self) or
					   ProcessList(self.suspect, nil, str, trace, self)
	end

	if IsSuspicious and blocked then
		if blocked[1] then
			ProcessList(self.blacklistHigh, blocked[1], str, trace, self)
			ProcessList(self.blacklistHigh_Suspect, blocked[1], str, trace, self)
		end

		if blocked[2] then
			ProcessList(self.blacklistMedium, blocked[2], str, trace, self)
			ProcessList(self.blacklistMedium_Suspect, blocked[2], str, trace, self)
		end
	end

	if IsSuspicious and warning then
		ProcessList(self.suspect, warning, str, trace, self)
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

-- Process recusively the files inside the aimed folders according to our white, black and suspect lists
-- Low risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:Scan_Folders(args)
	local highRisk = {}
	local mediumRisk = {}
	local lowRisk = {}

	local lowRiskFiles_Aux = {}

	-- Results from addons folder take precedence
	-- The addons folder will not be scanned if args is set
	local addonsFolder = {}
	local addonsFolderScan = #args == 0 and true

	local folders = not addonsFolderScan and args or {
		"lua",
		"gamemode",
		"data",
	}

	for k,v in pairs(folders) do
		folders[k] = string.gsub(v, "\\", "/")
		if string.sub(folders[k], -1) == "/" then
			folders[k] = folders[k]:sub(1, #v - 1)
		end
	end

	-- Easy way to check low risk files (values as table indexes)
	for _,v in pairs(self.lowRiskFiles) do
		lowRiskFiles_Aux[v] = true
	end

	-- Scan a folder
	local function ParteDir(dir)
		if dir == "data/" .. self.FOLDER.DATA then
			return
		end

		local files, dirs = file.Find( dir.."*", "GAME" )

		if not dirs then
			return
		end

		for _, fdir in pairs(dirs) do
			if fdir ~= "/" then -- We can get a / if the start from the root
				ParteDir(dir .. fdir .. "/")
			end
		end

		for k,v in pairs(files) do
			local path = dir .. v

			if not addonsFolder[path] then
				local ext = string.GetExtensionFromFilename(v)
				local blocked = {{}, {}}
				local warning = {}
				local pathAux = path

				if v == self.FILENAME then
					return
				end

				-- Convert the path of a file in the addons folder to a game's mounted one.
				-- I'll save it and prevent us from scanning twice.
				if addonsFolderScan then
					local correctPath = ""

					for k,v in pairs(string.Explode("/", path)) do
						if k > 2 then
							correctPath = correctPath .. "/" .. v
						end
					end

					correctPath = string.sub(correctPath, 2, string.len(correctPath))
					pathAux = correctPath
					addonsFolder[correctPath] = true
				end

				-- Ignore whitelisted files
				if CheckFilesWhitelist(pathAux, self.whitelistFiles) then
					return 
				end

				-- Scanning
				self:Scan_String(nil, file.Read(path, "GAME"), blocked, warning)

				local resultString = ""
				local resultTable
				local results

				-- Build, print and stock the result
				if #blocked[1] > 0 or #blocked[2] > 0 or #warning > 0 then
					resultString = path

					-- Files inside low risk folders
					for _,v in pairs(self.lowRiskFolders) do
						start = string.find(pathAux, v, nil, true)
						if start == 1 then
							results = lowRisk

							break
						end
					end

					-- or if it's not a low risk folder
					if not results then
						-- non Lua files are VERY unsafe
						if ext ~= "lua" then
							results = highRisk
						-- or check if it's a low risk file
						elseif lowRiskFiles_Aux[pathAux] then
							results = lowRisk
						-- or set the risk based on the detection precedence
						else
							if #blocked[1] > 0 then results = highRisk end
							if not results and #blocked[2] > 0 then results = mediumRisk end
							if not results and #warning > 0 then results = lowRisk end
						end
					end

					-- If we don't have a high risk but there are three or more medium risk detections, set to high risk
					if results ~= highRisk and #blocked[2] > 2 then
						results = highRisk
					end

					-- If we have a low risk but there are two or more high risk detections, set to medium risk
					if results == lowRisk and #blocked[1] >= 2 then
						results = mediumRisk
					end

					-- Build
					resultString = resultString .. JoinResults(blocked[1], "[!!]")
					resultString = resultString .. JoinResults(blocked[2], "[!]")
					resultString = resultString .. JoinResults(warning, "[.]")
					resultString = resultString .. "\n"

					-- Print
					if results ~= lowRisk then
						if results == highRisk then
							print("[[[ HIGH RISK ]]] ---------------------------------------------------------------------------- <<<")
						end

						print(resultString)
					end

					-- Stock
					table.insert(results, resultString)
				end
			end
		end 
	end

	print("\n\n -------------------------------------------------------------------")
	print(self.ALERT .. " Scanning GMod and all the mounted contents...\n")

	-- Manually installed addons have a higher chance of infection.
	-- Results from the addons folder always have the the full file paths
	-- To avoid scanning a file twice, I record what we're doing and compare later.
	if addonsFolderScan then
		ParteDir("addons/")
		addonsFolderScan = false
	end

	-- Scan the other selected folders
	for _,folder in pairs(folders) do
		if folder == "" or file.Exists(folder .. "/", "GAME") then
			ParteDir(folder == "" and folder or folder .. "/")
		end
	end

	self:Report_Folder(highRisk, mediumRisk, lowRisk)

	print("\nLow risk results: ", tostring(#lowRisk))
	print("Check the log for more informations.\n")
	print("------------------------------------------------------------------- \n")
end