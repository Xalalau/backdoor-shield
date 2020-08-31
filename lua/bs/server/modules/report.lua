--[[
    2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

local function GetContentLogFileName(contentLogFile)
	local function ParseName(testName, i)
		local newName = contentLogFile:gsub("%.txt", "_" .. tostring(i+1) .. ".txt")

		if not file.Exists(newName, "DATA") then
			contentLogFile = newName
		else
			ParseName(newName, i+1)
		end
	end

	if contentLogFile and file.Exists(contentLogFile, "DATA") then
		ParseName(contentLogFile, 1)
	end

	return contentLogFile
end

local function GetDetected(detected)
	local newStr = ""

	if detected then
		for _,v1 in pairs(detected) do
			if isstring(v1) then
				newStr = newStr .. "\n        " .. v1
			elseif istable(v1) then
				for _,v2 in pairs(v1) do
					newStr = newStr .. "\n        " .. v2
				end
			end
		end
	end

	return newStr
end

function BS:Report_Detection(infoIn)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = self.FOLDER.DATA .. date .. "/log_" .. infoIn.suffix .. ".txt"
	local contentLogFile = GetContentLogFileName(infoIn.folder and self.FOLDER.DATA .. date .. "/" .. infoIn.folder .. "/log_" .. infoIn.suffix .. "_(" .. time .. ").txt")
	local detected = GetDetected(infoIn.detected)

	local info = {
		infoIn.alert and "\n" .. self.ALERT .. " " .. infoIn.alert or "",
		infoIn.func and "\n    Function: " .. infoIn.func or "",
		"\n    Date: " .. date,
		"\n    Time: " .. time,
		"\n    Log: data/" .. logFile,
		contentLogFile and "\n    Content Log: data/" .. contentLogFile or "",
		infoIn.url and "\n    Url: " .. infoIn.url or "",
		infoIn.detected and "\n    Detected:" .. detected or "",
		infoIn.trace and "\n    Location: " .. infoIn.trace or ""
	}

	local fullMsg = ""
	local msg

	for _,v in ipairs(info) do
		fullMsg = fullMsg .. v
	end

	fullMsg = fullMsg .. "\n"

	-- Don't flood the console with too much warnings information
	if infoIn.suffix == "warning" then
		-- Alert .. Log .. Content log .. detected.. trace
		msg = info[1] .. info[5] .. info[6] .. info[8] .. info[9] .. "\n"
	end

	print(msg or fullMsg)

	if infoIn.suffix == "warning" then
		self.DETECTIONS.WARNINGS = self.DETECTIONS.WARNINGS + 1
	else
		self.DETECTIONS.BLOCKS = self.DETECTIONS.BLOCKS + 1
	end

	for _,ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			net.Start("BS_AddNotification")
			net.WriteString(tostring(self.DETECTIONS.BLOCKS))
			net.WriteString(tostring(self.DETECTIONS.WARNINGS))
			net.Send(ply)
		end
	end

	if not file.Exists(self.FOLDER.DATA .. date, "DATA") then
		file.CreateDir(self.FOLDER.DATA .. date)
	end

	file.Append(logFile, fullMsg)
	if contentLogFile and infoIn.content and isstring(infoIn.content) then
		if not file.Exists(self.FOLDER.DATA .. date .. "/" .. infoIn.folder, "DATA") then
			file.CreateDir(self.FOLDER.DATA .. date .. "/" .. infoIn.folder)
		end

		local separator = "-----------------------------------------------------------------------------------\n"
		local contentMsg = "[ALERT]\n" .. separator .. fullMsg .. "\n\n[CONTENT]\n" .. separator .. "\n" .. infoIn.content

		file.Write(contentLogFile, contentMsg)
	end
end

function BS:Report_Folder(highRisk, mediumRisk, lowRisk)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = self.FOLDER.DATA .. "Scan_" .. date .. "_(" .. time .. ").txt"

	file.Append(logFile, "[HIGH RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(highRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[MEDIUM RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(mediumRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[LOW RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(lowRisk, "Results", true))

	print("\nScan saved as \"data/" .. logFile .. "\"")
end