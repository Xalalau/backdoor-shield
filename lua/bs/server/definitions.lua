--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- MAIN CONFIGURATIONS
-- -----------------------------------------------------------------------------------

BS.devMode = true -- If true, will enable code live reloading, the command bs_tests and more time without hibernation (unsafe! Only used while developing)
BS.liveProtection = true -- If true, will block backdoors activity. If off, you'll only have the the file scanner.

-- These extensions will never be considered as not suspicious by the file scanner
-- The file scanner will only look for these extensions when running bs_scan_fast 
BS.dangerousExtensions = { "lua", "txt" , "vmt", "dat", "json" }

-- GAME FUNCTIONS PROTECTION
-- -----------------------------------------------------------------------------------

BS.control = {
--[[
	["some.game.function"] = {                -- Declaring a function in a field here will keep if safe from detouring
		detour = function                     -- Automatically managed, just ignore. It's the detour function address
		filters = string or { string, ... }   -- Internal function names. They'll execute any extra security checks we want (following the declared order)
		failed = type                         -- Set "failed" if you've set "filters" and need to return fail values other than the default or nil
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
	["require"] = { filters = { "Filters_CheckStack" } },
	["BroadcastLua"] = { filters = { "Filters_CheckStack" } },
	["pcall"] = { filters = { "Filters_CheckStack" } },
	["xpcall"] = { filters = { "Filters_CheckStack" } },
	["Error"] = {},
	["jit.util.funck"] = {},
	["util.NetworkIDToString"] = { filters = { "Filters_CheckStack" } },
	["TypeID"] = {},
	["timer.Simple"] = { filters = { "Filters_CheckTimers" } },
	["timer.Create"] = { filters = { "Filters_CheckTimers" } },
	["file.Read"] = {},
	["file.Write"] = {},
}

-- Whitelist for Filters_CheckStack combinations.
-- e.g. { "pcall", "BroadcastLua" } means that a BroadcastLua() inside a pcall() will not generate a detection
BS.whitelistedCallerCombos = {
	{ "timer.Simple", "timer.Create" },
	{ "timer.Create", "timer.Simple" },
	{ "timer.Simple", "timer.Simple" },
	{ "timer.Create", "timer.Create" },
}

-- SCAN LISTS
-- -----------------------------------------------------------------------------------

-- Low risk files and folders
--   Detections from these places will be considered low risk on live detections and file
--   scans (at first, in this case), so they'll print smaller logs and ignore detours.

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

-- Whitelist http.Fetch() and http.Post() urls
--  Don't scan the downloaded content, just run it normally to start checking again.
BS.whitelistUrls = {
	"http://www.geoplugin.net/",
}

-- Whitelist TRACE ERRORS
--   Ignore detections containging a line from here in its trace
BS.whitelistTraceErrors = {
	"lua/entities/gmod_wire_expression2/core/extloader.lua:86", -- Wiremod
	"gamemodes/darkrp/gamemode/libraries/simplerr.lua:", -- DarkRP
	"lua/autorun/streamradio_loader.lua:254", -- 3D Stream Radio
	"lua/ulib/shared/plugin.lua:186", -- ULib
	"lua/dlib/sh_init.lua:105", -- DLib
	"lua/dlib/core/loader.lua:32", -- DLib
	"lua/dlib/modules/i18n/sh_loader.lua:66", -- DLib
}

-- Whitelist texts
--   Ignore detections containing the listed texts. Be very careful to add items to this list!
BS.whitelistSnippets = {
}

-- Detections with these chars will be considered as not suspect (at first) on files/snippets that are not
-- part of the dangerousExtensions list. This lowers security a bit but eliminates a lot of false positives.
BS.notSuspect = {
	"ÿ",
	"", -- 000F
}

-- Extremely edge snippets and syntax for most normal Lua scripts
BS.blacklistHigh = {
	"=_G", -- Note: used by backdoors to start hiding names or create a better environment
	"(_G)",
	",_G,",
	"!true",
	"!false",
}

-- Very uncommon snippets and syntax for most normal Lua scripts
BS.blacklistHigh_suspect = {
	"‪", -- LEFT-TO-RIGHT EMBEDDING
}

-- Functions that backdoors love to use!
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

-- Uncommon snippets and syntax for most normal Lua scripts
BS.blacklistMedium_suspect = {
	"_G[",
	"_G.",
}

-- Functions that some backdoors use
BS.suspect = {
	"pcall",
	"xpcall",
	"SendLua",
}

-- More common snippets and syntax that some backdoors use
BS.suspect_suspect = {
	"]()",
	"0x",
	"\\x",
}
