--[[
    -- --------------- --
    [  Backdoor Shield  ]
    -- --------------- --
    
    Protected the listed functions as long as the scanner is running

    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
--]]

local BS_ALERT = "[Backdoor Shield]"
local BS_BASEFOLDER = "backdoor shield/"
local __G = _G
local __G_SAFE = table.Copy(_G)

local BS = {}
BS.__index = BS

-- Functions that backdoors like to modify globally or that need to be scanned/protected
local control = {
	--[[
	["somegame.function"] = {
		original = function original function,
		replacement = function replacement function - indexed by somegame.function
		filter = function to scan string contents
	},
	]]
	["debug.getinfo"] = {
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
	},
	["getfenv"] = {
		original = getfenv
	},
	["debug.getfenv"] = {
		original = debug.getfenv
	}
}

function BS:NoFilter()
	return nil
end

for k,v in pairs(control) do
	v.filter = BS.NoFilter
end

function BS:Report(infoIn)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = BS_BASEFOLDER .. date .. "/log_" .. infoIn.suffix .. ".txt"
	local contentLogFile = infoIn.folder and BS_BASEFOLDER .. date .. "/" .. infoIn.folder .. "/log_" .. infoIn.suffix .. "_(" .. time .. ").txt"

	local function ValidateContentLogFileName(testName, i)
		local newName = contentLogFile:gsub("%.txt", "_" .. tostring(i+1) .. ".txt")

		if not file.Exists(newName, "DATA") then
			contentLogFile = newName
		else
			ValidateContentLogFileName(newName, i+1)
		end
	end
	if contentLogFile and file.Exists(contentLogFile, "DATA") then
		ValidateContentLogFileName(contentLogFile, 1)
	end

	local detected = ""
	if infoIn.detected then
		for k,v in pairs(infoIn.detected) do
			detected = detected .. "\n        " .. v
		end
	end

	local info = {
		infoIn.alert and "\n" .. BS_ALERT .. " " .. infoIn.alert or "",
		infoIn.func and "\n    Function: " .. infoIn.func or "",
		"\n    Date: " .. date,
		"\n    Time: " .. time,
		"\n    Log: data/" .. logFile,
		contentLogFile and "\n    Content Log: data/" .. contentLogFile or "",
		infoIn.url and "\n    Url: " .. infoIn.url or "",
		infoIn.detected and "\n    Detected:" .. detected,
		infoIn.trace and "\n    Trying to locate: " .. infoIn.trace .. "\n" or ""
	}

	local fullMsg = ""
	local msg

	for _,v in ipairs(info) do
		fullMsg = fullMsg .. v
	end

	if infoIn.suffix == "warning" then
		-- Func .. Function .. Log .. Content log
		msg = info[1] .. info[2] .. info[5] .. info[6]
	end

	print(msg or fullMsg)

	if not file.Exists(BS_BASEFOLDER .. date, "DATA") then
		file.CreateDir(BS_BASEFOLDER .. date)
	end

	file.Append(logFile, fullMsg)
	if contentLogFile then
		if not file.Exists(BS_BASEFOLDER .. date .. "/" .. infoIn.folder, "DATA") then
			file.CreateDir(BS_BASEFOLDER .. date .. "/" .. infoIn.folder)
		end

		local separator = "-----------------------------------------------------------------------------------\n"
		local contentMsg = "[ALERT]\n" .. separator .. msg .. "\n\n[CONTENT]\n" .. separator .. "\n" .. infoIn.content

		file.Write(contentLogFile, contentMsg)
	end
end

function BS:SetCurrentFunction(func, f1, f2)
	if f2 then
		__G[f1][f2] = func
	elseif f1 then
		__G[f1] = func
	end
end

function BS:GetCurrentFunction(f1, f2)
	return f2 and __G[f1][f2] or __G[f1]
end

function BS:ValidateFunction(name, controlInfo, trace)
	local f1, f2 = unpack(string.Explode(".", name))
	local currentAddress = BS:GetCurrentFunction(f1, f2)
	local originalAddress = controlInfo.replacement or controlInfo.original

	if originalAddress ~= currentAddress then
		local info = {
			suffix = "override",
			alert = "Function overriding captured and undone!",
			func = name,
			trace = trace or debug.getinfo(currentAddress, "S").source
		}

		BS:Report(info)

		BS:SetCurrentFunction(originalAddress, f1, f2)

		return false
	end

	return true
end

function BS:SetupReplacement(funcName, customFilter)
	function Replacement(...)
		local args = {...} 

		BS:ValidateFunction(funcName, control[funcName], debug.traceback())

		if customFilter then
			return customFilter(nil, debug.traceback(), funcName, args)
		else
			return control[funcName].original(unpack(args))
		end
	end

	BS:SetCurrentFunction(Replacement, unpack(string.Explode(".", funcName)))
	control[funcName].replacement = Replacement
end

local whitelist = {}

function BS:AnalyseString(trace, str, blocked, warning)
	local blacklist = {
		"_G[",
		"_G.",
		"rcon_password",
		"sv_password",
		"RunString",
		"RunStringEx",
		"CompileString",
		"CompileFile",
		"BroadcastLua",
		"setfenv",
		"SendLua",
		")()",
		"!true",
		"!false",
		"()[",
		"]()",
		"]=‪[",
		"\"\\x",
		"‪" -- Invisible char
	}

	local suspect = {
		"util.AddNetworkString",
		"net",
		"http.Fetch",
		"http.Post",
		"concommand.Add",
		"pcall",
		"xpcall"
	}

	string.gsub(str, " ", "")

	local function CheckWhitelist(str)
		local found = true

		if table.Count(whitelist) > 0 then
			for _,addon in pairs(whitelist)do
				for _,allowed in pairs(addon)do
					if string.find(trace, allowed, nil, true) then
						found = false

						break
					end
				end
			end
		end

		return found
	end

	local function ProcessLists(list, list2)
		for k,v in pairs(list) do
			if string.find(str, v, nil, true) and CheckWhitelist(str) then
				table.insert(list2, v)
			end
		end
	end

	ProcessLists(blacklist, blocked)
	ProcessLists(suspect, warning)

	return blocked, warning
