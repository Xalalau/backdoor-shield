--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Check if a file isn't suspect (at first)
local function IsSuspectPath(str, ext, dangerousExtensions, notSuspect)
	if dangerousExtensions[ext] then return true end

	for k,v in pairs(notSuspect) do
		if string.find(str, v, nil, true) then
			return false
		end
	end

	return true
end
table.insert(BS.locals, IsSuspectPath)

-- Process a string according to our white, black and suspect lists
local function Folders_CheckSource(BS, trace, str, ext, blocked, warning, ignore_suspect)
	if not isstring(str) then return end
	if BS:Trace_IsWhitelisted(trace) then return end
	if BS:Scan_CheckWhitelist(str, BS.whitelists.snippets) then return end

	-- Check if we are dealing with binaries
	local IsSuspect = IsSuspectPath(str, ext, BS.scannerDangerousExtensions_Check, BS.filesScanner.notSuspect)

	-- Search for inappropriate terms for a binary but that are good for backdoors, then we won't be deceived
	if not IsSuspect then
		IsSuspect = BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistHigh) or
		            BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistMedium) or
		            BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.suspect)
	end

	if IsSuspect and blocked then
		-- Search for blocked terms
		if blocked[1] then
			BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistHigh, blocked[1])
			if not ignore_suspect then
				BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistHigh_suspect, blocked[1])
			end
		end

		if blocked[2] then
			BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistMedium, blocked[2])
			if not ignore_suspect then
				BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.blacklistMedium_suspect, blocked[2])
			end
		end

		-- If blocked terms are found, reinforce the search with a charset check
		if #blocked[1] > 0 and #blocked[2] > 0 then
			BS:Scan_CheckCharset(str, ext, blocked[1], true)
		end
	end

	if IsSuspect and warning then
		-- Loof for suspect terms, wich are also good to reinforce results
		BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.suspect, warning)
		if not ignore_suspect then
			BS:Scan_ProcessList(BS, trace, str, IsSuspect, BS.filesScanner.suspect_suspect, warning)
		end
	end

	return
