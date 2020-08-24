--[[
    2020 Xalalau Xubilozo. MIT License
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

	if trace and #whitelistTraceErrors > 0 then
		for _,allowed in pairs(whitelistTraceErrors)do
			if string.find(trace, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

local function CheckContentsWhitelist(str, whitelistContents)
	local found = false

	if str and #whitelistContents > 0 then
		for _,allowed in pairs(whitelistContents)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

-- Process a string according to our white, black and suspect lists
function BS:Scan_String(trace, str, blocked, warning, ignore_suspect)
	if not isstring(str) then return end

	local IsSuspicious = IsSuspicious(str, self.notSuspect)

	local function ProcessList(list, list2)
		for k,v in pairs(list) do
			if string.find(string.gsub(str, " ", ""), v, nil, true) and
			   not CheckTraceWhitelist(trace, self.whitelistTraceErrors) and
			   not CheckContentsWhitelist(str, self.whitelistContents) then
	
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

	if not IsSuspicious then
		IsSuspicious = ProcessList(self.blacklistHigh) or
					   ProcessList(self.blacklistMedium) or
					   ProcessList(self.suspect)
	end

	if IsSuspicious and blocked then
		if blocked[1] then
			ProcessList(self.blacklistHigh, blocked[1])
			if not ignore_suspect then
				ProcessList(self.blacklistHigh_suspect, blocked[1])
			end
		end

		if blocked[2] then
			ProcessList(self.blacklistMedium, blocked[2])
			if not ignore_suspect then
				ProcessList(self.blacklistMedium_suspect, blocked[2])
			end
		end
	end

	if IsSuspicious and warning then
		ProcessList(self.suspect, warning)
		if not ignore_suspect then
			ProcessList(self.suspect_suspect, warning)
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

-- Process recusively the files inside the aimed folders according to our white, black and suspect lists
-- Low risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:Scan_Folders(args)
	local highRisk = {}
	local mediumRisk = {}
	local lowRisk = {}

	local lowRiskFiles_Aux = {}
	local suspect_suspect_Aux = {}

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

	-- Easy way to check self.suspect_suspect table (values as table indexes)
	for _,v in pairs(self.suspect_suspect) do
		suspect_suspect_Aux[v] = true
	end

	-- Scan a folder
	local function ParteDir(dir)
		if dir == "data/" .. self.FOLDER.DATA then
			return
		end

		local files, dirs = file.Find( dir.."*", "GAME" )
		
		if not dirs or
		   dir == "addons/" .. self.FOLDER.DATA or
		   dir == "lua/" .. self.FOLDER.LUA  then

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

				-- Ignore whitelisted contents
				if CheckContentsWhitelist(pathAux, self.whitelistContents) then
					return 
				end

				-- Scanning
				self:Scan_String(nil, file.Read(path, "GAME"), blocked, warning)

				local resultString = ""
				local resultTable
				local results

				-- Build, print and stock the result
				if #blocked[1] > 0 or #blocked[2] > 0 or #warning > 0 then

					-- Trash:

					-- If it's any file with only detections from self.suspect_suspect, discard it
					local notImportant = 0

					if (#blocked[1] + #blocked[2] == 0)  then
						for k,v in pairs (warning) do
							if suspect_suspect_Aux[v] then
								notImportant = notImportant + 1
							end
						end

						if notImportant == #warning then
							return
						end
					end

					-- If it's a non Lua file with only one suspect detection or a suspect detection from
					-- self.suspect and other from self.suspect_suscpec, discard it
					if rext ~= "lua" and (#blocked[1] + #blocked[2] == 0) and (#warning == 1 or #warning == 2 and notImportant) then
						return
					end

					-- Default risks:

					-- Files inside low risk folders
					for _,v in pairs(self.lowRiskFolders) do
						start = string.find(pathAux, v, nil, true)
						if start == 1 then
							results = lowRisk

							break
						end
					end

					-- Or if it's not a low risk folder
					-- let's set a default risk to modify later
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

					-- Custom risks:

					-- If we don't have a high risk but there are three or more medium risk detections, set to high risk
					if results ~= highRisk and #blocked[2] > 2 then
						results = highRisk
					end

					-- If we have a low risk but there are two or more high risk detections, set to medium risk
					if results == lowRisk and #blocked[1] >= 2 then
						results = mediumRisk
					end

					-- Build
					resultString = path
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