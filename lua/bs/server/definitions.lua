--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- MAIN CONFIGURATIONS
-- -----------------------------------------------------------------------------------

BS.devMode = true -- If true, will enable code live reloading, the command bs_tests and more time without hibernation (unsafe! Only used while developing)
BS.liveProtection = true -- If true, will block backdoors activity. If off, you'll only have the the file scanner.

BS.dangerousExtensions = { "lua", "txt" , "vmt", "dat", "json" }

-- GAME FUNCTIONS PROTECTION
-- -----------------------------------------------------------------------------------

--   Declaring a function in a field will keep if safe from detours
--   Declaring filters will hook functions to execute security checks, following the given order
BS.control = {
--[[
	["some.game.function"] = {
		detour = function                     -- Automatically managed, just ignore. It's the detour function address
		filters = string or { string, ... }   -- Write internal function names to execute security checks. Execution is done in order
		failed = type                         -- Set "failed" if you have "filters" and need to return fail values other than the default or nil
	},
]]
	["debug.getinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectDebugGetinfo" }, failed = {} },
	["jit.util.funcinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectAddresses" } },
	["getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" } },
	["debug.getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" } },
	["tostring"] = { filters = "Filters_ProtectAddresses" },
	["http.Post"] = { filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" } },
	["http.Fetch"] = { filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" } },
	["CompileString"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
	["CompileFile"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" } },
	["RunString"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
	["RunStringEx"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
	["HTTP"] = { filters = { "Filters_CheckStack" } },
	["hook.Add"] = {},
	["hook.Remove"] = {},
	["hook.GetTable"] = {},
	["net.Receive"] = {},
	["net.Start"] = {},
	["net.ReadHeader"] = {},
	["net.WriteString"] = {},
	["require"] = {},
	["BroadcastLua"] = { filters = { "Filters_CheckStack" } },
	["pcall"] = { filters = { "Filters_CheckStack" } },
	["xpcall"] = { filters = { "Filters_CheckStack" } },
	["Error"] = {},
	["jit.util.funck"] = {},
	["util.NetworkIDToString"] = { filters = { "Filters_CheckStack" } },
	["TypeID"] = {},
	["timer.Simple"] = { filters = { "Filters_CheckStack", "Filters_CheckTimers" } },
	["timer.Create"] = { filters = { "Filters_CheckStack", "Filters_CheckTimers" } },
	["file.Read"] = {},
	["file.Write"] = {},
}

-- Whitelist for Filters_CheckStack combinations.
-- e.g. { "timer.Simple", "timer.Create" } means that a timer.Create() inside a timer.Simple() will not generate a detection
BS.whitelistedCallerCombos = {
	{ "timer.Simple", "timer.Create" },
	{ "timer.Create", "timer.Simple" },
	{ "timer.Simple", "timer.Simple" },
	{ "timer.Create", "timer.Create" },
}

-- SCAN LISTS
-- -----------------------------------------------------------------------------------

-- These lists are used to check urls, files and codes passed as argument
-- Note: these lists are locked here for proper security
-- Note2: I'm not using patterns

-- Low risk files and folders
-- 1) When scanning the game, these files and folders will be considered low risk, so they won't flood
-- the console with warnings (but they'll be normally reported in the logs);
-- 2) If a detour is detected here, it'll only be reported, not undone. Be very careful with these locations!

BS.lowRiskFolders = {
	"gamemodes/darkrp/",
	"lua/entities/gmod_wire_expression2/",
	"lua/wire/",
	"lua/ulx/",
	"lua/ulib/",
	"lua/dlib/",
	"lua/xlib/",
	"lua/_awesome/",
	"lua/serverguard/",
	"lua/klib/",
	"lua/pac3/"
}

BS.lowRiskFiles = {
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
-- Note: protected functions detouring will still be detected and undone
-- Note2: any protected functions called will still be scanned
-- Note3: insert an url starting with http or https and ending with a "/", like https://google.com/
BS.whitelistUrls = {
	"http://www.geoplugin.net/",
}

-- Whitelist TRACE ERRORS
-- Any detections with the informed trace will be ignored!
-- Note: protected functions detouring will still be detected and undone
BS.whitelistTraceErrors = {
	"lua/entities/gmod_wire_expression2/core/extloader.lua:86", -- Wiremod
	"gamemodes/darkrp/gamemode/libraries/simplerr.lua:", -- DarkRP
	"lua/autorun/streamradio_loader.lua:254", -- 3D Stream Radio
	"lua/ulib/shared/plugin.lua:186", -- ULib
	"lua/dlib/sh_init.lua:105", -- DLib
	"lua/dlib/core/loader.lua:32", -- DLib
	"lua/dlib/modules/i18n/sh_loader.lua:66", -- DLib
}

-- Whitelist contents
-- Detections containing the listed snippets will be ignored
-- Note: if misused it'll whitelist all types of files! Be very careful and Don't show it to anyone!
BS.whitelistContents = {
}

-- Detections with these chars will be considered as not suspect at first
-- This lowers security a bit but eliminates a lot of false positives
BS.notSuspect = {
	"ÿ",
	"", -- 000F
}

-- High chance of direct backdoor detection (all files)
BS.blacklistHigh = {
	"=_G", -- !! Used by backdoors to start hiding names. Also, there is an extra check in the code to avoid incorrect results.
	"(_G)",
	",_G,",
	"!true",
	"!false",
}

-- High chance of direct backdoor detection (suspect code only)
BS.blacklistHigh_suspect = {
	"‪", -- LEFT-TO-RIGHT EMBEDDING
}

-- Medium chance of direct backdoor detection (all files)
BS.blacklistMedium = {
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
BS.blacklistMedium_suspect = {
	"_G[",
	"_G.",
}

-- Low chance of direct backdoor detection (all files)
BS.suspect = {
	"pcall",
	"xpcall",
	"SendLua",
}

-- Low chance of direct backdoor detection (suspect code only)
BS.suspect_suspect = {
	"]()",
	"0x",
	"\\x",
}
