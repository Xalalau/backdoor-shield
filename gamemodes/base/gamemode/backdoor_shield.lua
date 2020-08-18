--[[
	-- --------------- --
    [  Backdoor Shield  ]
    -- --------------- --
    
    Protect your Garry's Mod server against backdoors.

	©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary

--]]

-- SCAN LISTS
-- These lists are used to check urls, files and codes passed as argument
-- Note: these lists are locked here for proper security
-- -----------------------------------------------------------------------------------

-- Low risk files
-- When scanning folders, these files will be considered low risk, so they won't flood the
-- console with warnings (but the total will be shown and they'll normally be reported in
-- the logs)
local lowRiskFiles = {
	"lua/derma/derma.lua",
	"lua/derma/derma_example.lua",
	"lua/entities/gmod_wire_expression2/core/debug.lua",
	"lua/entities/gmod_wire_expression2/core/e2lib.lua",
	"lua/entities/gmod_wire_expression2/core/extloader.lua",
	"lua/entities/gmod_wire_expression2/core/init.lua",
	"lua/entities/gmod_wire_expression2/core/player.lua",
	"lua/entities/gmod_wire_keyboard/init.lua",
	"lua/entities/info_wiremapinterface/init.lua",
	"lua/includes/modules/constraint.lua",
	"lua/includes/util/javascript_util.lua",
	"lua/includes/util.lua",
	"lua/vgui/dhtml.lua",
	"lua/wire/client/text_editor/texteditor.lua",
	"lua/wire/zvm/zvm_core.lua",
	"lua/wire/wireshared.lua",
}

-- Whitelist urls
-- Don't scan the downloaded string!
-- Note: protected functions overriding will still be detected and undone
-- Note2: any protected functions called will still be scanned
-- Note3: insert a url starting with http or https and ending with a "/", like https://google.com/
local whitelistUrls = {
	"http://www.geoplugin.net/",
}

-- Whitelist TRACE ERRORS
-- By default, I do this instead of whitelisting files because the traces cannot be
-- replicated without many counterpoints
local whitelistTraceErrors = {
	"lua/entities/gmod_wire_expression2/core/extloader.lua:86", -- Wiremod
	"gamemodes/darkrp/gamemode/libraries/simplerr.lua:507", -- DarkRP
	"lua/ulib/shared/plugin.lua:186", -- ULib
}

-- Whitelist files
-- Ignore these files and their contents, so they won't going to be scanned at all!
-- Note: protected functions overriding will still be detected and undone
-- Note2: only whitelist files if you trust them completely! Even protected functions will be disarmed
local whitelistFiles = {
}

-- High chance of direct backdoor detection
local blacklistHigh = {
	"_G[", -- !! Important, don't remove! Used to start hiding function names.
	"_G.", -- !! Important, don't remove! Used to start hiding function names.
	"!true",
	"!false",
	"]()",
	"]=‪[",
	"\"\\x",
	"‪", -- Invisible char
}

-- Medium chance of direct backdoor detection
local blacklistMedium = {
	"RunString",
	"RunStringEx",
	"CompileString",
	"CompileFile",
	"BroadcastLua",
	"setfenv",
}

-- Low chance of direct backdoor detection
local suspect = {
	"util.AddNetworkString",
	"net",
	"http.Fetch",
	"http.Post",
	"concommand.Add",
	"pcall",
	"xpcall",
	"SendLua",
}

-- -----------------------------------------------------------------------------------

local BS_VERSION = "V.1.2"

local BS_ALERT = "[Backdoor Shield]"
local BS_BASEFOLDER = "backdoor shield/"
local BS_FILENAME = "backdoor_shield.lua"
local __G = _G -- Access the global table inside our custom environment
local __G_SAFE = table.Copy(_G) -- Our custom environment

local BS = {}
BS.__index = BS

-- Functions that need to be protected (some are scanned)
local control = {
	--[[
	["somegame.function"] = {
		original = function original function,
		replacement = function replacement function - indexed by somegame.function
		filter = function to scan string contents
	},
	]]
	["debug.getinfo"] = {}, -- Protected
	["HTTP"] = {}, -- Protected
	["http.Post"] = {}, -- Protected, scanned
	["http.Fetch"] = {}, -- Protected, scanned
	["CompileString"] = {}, -- Protected, scanned
	["CompileFile"] = {}, -- Protected, scanned
	["RunString"] = {}, -- Protected, scanned
	["RunStringEx"] = {}, -- Protected, scanned
	["getfenv"] = {}, -- Protected (isolate our environment)
	["debug.getfenv"] = {}, -- Protected (isolate our environment)
}

