--[[
    2020-2021 Xalalau Xubilozo. MIT License
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
		["snippet"] = "Blocked code snippet",
		["file"] = "Full Lua file: " ,
	}

	local indent = "        "
	local result = [[

]] .. (snippet and indent .. (messages["snippet"] .. "\n") or "") .. [[
]] .. (file and indent .. (messages["file"] .. file) or "")

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
		*	alert =  Message explaining the detection
			func = Name of the bad function
			detected = List of the prohibited calls detected inside the blocked function
		*	type = Detection type. I commonly use "blocked", "warning" and "detour"
			folder = Main folder to store this dectetion. I commonly use the detected function name, so it's easier to find the real threats
			trace = Lua function call stack. Due to my persistent trace system, it can contain multiple stacks
			snippet = Blocked code snippet
			file = File where detection occurred
		}

		* Required fields

	Note: Using the type "warning" will generate full file logs but smaller console prints
]]
function BS:Report_Detection(infoIn)
	-- Format the report informations
	local timestamp = os.time()
	local date = os.date("%Y-%m-%d", timestamp)
	local timeFormat1 = os.date("%H.%M.%S", timestamp)
	local timeFormat2 = os.date("%Hh %Mm %Ss", timestamp)

	--[[
		dayFolder            e.g.	/03-16-2021/
			typeFile             		log_blocked.txt
			mainFolder           		/http.Fetch/
				logFolder        			/23.57.47 - blocked/
					logFile      				[Log].txt
					luaFile      				Full Lua file.txt
					snippetFile  				Blocked code snippet.txt
	]]
	local dayFolder = self.folder.data .. date .. "/"
	local typeFile = dayFolder .. "/log_" .. infoIn.type .. ".txt"
	local mainFolder = infoIn.folder and dayFolder .. infoIn.folder .. "/"
	local logFolder = mainFolder and ValidateFolderName(mainFolder .. timeFormat1 .. " - " .. infoIn.type .. "/")
	local logFile = logFolder and logFolder .. "/[Log].txt"
	local luaFile =  logFolder and infoIn.file and logFolder .. "Full Lua file.txt"
	local snippetFile =  logFolder and infoIn.snippet and logFolder .. "Blocked code snippet.txt"

	local filesGenerated = logFolder and FormatTypesList(infoIn.snippet, infoIn.file)

	local detected = FormatDetectedList(infoIn.detected)

	local info = { -- If you change the fields order, update FormatLog(). Also, use "::" to identify the color position
		self.alert .. " " .. infoIn.alert or "",
		"\n    Date & time:: " .. date .. " | " .. timeFormat2,
		infoIn.func and "\n    Function:: " .. infoIn.func or "",
		detected and "\n    Detected::" .. detected or "",
		infoIn.url and "\n    Url:: " .. infoIn.url or "",
		"\n    Log Folder:: data/" .. (logFolder or dayFolder),
		filesGenerated and "\n    Log Contents:: " .. filesGenerated or "",
		infoIn.trace and "\n    Location:: " .. infoIn.trace or ""
	}

	local fullLog, partialLog = FormatLog(info)

--[[
	Full log preview (e.g.):

	[Backdoor Shield] Execution blocked!
		Date & Time: 03-14-2021 | 23h 57m 47s
		Function: http.Fetch
		Detected:
			CompileString
			http.Fetch
		Url: https://gvac.cz/link/fuck.php?key=McIjefKcSOKuWbTxvLWC
		Log Folder: data/backdoor-shield/03-14-2021/http.Fetch/23.57.47 - blocked/
		Log Contents:
			Blocked code snippet
			Full Lua file: addons/ariviaf4/lua/autorun/_arivia_load.lua
		Location:
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
		local colors = string.Explode("::", lineText)

		if linePos == 2 then
			MsgC(infoIn.type == "warning" and self.colors.mediumRisk or self.colors.highRisk, lineText .. "\n")
		elseif #colors > 0 then
			if not colors[2] then
				MsgC(self.colors.value, colors[1] .. "\n")
			else
				MsgC(self.colors.key, colors[1] .. ":", self.colors.value, colors[2] .. "\n")
			end
		else
			print(lineText)
		end
	end

	-- Clean color identificator
	fullLog = string.gsub(fullLog, "::", ":")

	-- Update counter
	if infoIn.type == "warning" then
		self.detections.warnings = self.detections.warnings + 1
	else
		self.detections.blocks = self.detections.blocks + 1
	end

	-- Send a GUI update
	for _,ply in pairs(player.GetHumans()) do
		if ply:IsAdmin() then
			net.Start("BS_AddNotification")
			net.WriteString(tostring(self.detections.blocks))
			net.WriteString(tostring(self.detections.warnings))
			net.Send(ply)
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

-- Print scan detections to a file
function BS:Report_Folder(highRisk, mediumRisk, lowRisk)
	local timestamp = os.time()
	local date = os.date("%Y-%m-%d", timestamp)
	local time = os.date("%Hh %Mm %Ss", timestamp)
	local logFile = self.folder.data .. "Scan_" .. date .. "_(" .. time .. ").txt"

	local topSeparator = "\n\n\n\n\n"
	local bottomSeparator = "\n-----------------------------------------------------------------------------------\n\n"

	local message = [[
[HIGH RISK detections] ]] .. bottomSeparator ..[[
]] .. table.ToString(highRisk, "Results", true) .. [[
]] .. topSeparator .. "[MEDIUM RISK detections]" .. bottomSeparator .. [[
]] .. table.ToString(mediumRisk, "Results", true) .. [[
]] .. topSeparator .. "[LOW RISK detections]" .. bottomSeparator .. [[
]] .. table.ToString(lowRisk, "Results", true)

	file.Append(logFile, message)

	return logFile
end