--[[

    -- --------------- --
    [  Backdoor Shield  ]
    -- --------------- --

    Protect your Garry's Mod server against backdoors.

	©2020 Xalalau Xubilozo. All Rights Reserved.
	https://tldrlegal.com/license/all-rights-served#summary

	http://xalalau.com/

--]]

-- Note: the source code isn't divided into files because we need to isolate it.

-- SCAN LISTS
-- These lists are used to check urls, files and codes passed as argument
-- Note: these lists are locked here for proper security
-- Note2: I'm not using patterns
-- -----------------------------------------------------------------------------------

-- Low risk files and folders
-- When scanning the game, these limes will be considered low risk, so they won't flood
-- the console with warnings (but they'll be normally reported in the logs)
local lowRiskFolders = {
	"gamemodes/darkrp/",
	"lua/entities/gmod_wire_expression2/",
	"lua/wire/",
	"lua/ulx/",
	"lua/ulib/",
	"lua/dlib/",
}

local lowRiskFiles = {
	"lua/derma/derma.lua",
	"lua/derma/derma_example.lua",
	"lua/entities/gmod_wire_target_finder.lua",
	"lua/entities/gmod_wire_keyboard/init.lua",
	"lua/entities/info_wiremapinterface/init.lua",
	"lua/includes/extensions/debug.lua",
	"lua/includes/modules/constraint.lua",
	"lua/includes/util/javascript_util.lua",
	"lua/includes/util.lua",
	"lua/vgui/dhtml.lua",
	"lua/autorun/cb-lib.lua",
	"lua/autorun/!sh_dlib.lua",
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
	"gamemodes/darkrp/gamemode/libraries/simplerr.lua:", -- DarkRP
	"lua/autorun/streamradio_loader.lua:254", -- 3D Stream Radio
	"lua/ulib/shared/plugin.lua:186", -- ULib
	"lua/dlib/sh_init.lua:105", -- DLib
	"lua/dlib/core/loader.lua:32", -- DLib
	"lua/dlib/modules/i18n/sh_loader.lua:66", -- DLib
}

-- Whitelist files
-- Ignore these files and all their contents, so they won't going to be scanned at all!
-- Note: protected functions overriding will still be detected and undone
-- Note2: only whitelist files if you trust them completely! Even protected functions will be disarmed
local whitelistFiles = {
}

-- Detections with these chars will be considered as not suspect at first
local notSuspect = {
	" ",
}

-- High chance of direct backdoor detection (all files)
local blacklistHigh = {
	"=_G", -- !! Used by backdoors to start hiding names. Also, there is an extra check in the code to avoid incorrect results.
	"(_G)",
	"!true",
	"!false",
}

-- High chance of direct backdoor detection (suspect code only)
local blacklistHigh_Suspect = {
	"]=‪[",
	"\"0x",
	"\'0x",
	"\"0X",
	"\'0X",
	"\"\\x",
	"\'\\x",
	"\"\\X",
	"\'\\X",
	"‪", -- Invisible char
}

-- Medium chance of direct backdoor detection (all files)
local blacklistMedium = {
	"RunString",
	"RunStringEx",
	"CompileString",
	"CompileFile",
	"BroadcastLua",
	"setfenv",
	"http.Fetch",
	"http.Post",
	"debug.getinfo",
}

-- Medium chance of direct backdoor detection (suspect code only)
local blacklistMedium_Suspect = {
	"_G[",
	"_G.",
	"]()",
}

-- Low chance of direct backdoor detection
local suspect = {
	--"util.AddNetworkString",
	--"net",
	--"file.Read",
	--"file.Delete",
	--"concommand.Add",
	"pcall",
	"xpcall",
	"SendLua",
}

-- -----------------------------------------------------------------------------------

local BS_VERSION = "V.git.1.3+"

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
	["debug.getinfo"] = {}, -- Protected to isolate our environment
	["jit.util.funcinfo"] = {}, -- Protected to isolate our environment
	["getfenv"] = {}, -- Protected to isolate our environment
	["debug.getfenv"] = {}, -- Protected to isolate our environment
	["HTTP"] = {},
	["http.Post"] = {}, -- scanned
	["http.Fetch"] = {}, -- scanned
	["CompileString"] = {}, -- scanned
	["CompileFile"] = {}, -- scanned
	["RunString"] = {}, -- scanned
	["RunStringEx"] = {}, -- scanned
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

function BS:ReportFolder(highRisk, mediumRisk, lowRisk)
	local Timestamp = os.time()
	local date = os.date("%m-%d-%Y", Timestamp)
	local time = os.date("%Hh %Mm %Ss", Timestamp)
	local logFile = BS_BASEFOLDER .. "Scan_" .. date .. "_(" .. time .. ").txt"

	file.Append(logFile, "[HIGH RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(highRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[MEDIUM RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(mediumRisk, "Results", true))
	file.Append(logFile, "\n\n\n\n\n[LOW RISK DETECTIONS]\n\n")
	file.Append(logFile, table.ToString(lowRisk, "Results", true))

	print("\nScan saved as \"data/" .. logFile .. "\"")
end

-- -------------------------------------
-- [ MANAGE CONTROLLED FUNCTIONS ]
-- -------------------------------------

function BS:GetCurrentFunction(f1, f2, f3)
	return f3 and __G[f1][f2][f3] or f2 and __G[f1][f2] or f1 and __G[f1]
end

function BS:SetDetouring_Aux(func, f1, f2, f3)
	if f3 then
		__G[f1][f2][f3] = func
	elseif f2 then
		__G[f1][f2] = func
	elseif f1 then
		__G[f1] = func
	end
end

function BS:SetDetouring(funcName, customFilter)
	function Replacement(...)
		local args = {...} 
		local trace = debug.traceback()

		BS:ValidateDetouring(funcName, control[funcName], trace)

		if customFilter then
			return customFilter(nil, trace, funcName, args)
		else
			return control[funcName].original(unpack(args))
		end
	end

	BS:SetDetouring_Aux(Replacement, unpack(string.Explode(".", funcName)))
	control[funcName].replacement = Replacement
end

function BS:ValidateDetouring(name, controlInfo, trace)
	local f1, f2, f3 = unpack(string.Explode(".", name))
	local currentAddress = BS:GetCurrentFunction(f1, f2, f3)
	local originalAddress = controlInfo.replacement or controlInfo.original

	if originalAddress ~= currentAddress then
		local info = {
			suffix = "override",
			alert = "Function overriding captured and undone!",
			func = name,
			trace = trace
		}

		BS:ReportFile(info)

		BS:SetDetouring_Aux(originalAddress, f1, f2, f3)

		return false
	end

	return true
end

-- Check http.fetch calls
function BS:ValidateHttpFetch(trace, funcName, args)
	local url = args[1]

	http.Fetch(url, function(...)
		local args2 = { ... }
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

		for _,arg in pairs(args2) do
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
				content = table.ToString(args2, "arguments", true)
			}

			BS:ReportFile(info)
		end

		if #blocked[1] == 0 and #blocked[2] == 0 then
			control[funcName].original(unpack(args))
		end
	end, args[3], args[4])
end

-- Check CompileString and RunString(EX) calls
function BS:ValidateCompileOrRunString_Ex(trace, funcName, args)
	local code = args[1]
	local blocked = {{}, {}}
	local warning = {}

	if not __G_SAFE[funcName] then -- RunStringEx exists but is deprecated
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
	local content = file.Read(path, "LUA")
	local blocked = {{}, {}}
	local warning = {}

	if not isstring(content) then
		return
	end

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
function BS:ProtectEnv(trace, funcName, args)
	local result = control[funcName].original(unpack(args))

	return result == __G_SAFE and __G or result
end

-- Mask our function replacements
function BS:MaskDebugGetInfo(trace, funcName, args)
	local result = control[funcName].original(unpack(args))

	if result and (result.short_src or result.source) then
		for k,v in pairs(control) do
			local replacementFunction = BS:GetCurrentFunction(unpack(string.Explode(".", k)))

			if args[1] == replacementFunction then
				if result.short_src then
					result.short_src = v.short_src
				end

				if result.source then
					result.source = v.source
				end
			end
		end
	end

	return result
end

-- Mask our function replacements
function BS:MaskJitUtilFuncinfo(trace, funcName, args)
	for k,v in pairs(control) do
		local replacementFunction = BS:GetCurrentFunction(unpack(string.Explode(".", k)))

		if args[1] == replacementFunction then
			return control[funcName].jit_util_funcinfo
		end
	end

	return control[funcName].original(unpack(args))
end

-- -------------------------------------
-- [ SCANNING ]
-- -------------------------------------

-- Check if a file isn't suspicious at first 
function BS:IsSuspicious(str)
	for k,v in pairs(notSuspect) do
		if string.find(str, v, nil, true) then
			return false
		end
	end

	return true
end

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
	if not str then return end

	local IsSuspicious = BS:IsSuspicious(str)

	local strAux = string.gsub(str, " ", "")

	local function ProcessLists(list, list2)
		for k,v in pairs(list) do
			if string.find(strAux, v, nil, true) and
			   not BS:CheckTraceWhitelist(trace) and
			   not BS:CheckFilesWhitelist(trace) then

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
		IsSuspicious = ProcessLists(blacklistHigh) or ProcessLists(blacklistMedium) or ProcessLists(suspect)
	end

	if IsSuspicious and blocked then
		if blocked[1] then
			ProcessLists(blacklistHigh, blocked[1])
			ProcessLists(blacklistHigh_Suspect, blocked[1])
		end

		if blocked[2] then
			ProcessLists(blacklistMedium, blocked[2])
			ProcessLists(blacklistMedium_Suspect, blocked[2])
		end
	end

	if IsSuspicious and warning then
		ProcessLists(suspect, warning)
	end

	return blocked, warning
end

-- Process recusively the files inside the aimed folders according to our white, black and suspect lists
-- Low risk files will be reported in the logs as well, but they won't flood the console with warnings
function BS:ScanFolders(args)
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

	-- Remove backslashes
	for k,v in pairs(folders) do
		folders[k] = string.gsub(v, "\\", "/")
		if string.sub(folders[k], -1) == "/" then
			folders[k] = folders[k]:sub(1, #v - 1)
		end
	end

	-- Easy way to check low risk files (values as table indexes)
	for _,v in pairs(lowRiskFiles) do
		lowRiskFiles_Aux[v] = true
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
	local function ScanFolder(dir)
		if dir == "data/" .. BS_BASEFOLDER then
			return
		end

		local files, dirs = file.Find( dir.."*", "GAME" )

		if not dirs then
			return
		end

		for _, fdir in pairs(dirs) do
			if fdir ~= "/" then -- We can get a / if the start from the root
				ScanFolder(dir .. fdir .. "/")
			end
		end

		for k,v in pairs(files) do
			local ext = string.GetExtensionFromFilename(v)
			local path = dir .. v

			-- Most common infected files
			if not addonsFolder[path] then
				local blocked = {{}, {}}
				local warning = {}
				local pathAux = path

				if v == BS_FILENAME then
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
				if BS:CheckFilesWhitelist(pathAux) then
					return 
				end

				-- Scanning
				BS:ScanString(nil, file.Read(path, "GAME"), blocked, warning)

				local resultString = ""
				local resultTable
				local results

				-- If we have something: build the path, the message and store in the right table
				if #blocked[1] > 0 or #blocked[2] > 0 or #warning > 0 then
					resultString = path

					-- Files inside low risk folders
					for _,v in pairs(lowRiskFolders) do
						start = string.find(pathAux, v, nil, true)
						if start == 1 then
							results = lowRisk

							break
						end
					end

					if not results then
						-- Detected non lua files are VERY unsafe
						if ext ~= "lua" then
							results = highRisk
						-- or check if it's a low risk file
						elseif lowRiskFiles_Aux[pathAux] then
							results = lowRisk
						-- or set the risk based on the detection precedence
						else
							if #blocked[1] > 0 or #blocked[2] > 2 then results = highRisk end
							if not results and #blocked[2] > 0 then results = mediumRisk end
							if not results and #warning > 0 then results = lowRisk end
						end
					end

					-- If we have a low risk table selected but there two or more high risk detections,
					-- set it to medium risk state
					if results == lowRisk and #blocked[1] >= 2 then
						results = mediumRisk
					end

					-- Build, print and store the result
					resultString = resultString .. JoinResults(blocked[1], "[!!]")
					resultString = resultString .. JoinResults(blocked[2], "[!]")
					resultString = resultString .. JoinResults(warning, "[.]")
					resultString = resultString .. "\n"

					table.insert(results, resultString)

					if results ~= lowRisk then
						if results == highRisk then
							print("[[[ HIGH RISK ]]] ---------------------------------------------------------------------------- <<<")
						end

						print(resultString)
					end
				end
			end
		end 
	end

	print("\n\n -------------------------------------------------------------------")
	print(BS_ALERT .. " Scanning GMod and all the mounted contents...\n")

	-- Manually installed addons have a higher chance of infection. Scanning the addons folder
	-- directly instead of the Lua mount gives me the full paths to the files. To avoid scanning
	-- a file twice, I record what we're doing and compare it later.
	if addonsFolderScan then
		ScanFolder("addons/")
		addonsFolderScan = false
	end

	-- Scan the other selected folders
	for _,folder in pairs(folders) do
		if folder == "" or file.Exists(folder .. "/", "GAME") then
			ScanFolder(folder == "" and folder or folder .. "/")
		end
	end

	BS:ReportFolder(highRisk, mediumRisk, lowRisk)

	print("\nLow risk results: ", tostring(#lowRisk))
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

	The security is performed by automatically blocking executions,
	correcting some	changes and warning about suspicious activity,
	but you may also:

	1) Set custom black and white lists directly in the main file.
	Don't leave warnings circulating on the console and make exceptions
	whenever you want.

	2) Scan your addons and investigate the results:
	|--> "bs_scan": Recursively scan GMod and all the mounted contents
	|--> "bs_scan <folder>": Recursively scan the seleceted folder

	All logs are located in: "garrysmod/data/]] .. BS_BASEFOLDER .. [["


	|---------> Version: ]] .. BS_VERSION .. [[


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
	control["debug.getinfo"].filter = BS.MaskDebugGetInfo
	control["jit.util.funcinfo"].filter = BS.MaskJitUtilFuncinfo

	for k,v in pairs(control) do
		control[k].original = BS:GetCurrentFunction(unpack(string.Explode(".", k)))
		control[k].short_src = debug.getinfo(control[k].original).short_src
		control[k].source = debug.getinfo(control[k].original).source
		control[k].jit_util_funcinfo = jit.util.funcinfo(control[k].original)
		BS:SetDetouring(k, v.filter)
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

-- Isolate our enironment
for k,v in pairs(BS)do
	if isfunction(v) then
		setfenv(v, __G_SAFE)
	end
end

-- Command to scan folders
concommand.Add("bs_scan", function(ply, cmd, args)
    BS:ScanFolders(args)
end)

-- Protection started
BS:Initialize()
