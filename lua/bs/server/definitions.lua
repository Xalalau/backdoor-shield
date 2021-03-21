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

-- The folders checked by the scanner if none are specified (bs_scan)
BS.foldersToScan = { "lua", "gamemode", "data" }

-- REAL TIME PROTECTION SETUP
-- -----------------------------------------------------------------------------------

-- In-game backdoor detection and self preservation

BS.control = {
--[[
	["some.game.function"] = {                -- Declaring a function in a field will keep it safe from detouring
		detour = function                     -- Automatically managed, just ignore. It's the detour function address
		filters = string or { string, ... }   -- Add internal function names. They'll execute any extra security checks we want (following the declared order)
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
	["require"] = {},
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

-- WHITE LISTS
-- -----------------------------------------------------------------------------------

-- Whitelist for Filters_CheckStack combinations.
-- e.g. { "pcall", "BroadcastLua" } means that a BroadcastLua() inside a pcall() will not generate a detection
BS.whitelistedCallerCombos = {
}

-- Low-risk files and folders
--   Detections from these places will be considered low-risk on live detections and, at
--   first, on file scans - so they'll print smaller logs.
--[[
   Attention!! Low-risk locations will cause detouring of protected functions to be
   ignored! This means other addons will steal the game functions, do something with them
   and most problably call us back because we keep the original addresses locked down.
]]

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
--   Don't scan the downloaded content, just run it normally to start checking again.
BS.whitelistUrls = {
	"http://www.geoplugin.net/",
}

-- Whitelist TRACE ERRORS
--   Ignore detections containging one of these lines in its trace
BS.whitelistTraceErrors = {
	"lua/entities/gmod_wire_expression2/core/extloader.lua:86", -- Wiremod
	"gamemodes/darkrp/gamemode/libraries/simplerr.lua:", -- DarkRP
	"lua/autorun/streamradio_loader.lua:254", -- 3D Stream Radio
	"lua/ulib/shared/plugin.lua:186", -- ULib
	"lua/dlib/sh_init.lua:105", -- DLib
	"lua/dlib/core/loader.lua:32", -- DLib
	"lua/dlib/modules/i18n/sh_loader.lua:66", -- DLib
}

-- Whitelist snippets
--   Ignore detections containing the listed "texts".
BS.whitelistSnippets = {
	-- Be very careful to add items to this list! Ideally, it should never be used.
}

-- Detections with these chars will be considered as not suspect (at first) for files and snippets that not
-- fit into dangerousExtensions list. This lowers security a bit but eliminates a lot of false positives.
BS.notSuspect = {
	"ÿ",
	"", -- 000F
}

-- BLACK AND SUSPECT LISTS
-- -----------------------------------------------------------------------------------
--[[
  In the real-time protection scenario, blacklists cause warnings and interruptions in
  execution, while suspect lists add details to the logs and, consequently, help us
  to better identify threats.

  When used by the file scanner, both lists generate complete reports. In this case,
  we use the high, medium and low divisions to assign a weight to each detection and
  calculate a risk. For example. many low-risk detections can be listed as medium-risk,
  while some medium plus low-risk detections can be heavy enough to be listed as high-
  risk. This system helps to make detected backdoors more visible by showing them above
  irrelevant results - and, in fact, they end up concentraded on high-risk with some
  in the medium. I've never seen a detection in the low-risk section.

  Finally, if someone makes the foolish decision to add a common pattern to one of these
  lists, the addon will return many false positives, probably turning the console into
  a giant log hell.

  Be wise, be safe. And thanks for being here.
]]

-- Very edge snippets, syntax and symbols that only backdoors use
BS.blacklistHigh = {
	"‪", -- LEFT-TO-RIGHT EMBEDDING
	"(_G)",
	",_G,",
	"!true",
	"!false",
}

-- Edge snippets, syntax and symbols that almost only backdoors use
BS.blacklistHigh_suspect = {
	"=_G", -- Note: used by backdoors to start hiding names or create a better environment
}

-- Functions that backdoors love to use!
--   They usually run one inside the other or set/get improper stuff that almost only they need.
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

-- Snippets, syntax and symbols that sometimes appear in normal scripts, but are usually seen in backdoors
BS.blacklistMedium_suspect = {
	"_G[",
	"_G.",
}

-- Functions that some backdoors and regular scripts use - They aren't worth blocking, just warning.
--   I use these detections to increase the potential risk of others while scanning files.
BS.suspect = {
	"pcall",
	"xpcall",
	"SendLua",
}

-- Snippets, syntax and symbols that some backdoors and regular scripts use - They aren't worth blocking, just warning.
--   I use these detections to increase the potential risk of others while scanning files, but with a very light weight.
BS.suspect_suspect = {
	"]()",
	"0x",
	"\\x",
}
