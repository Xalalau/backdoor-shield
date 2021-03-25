--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]


-- MAIN CONFIGURATIONS
-- -----------------------------------------------------------------------------------

-- If true, will enable code live reloading, the command bs_tests and more time without hibernation
--   Unsafe! Only used while developing
BS.devMode = true


-- REAL TIME PROTECTION
-- -----------------------------------------------------------------------------------

-- In-game detouring protection and backdoor detection

BS.live = {
	-- If true, will block backdoors activity in real time
	backdoorDetection = true, 

	--[[
		["some.game.function"] = {                -- Declaring a function in a field will keep it safe from detouring
			detour = function                     -- Detoured function address (Automatically managed)
			protectStack = bool                   -- If true, the Filters_CheckStack functions will generate a detection when meeting "some.game.function"
				isStackWarning = bool             -- Set "isStackWarning" if you've set multiple "protectStack" and need to generate a stack warning instead of a blocking
			filters = string or { string, ... }   -- Internal functions to execute any extra security checks we want (following the declared order)
				failed = type                     -- Set "failed" if you've set multiple "filters" and need to return fail values other than nil
		},
	]]
	control = {
		["Ban"] = { filters = { "Filters_CheckStack" } },
		["BroadcastLua"] = { protectStack = true, filters = { "Filters_CheckStack" } },
		["cam.Start3D"] = { filters = { "Filters_CheckStack" } },
		["ChatPrint"] = { filters = { "Filters_CheckStack" } },
		["ClientsideModel"] = { filters = { "Filters_CheckStack" } },
		["CompileFile"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" } },
		["CompileString"] = { protectStack = true, filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
		["concommand.Add"] = { filters = { "Filters_CheckStack" } },
		["debug.getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" } },
		["debug.getinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectDebugGetinfo" }, failed = {} },
		["debug.getregistry"] = { filters = { "Filters_CheckStack" } },
		["Error"] = {},
		["file.Delete"] = { filters = { "Filters_CheckStack" } },
		["file.Exists"] = { filters = { "Filters_CheckStack" }, isStackWarning = true },
		["file.Find"] = { filters = { "Filters_CheckStack" }, isStackWarning = true },
		["file.Read"] = { filters = { "Filters_CheckStack" }, isStackWarning = true },
		["file.Write"] = { filters = { "Filters_CheckStack" } },
		["game.CleanUpMap"] = { filters = { "Filters_CheckStack" } },
		["game.ConsoleCommand"] = { filters = { "Filters_CheckStack" } },
		["game.KickID"] = { filters = { "Filters_CheckStack" } },
		["getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" } },
		["hook.Add"] = { filters = { "Filters_CheckStack" } },
		["hook.GetTable"] = { filters = { "Filters_CheckStack" } },
		["hook.Remove"] = { filters = { "Filters_CheckStack" } },
		["HTTP"] = { filters = { "Filters_CheckStack" } },
		["http.Fetch"] = { protectStack = true, filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" } },
		["http.Post"] = { protectStack = true, filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" } },
		["include"] = { filters = { "Filters_CheckStack" } },
		["jit.util.funcinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectAddresses" } },
		["jit.util.funck"] = { filters = { "Filters_CheckStack" } },
		["Kick"] = { filters = { "Filters_CheckStack" } },
		["net.ReadHeader"] = { filters = { "Filters_CheckStack" } },
		["net.ReadString"] = { protectStack = true, filters = { "Filters_CheckStack" } },
		["net.Receive"] = { filters = { "Filters_CheckStack" } },
		["net.Start"] = { filters = { "Filters_CheckStack" } },
		["net.WriteString"] = { filters = { "Filters_CheckStack" } },
		["pcall"] = { filters = { "Filters_CheckStack" } },
		["PrintMessage"] = { filters = { "Filters_CheckStack" } },
		["require"] = { filters = { "Filters_CheckStack" } },
		["RunConsoleCommand"] = { filters = { "Filters_CheckStack" } },
		["RunString"] = { protectStack = true, filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
		["RunStringEx"] = { protectStack = true, filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "" },
		["setfenv"] = { filters = { "Filters_CheckStack" } },
		["sound.PlayURL"] = { filters = { "Filters_CheckStack" } },
		["surface.PlaySound"] = { filters = { "Filters_CheckStack" } },
		["timer.Create"] = { filters = { "Filters_CheckStack", "Filters_CheckTimers" }, isStackWarning = true },
		["timer.Destroy"] = { filters = { "Filters_CheckStack" } },
		["timer.Exists"] = { filters = { "Filters_CheckStack" }, isStackWarning = true },
		["timer.Simple"] = { filters = { "Filters_CheckStack", "Filters_CheckTimers" }, isStackWarning = true },
		["tostring"] = { filters = "Filters_ProtectAddresses" },
		["util.AddNetworkString"] = { filters = { "Filters_CheckStack" } },
		["util.NetworkIDToString"] = { filters = { "Filters_CheckStack" } },
		["util.ScreenShake"] = { filters = { "Filters_CheckStack" } },
		["xpcall"] = { filters = { "Filters_CheckStack" } },
	},
}


-- ARGUMENTS LISTS
-- -----------------------------------------------------------------------------------

-- Some extra blacklists for arguments
BS.arguments = {
	blacklists = {
		-- Every function set as Filters_CheckStack with isStackWarning = nil will populate this list
		functions = {},
		snippets = {
			"‪", -- LEFT-TO-RIGHT EMBEDDING
			"(_G)",
			",_G,",
			"!true",
			"!false",
			"_G[",
			"_G.",
			"_R[",
			"_R.",
			"]()",
			"0x",
			"\\x",
			"STEAM_0:",
			"startingmoney", -- DarkRP var
		},
		cvars = {
			"rcon_password",
			"sv_password",
			"sv_gravity",
			"sv_friction",
			"sv_allowcslua",
			"sv_password",
			"sv_hostname",
			"rp_resetallmoney",
			"hostport",
		},
	},
	suspect = {
		-- Every function set as Filters_CheckStack withe isStackWarning = true will populate this list
		functions = {}
	}
}

-- FILES SCANNER
-- -----------------------------------------------------------------------------------

-- Don't add common patterns to the blacklists and suspect lists, or the addon will return
-- many false positives and probably turn the console into a giant log hell.

BS.filesScanner = {
	-- These extensions will never be considered as not suspicious by the file scanner
	-- bs_scan scans only for files with these extensions
	dangerousExtensions = { "lua", "txt" , "vmt", "dat", "json" },

	-- The folders checked by the scanner if none are specified (bs_scan)
	foldersToScan = { "lua", "gamemode", "data" },

	-- Print low-risk results in the console
	printLowRisk = false,

	-- Discard result if it's from file with only BS.filesScanner.suspect_suspect detections
	discardVeryLowRisk = true,

	-- Ignore our own folders
	ignoreBSFolders = true,

	-- Detections with these chars will be considered as not suspect (at first) for files and snippets that not
	-- fit into scanner.dangerousExtensions list.
	--   Avoid false positives with non Lua files
	notSuspect = {
		"ÿ",
		"", -- 000F
	},

	-- Very edge snippets, syntax and symbols that only backdoors use
	--   High-risk
	blacklistHigh = {
		"‪", -- LEFT-TO-RIGHT EMBEDDING
		"(_G)",
		",_G,",
		"!true",
		"!false",
	},

	-- Edge snippets, syntax and symbols that almost only backdoors use
	--   High-risk
	blacklistHigh_suspect = {
		"=_G", -- Note: used by backdoors to start hiding names or create a better environment
	},

	-- Functions that backdoors love to use!
	--   They usually run one inside the other or set/get improper stuff that almost only they need.
	--   Medium-risk
	blacklistMedium = {
		"RunString",
		"RunStringEx",
		"CompileString",
		"CompileFile",
		"BroadcastLua",
		"setfenv",
		"http.Fetch",
		"http.Post",
		"debug.getinfo",
		"game.ConsoleCommand",
	},

	-- Snippets, syntax and symbols that sometimes appear in normal scripts, but are usually seen in backdoors
	--   Medium-risk
	blacklistMedium_suspect = {
		"_G[",
		"_G.",
		"_R[",
		"_R."
	},

	-- Functions that some backdoors and regular scripts use - They aren't worth blocking, just warning.
	--   I use these detections to increase the potential risk of others while scanning files.
	--   Low-risk
	suspect = {
		"pcall",
		"xpcall",
		"SendLua",
	},

	-- Snippets, syntax and symbols that some backdoors and regular scripts use - They aren't worth blocking, just warning.
	--   I use these detections to increase the potential risk of others while scanning files, but with a very light weight.
	--   Low-risk
	suspect_suspect = {
		"]()",
		"0x",
		"\\x",
	},
}


-- LOW-RISK LISTS
-- -----------------------------------------------------------------------------------

-- Detections from these lists are considered low risk on the file scanner and generate
-- only warnings on live protection. Even detour detections only alert!

BS.lowRisk= {
	-- Low-risk folders
	folders = {
	},

	-- Low-risk files
	files = {
	},
}


-- WHITELISTS
-- -----------------------------------------------------------------------------------

-- Detections from these lists don't appear on the file scanner and aren't protected
-- in any way. No blocking, no warnings, no logs. Detours are completely ignored!

BS.whitelists = {
	-- Whitelisted files
	folders = {
		"lua/wire/", -- Wiremod
		"lua/ulx/", -- ULX
		"lua/ulib/", -- Ulib
		"lua/pac3/", -- Pac3
		"lua/smh", -- Stop Motion Helper
		"lua/playx", -- PlayX
	},

	-- Whitelisted folders
	files = {
		"lua/entities/gmod_wire_expression2/core/extloader.lua", -- Wiremod
		"gamemodes/base/entities/entities/lua_run.lua" -- GMod
	},

	-- Whitelist for Filters_CheckStack combinations
	stack = {
		--  { "CompileString", "BroadcastLua" } -- e.g. it means that a BroadcastLua() inside a CompileString() won't generate a detection
		{ "RunString", "RunString" }
	},

	-- Whitelist http.Fetch() and http.Post() urls
	--   Don't scan the downloaded content, just run it normally to start checking again
	urls = {
		"http://www.geoplugin.net/",
	},

	-- Whitelist snippets
	--   Ignore detections containing the listed "texts"
	--   Be very careful to add items to this list! Ideally, it should never be used
	snippets = {
	},
}