end

function BS:SetTraceWhitelist()
	local addons = engine.GetAddons()

	local traceWhitelist = {
		["Wiremod"] = {
			"lua/entities/gmod_wire_expression2/core/extloader.lua:86"
		},
		["DarkRP"] = {
			"gamemodes/darkrp/gamemode/libraries/simplerr.lua:507"
		}
	}

	for k,v in pairs(addons) do
		if traceWhitelist[v.title] then
			whitelist[v.title] = traceWhitelist[v.title]
		end
	end
end

function BS:ValidateHttpFetch(trace, funcName, args)
	local url = args[1]

	http.Fetch(url, function(...)
		local args = { ... }
		local blocked = {}
		local warning = {}
		local detected

		BS:AnalyseString(trace, url, blocked, warning)

		for _,arg in pairs(args) do
			if isstring(arg) then
				BS:AnalyseString(trace, arg, blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					BS:AnalyseString(trace, k, blocked, warning)
					BS:AnalyseString(trace, v, blocked, warning)
				end
			end
		end

		local detected = #blocked > 0 and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

		if detected then
			local info = {
				suffix = detected[1],
				folder = funcName,
				alert = detected[2] .. " execution!",
				func = funcName,
				trace = trace,
				url = url,
				detected = detected[3],
				content = table.ToString(args, "arguments", true)
			}

			BS:Report(info)
		end

		return #blocked == 0 and control[funcName].original(unpack(args))
	end)

	return true
end

function BS:ValidateCompileOrRunString(trace, funcName, args)
	local code = args[1]
	local blocked = {}
	local warning = {}

	BS:AnalyseString(trace, code, blocked, warning)

	local detected = #blocked > 0 and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

	if detected then
		local info = {
			suffix = detected[1],
			folder = funcName,
			alert = detected[2] .. " execution!",
			func = funcName,
			trace = trace,
			detected = detected[3],
			content = code
		}

		BS:Report(info)
	end

	return #blocked == 0 and control[funcName].original(unpack(args))
end

function BS:GenerateRandomName()
    local name = string.ToTable("qwertyuiopsdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM")
	local newName = ""
	local aux, rand
    
	for i = 1, #name do
		rand = math.random(#name)
		aux = name[i]
		name[i] = name[rand]
		name[rand] = aux
    end

    for i = 1, #name do
        newName = newName .. name[i]
    end

    return newName
end

function BS:ProtectEnv(funcName, ...)
	local result = control[funcName].original(...)

	return result == __G_SAFE and __G or result
end

function BS:ScanFunctions()
	for k,v in pairs(control) do
		BS:ValidateFunction(k, v)
	end
end

function BS:Initialize()
	-- https://manytools.org/hacker-tools/ascii-banner/
	-- ANSI Shadow
	local logo = [[
	----------------------- Server Protected By -----------------------

	██████╗  █████╗  ██████╗██╗  ██╗██████╗  ██████╗  ██████╗ ██████╗ 
	██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗
	██████╔╝███████║██║     █████╔╝ ██║  ██║██║   ██║██║   ██║██████╔╝
	██╔══██╗██╔══██║██║     ██╔═██╗ ██║  ██║██║   ██║██║   ██║██╔══██╗]]
	local logo2 = [[
	██████╔╝██║  ██║╚██████╗██║  ██╗██████╔╝╚██████╔╝╚██████╔╝██║  ██║
	╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

	███████╗██╗  ██╗██╗███████╗██╗     ██████╗
	██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗
	███████╗███████║██║█████╗  ██║     ██║  ██║
	╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║]]
	local logo3 = [[
	███████║██║  ██║██║███████╗███████╗██████╔╝
	╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝

	©2020 Xalalau Xubilozo. All Rights Reserved.
	----------------------------------------------------Pre-Alpha-1---
	]]

	print(logo)
	print(logo2)
	print(logo3)

	if not file.Exists(BS_BASEFOLDER, "DATA") then
		file.CreateDir(BS_BASEFOLDER)
	end

	BS:SetTraceWhitelist()

	control["http.Fetch"].filter = BS.ValidateHttpFetch
	control["CompileString"].filter = BS.ValidateCompileOrRunString
	control["RunString"].filter = BS.ValidateCompileOrRunString
	control["getfenv"].filter = BS.ProtectEnv
	control["debug.getfenv"].filter = BS.ProtectEnv

	for k,v in pairs(control) do
		BS:SetupReplacement(k, v.filter)
	end

	if not GetConVar("sv_hibernate_think"):GetBool() then
		hook.Add("Initialize", BS:GenerateRandomName(), function()
			RunConsoleCommand("sv_hibernate_think", "1")

			timer.Simple(300, function()
				RunConsoleCommand("sv_hibernate_think", "0")
			end)
		end)
	end
end

for k,v in pairs(BS)do
	if isfunction(v) then
		setfenv(v, __G_SAFE)
	end
end

BS:Initialize()