-- -------------------------------------
-- [ UTILITIES ]
-- -------------------------------------

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

-- -------------------------------------
-- [ REPORTING ]
-- -------------------------------------

function BS:ReportFile(infoIn)
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
		infoIn.alert and "\n" .. BS_ALERT .. " " .. infoIn.alert or "",
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
		-- Alert .. Log .. Content log .. trace
		msg = info[1] .. info[5] .. info[6] .. info[9] .. "\n"
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
		local contentMsg = "[ALERT]\n" .. separator .. fullMsg .. "\n\n[CONTENT]\n" .. separator .. "\n" .. infoIn.content

		file.Write(contentLogFile, contentMsg)
	end
end

function BS:ReportFolder(resultsHighRisk, resultsLowRisk)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = BS_BASEFOLDER .. "Scan_" .. date .. "_(" .. time .. ").txt"

	file.Append(logFile, "[HIGH RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(resultsHighRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[LOW RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(resultsLowRisk, "Results", true))

	print("\nScan saved as \"data/" .. logFile .. "\"")
end

-- -------------------------------------
-- [ MANAGE CONTROLLED FUNCTIONS ]
-- -------------------------------------

-- Get a global GMod function
function BS:GetCurrentFunction(f1, f2)
	return f2 and __G[f1][f2] or __G[f1]
end

-- Set a global GMod function
function BS:SetCurrentFunction(func, f1, f2)
	if f2 then
		__G[f1][f2] = func
	elseif f1 then
		__G[f1] = func
	end
end

-- Replace a global GMod function with our custom ones
function BS:SetReplacementFunction(funcName, customFilter)
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

-- Check if our custom replaced global GMod function was overridden
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

		BS:ReportFile(info)

		BS:SetCurrentFunction(originalAddress, f1, f2)

		return false
	end

	return true
end

-- Check http.fetch calls
function BS:ValidateHttpFetch(trace, funcName, args)
	local url = args[1]

	http.Fetch(url, function()
		local blocked = {{}, {}}
		local warning = {}
		local detected

		for k,v in pairs(whitelistUrls) do
			local urlStart, urlEnd = string.find(url, v)

			if urlStart and urlStart == 1 then
				return control[funcName].original(unpack(args))
			end
		end

		BS:ScanString(trace, url, blocked, warning)

		for _,arg in pairs(args) do
			if isstring(arg) then
				BS:ScanString(trace, arg, blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					BS:ScanString(trace, k, blocked, warning)
					BS:ScanString(trace, v, blocked, warning)
				end
			end
		end

		local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

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

			BS:ReportFile(info)
		end

		if #blocked[1] == 0 and #blocked[2] == 0 then
			control[funcName].original(unpack(args))
		end
	end)
end

-- Check CompileString and RunString(EX) calls
function BS:ValidateCompileOrRunString_Ex(trace, funcName, args)
	local code = args[1]
	local blocked = {{}, {}}
	local warning = {}

	if not __G_SAFE[funcName] then -- RunStringEx is deprecated
		return ""
	end

	BS:ScanString(trace, code, blocked, warning)

	local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

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

		BS:ReportFile(info)
	end

	return #blocked[1] == 0 and #blocked[2] == 0 and control[funcName].original(unpack(args)) or ""
end

-- Check CompileFile calls
function BS:ValidateCompileFile(trace, funcName, args)
	local path = args[1]
	local content = file.Open(path, "r", "LUA")
	local blocked = {{}, {}}
	local warning = {}

	BS:ScanString(trace, content, blocked, warning)

	local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

	if detected then
		local info = {
			suffix = detected[1],
			folder = funcName,
			alert = detected[2] .. " execution!",
			func = funcName,
			trace = trace,
			detected = detected[3],
			content = content
		}

		BS:ReportFile(info)
	end

	return #blocked[1] == 0 and #blocked[2] == 0 and control[funcName].original(unpack(args))
end

-- Protect our custom environment
function BS:ProtectEnv(null, funcName, ...)
	local result = control[funcName].original(unpack({...})[1])

	return result == __G_SAFE and __G or result
end

-- -------------------------------------
-- [ SCANNING ]
-- -------------------------------------

function BS:CheckTraceWhitelist(trace)
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

function BS:CheckFilesWhitelist(str)
	local found = false

	if str and #whitelistFiles > 0 then
		for _,allowed in pairs(whitelistFiles)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

-- Process a string according to our white, black and suspect lists
function BS:ScanString(trace, str, blocked, warning)
	string.gsub(str, " ", "")

	local function ProcessLists(list, list2)
		for k,v in pairs(list) do
			if string.find(str, v, nil, true) and
			   not BS:CheckTraceWhitelist(trace) and
			   not BS:CheckFilesWhitelist(trace) then

				table.insert(list2, v)
			end
		end
	end

	if blocked then
		if blocked[1] then
			ProcessLists(blacklistHigh, blocked[1])
		end

		if blocked[2] then
			ProcessLists(blacklistMedium, blocked[2])
		end
	end

	if warning then
		ProcessLists(suspect, warning)
	end

	return blocked, warning
end

-- Process recusively the files inside the aimed folders according to our white, black and suspect lists
-- Low risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:ScanFolders(args)
	local resultsHighRisk = {}
	local resultsLowRisk = {}
	local folders = #args > 0 and args or {
		"data",
		"lua"
	}

	for k,v in pairs(folders) do
		folders[k] = string.gsub(v, "\\", "/")
		if string.sub(folders[k], -1) == "/" then
			folders[k] = folders[k]:sub(1, #v - 1)
		end
	end

	local function ScanFolder(dir)
		if dir == "data/" .. BS_BASEFOLDER then
			return
		end

		local files, dirs = file.Find( dir.."*", "GAME" )

		for _, fdir in pairs(dirs) do
			ScanFolder(dir .. fdir .. "/", ext)
		end

		for k,v in pairs(files) do
			local ext = string.GetExtensionFromFilename(v)

			if ext == "lua" or ext == "vmt" or ext == "txt" then
				local blocked = {{}, {}}
				local arq = dir .. v

				if v == BS_FILENAME or BS:CheckFilesWhitelist(arq) then
					return 
				end

				local results

				for _,lowRiskFile in pairs(lowRiskFiles) do
					if arq == lowRiskFile then
						results = resultsLowRisk
					end
				end

				if not results then
					results = resultsHighRisk
				end

				BS:ScanString(nil, file.Read(arq, "GAME"), blocked)

				local localResult = ""

				if #blocked[1] > 0 or #blocked[2] > 0 then
					localResult = arq
				end

				if #blocked[1] > 0 then
					for k,v in pairs(blocked[1]) do
						localResult = localResult .. "\n     [!!] " .. v
					end
				end

				if #blocked[2] > 0 then
					for k,v in pairs(blocked[2]) do
						localResult = localResult .. "\n     [!] " .. v
					end
				end

				if #blocked[1] > 0 or #blocked[2] > 0 then
					localResult = localResult .. "\n"
					table.insert(results, localResult)
					if results == resultsHighRisk then
						print(localResult)
					end
				end
			end
		end 
	end

	print("\n\n -------------------------------------------------------------------")
	print(BS_ALERT .. " Scanning GMod and all the mounted contents...\n")

	for _,folder in pairs(folders) do
		if file.Exists(folder .. "/", "GAME") then
			ScanFolder(folder .. "/", ".vcd" )
		end
	end

	BS:ReportFolder(resultsHighRisk, resultsLowRisk)

	print("\nLow risk results: ", tostring(#resultsLowRisk))
	print("Check the log for more informations.\n")
	print("------------------------------------------------------------------- \n")
end

-- -------------------------------------
-- [ INITIALIZATION ]
-- -------------------------------------

function BS:Initialize()
	-- https://manytools.org/hacker-tools/ascii-banner/
	-- Font: ANSI Shadow
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

	The protection runs automatically, but you can also:

	1) Set custom black and white lists directly in the main file.

	2) Use the commands:
	|--> "bs_scan": Recursively scan GMod and all the mounted contents
	|--> "bs_scan <folder>": Recursively scan the seleceted folder

	Version: ]] .. BS_VERSION .. [[


	©2020 Xalalau Xubilozo. All Rights Reserved.
	-------------------------------------------------------------------
	]]

	print(logo)
	print(logo2)
	print(logo3)

	if not file.Exists(BS_BASEFOLDER, "DATA") then
		file.CreateDir(BS_BASEFOLDER)
	end

	control["http.Fetch"].filter = BS.ValidateHttpFetch
	control["CompileFile"].filter = BS.ValidateCompileFile
	control["CompileString"].filter = BS.ValidateCompileOrRunString_Ex
	control["RunString"].filter = BS.ValidateCompileOrRunString_Ex
	control["RunStringEx"].filter = BS.ValidateCompileOrRunString_Ex
	control["getfenv"].filter = BS.ProtectEnv
	control["debug.getfenv"].filter = BS.ProtectEnv
	
	for k,v in pairs(control) do
		control[k].original = BS:GetCurrentFunction(unpack(string.Explode(".", k)))
		BS:SetReplacementFunction(k, v.filter)
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

concommand.Add("bs_scan", function(ply, cmd, args)
    BS:ScanFolders(args)
end)