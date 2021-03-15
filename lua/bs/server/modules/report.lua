--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

function BS:Report_Detection(infoIn)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = self.folder.data .. date .. "/log_" .. infoIn.suffix .. ".txt"

	local contentLogFile = infoIn.content and infoIn.folder and self.folder.data .. date .. "/" .. infoIn.folder .. "/log_" .. infoIn.suffix .. "_(" .. time .. ").txt"
	local function ValidateName(testName, i)
		local newName = contentLogFile:gsub("%.txt", "_" .. tostring(i+1) .. ".txt")

		if not file.Exists(newName, "DATA") then
			contentLogFile = newName
		else
			ValidateName(newName, i+1)
		end
	end

	if contentLogFile and file.Exists(contentLogFile, "DATA") then
		ValidateName(contentLogFile, 1)
	end

	local detected = ""
	if infoIn.detected then
		for _,v1 in pairs(infoIn.detected) do
			if isstring(v1) then
				detected = detected .. "\n        " .. v1
			elseif istable(v1) then
				for _,v2 in pairs(v1) do
					detected = detected .. "\n        " .. v2
				end
			end
		end
	end

	local info = {
		infoIn.alert and "\n" .. self.alert .. " " .. infoIn.alert or "",
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
		self.detections.warnings = self.detections.warnings + 1
	else
		self.detections.blocks = self.detections.blocks + 1
	end

	for _,ply in pairs(player.GetAll()) do
		if ply:IsAdmin() then
			net.Start("BS_AddNotification")
			net.WriteString(tostring(self.detections.blocks))
			net.WriteString(tostring(self.detections.warnings))
			net.Send(ply)
		end
	end

	if not file.Exists(self.folder.data .. date, "DATA") then
		file.CreateDir(self.folder.data .. date)
	end

	file.Append(logFile, fullMsg)
	if contentLogFile and infoIn.content and isstring(infoIn.content) then
		if not file.Exists(self.folder.data .. date .. "/" .. infoIn.folder, "DATA") then
			file.CreateDir(self.folder.data .. date .. "/" .. infoIn.folder)
		end

		local separator = "-----------------------------------------------------------------------------------\n"
		local contentMsg = "[alert]\n" .. separator .. fullMsg .. "\n\n[CONTENT]\n" .. separator .. "\n" .. infoIn.content

		file.Write(contentLogFile, contentMsg)
	end
end

function BS:Report_Folder(highRisk, mediumRisk, lowRisk)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = self.folder.data .. "Scan_" .. date .. "_(" .. time .. ").txt"
	local separator = "-----------------------------------------------------------------------------------\n"
	
	file.Append(logFile, "[HIGH RISK detections]\n" .. separator .. "\n")
	file.Append(logFile, table.ToString(highRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[MEDIUM RISK detections]\n" .. separator .. "\n")
	file.Append(logFile, table.ToString(mediumRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[LOW RISK detections]\n" .. separator .. "\n")
	file.Append(logFile, table.ToString(lowRisk, "Results", true))

	print("\nScan saved as \"data/" .. logFile .. "\"")
end