end
table.insert(BS.locals, Folders_CheckSource)

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
local function RecursiveScan(BS, dir, results, cfgs, extensions, forceIgnore, forceLowRisk)
	if dir == "data/" .. BS.folder.data then
		return
	end

	local files, dirs = file.Find(dir.."*", "GAME")

	-- Ignore nil folders
	if not dirs then
		return
	-- Ignore nil dirs and our own folder(s) results
	elseif not dirs then
		forceIgnore = true
	-- Ignore our own folders
	elseif not forceLowRisk and
	       string.find(dir, "lua/" .. BS.folder.lua) == 1 or
	       dir == "addons/" .. BS.folder.data or
	       dir == "addons/" .. string.gsub(BS.folder.data, "/", "") .. "-master/" then

		if BS.filesScanner.ignoreBSFolders then
			forceIgnore = true
		else
			forceLowRisk = true
		end
	end

	-- Check directories
	for _, fdir in pairs(dirs) do
		if fdir ~= "/" then -- We can get a / if we start from the root
			RecursiveScan(BS, dir .. fdir .. "/", results, cfgs, extensions, forceIgnore, forceLowRisk)
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
			-- Note: used by bs_scan
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
			if BS:Scan_CheckWhitelist(pathAux, BS.whitelists.snippets) then
				return 
			end

			-- Print status
			results.totalScanned = results.totalScanned + 1
			if results.totalScanned == results.lastTotalPrinted + 500 then
				MsgC(BS.colors.message, results.totalScanned .. " files scanned...\n\n")
				results.lastTotalPrinted = results.totalScanned
			end

			-- Scan file
			Folders_CheckSource(BS, path, file.Read(path, "GAME"), ext, blocked, warning)

			local resultString = ""
			local resultsList

			-- Build, print and stock the result
			if #blocked[1] > 0 or #blocked[2] > 0 or #warning > 0 then

				-- Trash:

				-- Discard result if it's from file with only BS.filesScanner.suspect_suspect detections
				if BS.filesScanner.discardVeryLowRisk and (#blocked[1] + #blocked[2] == 0) then
					local notImportant = 0

					for k,v in pairs (warning) do
						if BS.scannerSuspect_suspect_Check[v] then
							notImportant = notImportant + 1
						end
					end

					if notImportant > 0 and notImportant == #warning then
						results.discarded = results.discarded + 1
						return
					end
				end

				-- Default risks:

				-- If it's low-risk or a forced low-risk
				if BS:Trace_IsLowRisk(path) or forceLowRisk then
					resultsList = results.lowRisk
				end

				-- Or if it's not a file in a low-risk folder, set a default risk to maybe modify later
				if not resultsList then
					-- Non Lua detections, if they aren't false positive, are VERY unsafe
					if ext ~= "lua" then
						resultsList = results.highRisk
					-- Set the risk based on the detection precedence
					else
						if #blocked[1] > 0 then resultsList = results.highRisk end
						if not resultsList and #blocked[2] > 0 then resultsList = results.mediumRisk end
						if not resultsList and #warning > 0 then resultsList = results.lowRisk end
					end
				end

				-- Other custom risks:

				if not forceLowRisk then
					-- If we don't have a high-risk but there are three or more medium-risk detections, set to high-risk
					if resultsList ~= results.highRisk and #blocked[2] > 2 then
						resultsList = results.highRisk
					end

					-- If we have a low-risk but there are two or more high-risk detections, set to medium-risk
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

				if resultsList ~= results.lowRisk or BS.filesScanner.printLowRisk then
					for lineCount,lineText in pairs(string.Explode("\n", resultString)) do
						if lineCount == 1 then
							local color = resultsList == results.highRisk and BS.colors.highRisk or -- Linux compatible colors
							              resultsList == results.mediumRisk and BS.colors.mediumRisk or
							              resultsList == results.lowRisk and BS.colors.lowRisk

							MsgC(color, lineText .. "\n")
						else
							print(lineText)
						end
					end
				end

				-- Stack up

				table.insert(resultsList, resultString)
			end
		end
	end 
end
table.insert(BS.locals, RecursiveScan)

-- Process the files recusively inside the aimed folders according to our white, black and suspect lists
-- Note: Low-risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:Folders_Scan(args, extensions)
	-- All results
	local results = {
		totalScanned = 0,
		lastTotalPrinted = 0,
		highRisk = {},
		mediumRisk = {},
		lowRisk = {},
		discarded = 0
	}

	local cfgs = {
		addonsFolder = {}, 	-- Note: results from addons folder take precedence over lua folder.
	}

	-- Select custom folders or a list of default folders
	local folders = #args > 0 and args or self.filesScanner.foldersToScan

	if not folders then
		MsgC(self.colors.message, "\n" .. self.alert .. " no folders selected.\n\n")
		return
	end

	-- Deal with bars
	for k,v in pairs(folders) do
		folders[k] = string.gsub(v, "\\", "/")
		if string.sub(folders[k], -1) == "/" then
			folders[k] = folders[k]:sub(1, #v - 1)
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
	for _,folder in ipairs(folders) do
		if folder == "" or file.Exists(folder .. "/", "GAME") then
			RecursiveScan(self, folder == "" and folder or folder .. "/", results, cfgs, extensions)
		else
			MsgC(self.colors.message, "\n" .. self.alert .. " Folder not found: " .. folder .. "\n\n")
		end
	end

	-- Console final log
	MsgC(self.colors.header, "\nScan results:\n\n")

	MsgC(self.colors.key, "    Files scanned: ", self.colors.value, results.totalScanned .. "\n\n")

	MsgC(self.colors.key, "    Detections:\n")
	MsgC(self.colors.key, "      | High-Risk   : ", self.colors.highRisk, #results.highRisk .. "\n")
	MsgC(self.colors.key, "      | Medium-Risk : ", self.colors.mediumRisk, #results.mediumRisk .. "\n") 
	MsgC(self.colors.key, "      | Low-Risk    : ", self.colors.lowRisk, #results.lowRisk .. "\n")
	MsgC(self.colors.key, "      | Discarded   : ", self.colors.value, results.discarded .. "\n\n")

	local logFile = self:Report_Folder(results.highRisk, results.mediumRisk, results.lowRisk)

	MsgC(self.colors.key, "    Saved as: ", self.colors.value, "data/" .. logFile .. "\n\n")

	MsgC(self.colors.message, "Check the log file for more information.\n\n")
end