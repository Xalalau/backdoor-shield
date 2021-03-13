--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Functions that need to be protected
-- Some are scanned or serve some special purpose
BS.control = {
--[[
	["some.game.function"] = {           -- Max. of 2 dots. Ex, 1 dot: http.Fecth = _G["http"]["Fetch"]
		detour = function                -- Automatically managed, just ignore. Detour function address
		filter = string                  -- An "internal BS function name" to execute extra protections
	},
]]
	["debug.getinfo"] = { filter = "Validate_Adrresses" },     -- Isolate our environment
	["jit.util.funcinfo"] = { filter = "Validate_Adrresses" }, -- Isolate our environment
	["getfenv"] = { filter = "Validate_Environment" },        -- Isolate our environment and alert the user
	["debug.getfenv"] = { filter = "Validate_Environment" },  -- Isolate our environment and alert the user
	["tostring"] = { filter = "Validate_Adrresses" },          -- Isolate our environment
	["http.Post"] = { filter = "Validate_HttpFetchPost" },    -- scanned
	["http.Fetch"] = { filter = "Validate_HttpFetchPost" },   -- scanned
	["CompileString"] = { filter = "Validate_StrCode" },      -- scanned
	["CompileFile"] = { filter = "Validate_StrCode" },        -- scanned
	["RunString"] = { filter = "Validate_StrCode" },          -- scanned
	["RunStringEx"] = { filter = "Validate_StrCode" },        -- scanned
	["HTTP"] = {},
	["hook.Add"] = {},
	["hook.Remove"] = {},
	["hook.GetTable"] = {},
	["net.Receive"] = {},
	["net.Start"] = {},
	["net.ReadHeader"] = {},
	["net.WriteString"] = {},
	["require"] = {},
	["pcall"] = {},
	["xpcall"] = {},
	["Error"] = {},
	["jit.util.funck"] = {},
	["util.NetworkIDToString"] = {},
	["TypeID"] = {},
}

-- SCAN LISTS

-- These lists are used to check urls, files and codes passed as argument
-- Note: these lists are locked here for proper security
-- Note2: I'm not using patterns
-- -----------------------------------------------------------------------------------

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
	"lua/klib/"
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
