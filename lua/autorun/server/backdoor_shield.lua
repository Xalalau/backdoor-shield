--[[
    -- --------------- --
    [  Backdoor Shield  ]
    -- --------------- --
    
	Protect your Garry's Mod server against backdoors.

    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
--]]

local BS_ALERT = "[Backdoor Shield]"
local BS_BASEFOLDER = "backdoor shield/"

local backup = {
	--[[
	["somegame.function"] = {
		original = function original function,
		replacement = function replacement function - indexed by somegame.function
		filter = function to run validations
	},
	]]
	["debug.getinfo"] = {  -- Must be the first of the list
		original = debug.getinfo
	},
	["HTTP"] = {
		original = HTTP
	},
	["http.Post"] = { 
		original = http.Post
	},
	["http.Fetch"] = { 
		original = http.Fetch
	},
	["CompileString"] = {
		original = CompileString
	},
	["RunString"] = {
		original = RunString
	}
}

local function NoFilter()
	return true
end

for k,v in pairs(backup) do
	v.filter = NoFilter
end

local function Report(infoIn)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = BS_BASEFOLDER .. date .. "/log.txt"
	local contentLogFile = infoIn.folder and BS_BASEFOLDER .. date .. "/" .. infoIn.folder .. "/log " .. time .. ".txt"

	local msg = ""

	local info = {
		infoIn.alert and "\n" .. BS_ALERT .. " " .. infoIn.alert or "",
		infoIn.func and "\n   Function: " .. infoIn.func or "",
		"\n   Date: " .. date,
		"\n   Time: " .. time,
		"\n   Log: data/" .. logFile,
		contentLogFile and "\n   Content Log: data/" .. contentLogFile or "",
		infoIn.url and "\n   Url: " .. infoIn.url or "",
		infoIn.trace and "\n   Trying to locate: " .. infoIn.trace or "",
		detected = infoIn.detected,
	}

	for _,v in ipairs(info) do
		msg = msg .. v
	end

	msg = msg .. "\n"

	print(msg)

	if not file.Exists(BS_BASEFOLDER .. date, "DATA") then
		file.CreateDir(BS_BASEFOLDER .. date)
	end

	file.Append(logFile, msg)
	if contentLogFile then
		if not file.Exists(BS_BASEFOLDER .. date .. "/" .. infoIn.folder, "DATA") then
			file.CreateDir(BS_BASEFOLDER .. date .. "/" .. infoIn.folder)
		end

		local separator = "-----------------------------------------------------------------------------------\n\n"
		local contentMsg = "[ALERT]\n" .. separator .. "\n\n" .. msg .. "\n\n[CODE]\n" .. separator .. infoIn.content

		file.Write(contentLogFile, contentMsg)
	end
end

local function SetCurrentFunction(func, f1, f2)
	if f2 then
		_G[f1][f2] = func
	elseif f1 then
		_G[f1] = func
	end
end

local function GetCurrentFunction(f1, f2)
	return f2 and _G[f1][f2] or _G[f1]
end

local function ValidateFunction(name, backupInfo, trace)
	local f1, f2 = unpack(string.Explode(".", name))
	local currentAddress = GetCurrentFunction(f1, f2)
	local originalAddress = backupInfo.replacement or backupInfo.original

	if originalAddress ~= currentAddress then
		local info = {
			alert = "Function overriding captured and undone!",
			func = name,
			trace = trace or debug.getinfo(currentAddress, "S").source
		}

		Report(info)

		SetCurrentFunction(originalAddress, f1, f2)

		return false
	end

	return true
end

local function ScanFunctions()
	for k,v in pairs(backup) do
		ValidateFunction(k, v)
	end
end

local function SetupReplacement(funcName, customFilter)
	function Replacement(...)
		local args = {...} 

		ValidateFunction(funcName, backup[funcName], debug.traceback())

		if customFilter then
			return customFilter(debug.traceback(), funcName, args)
		else
			return backup[funcName].original(unpack(args))
		end
	end

	SetCurrentFunction(Replacement, unpack(string.Explode(".", funcName)))
	backup[funcName].replacement = Replacement
end

local function AnalyseString(str, blocked, warning)
	local blacklist = {
		"_G",
		"rcon_password",
		"sv_password",
		"RunString",
		"pcall",
		"CompileString",
		"CompileFile",
		"BroadcastLua",
		"‪" -- Invisible char
	}

	local suspect = {
		"util.AddNetworkString",
		"net",
		"http.Fetch",
		"concommand.Add",
		"http.Post"
	}

	for k,v in pairs(blacklist) do
		if string.find(str, v) then
			table.insert(blocked, v)
		end
	end

	for k,v in pairs(suspect) do
		if string.find(str, v) then
			table.insert(warning, v)
		end
	end

	return blocked, warning
end

local function validateHttpFetch(trace, funcName, args)
	local url = args[1]

	backup["http.Fetch"].original(url, function(...)
		local args = { ... }
		local blocked = {}
		local warning = {}
		local detected

		AnalyseString(url, blocked, warning)

		for _,arg in pairs(args) do
			if isstring(arg) then
				AnalyseString(arg, blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					AnalyseString(k, blocked, warning)
					AnalyseString(v, blocked, warning)
				end
			end
		end

		local detected = #blocked > 0 and { "Blocked", blocked } or #warning > 0 and { "Suspect", warning }

		if detected then
			local info = {
				folder = funcName,
				alert = detected[1] .. " execution!",
				func = funcName,
				trace = trace,
				url = url,
				detected = table.ToString(detected[2], "", true),
				content = table.ToString(args, "arguments", true)
			}

			Report(info)
		end

		return #blocked == 0 and backup[funcName].original(unpack(args))
	end)

	return true
end

local function validateCompileOrRunString(trace, funcName, args)
	local code = args[1]
	local blocked = {}
	local warning = {}

	AnalyseString(code, blocked, warning)

	local detected = #blocked > 0 and { "Blocked", blocked } or #warning > 0 and { "Suspect", warning }

	if detected then
		local info = {
			folder = funcName,
			alert = detected[1] .. " execution!",
			func = funcName,
			trace = trace,
			detected = table.ToString(detected[2], "", true),
			content = code
		}

		Report(info)
	end

	return #blocked == 0 and backup[funcName].original(unpack(args))
end

local function Initialize()
	if not file.Exists("backdoor shield", "DATA") then
		file.CreateDir("backdoor shield")
	end

	backup["http.Fetch"].filter = validateHttpFetch
	backup["CompileString"].filter = validateCompileOrRunString
	backup["RunString"].filter = validateCompileOrRunString

	for k,v in pairs(backup) do
		SetupReplacement(k, v.filter)
	end
end

Initialize()
