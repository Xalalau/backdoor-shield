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
	-- Turn on the real time detections
	isOn = true, 

	-- Block backdoors activity
	-- This should never be turned off, but it's here in case you want to get infected on purpose to generate more logs
	blockThreats = true, 

	-- Live protection main control table
	--[[
		["some.game.function"] = {                -- Declaring a function in a field will keep it safe from external detouring
			detour = function                     -- Our detoured function address (Automatically managed)
			filters = string or { string, ... }   -- Internal functions to execute any extra security checks we want (following the declared order)
				failed = type                     -- Set "failed" if you've set multiple "filters" and need to return fail values other than nil
				fast = bool                       -- Set "fast" if you've set one or none "filters" and need to run VERY fast (much less code, ignore whitelists and low-risk lists)

			-- If you've set the "Filters_CheckStack" filter:

			stackBanLists = { string, ...}        -- You can create blacklists of functions by adding names here. "some.game.function" will be grouped with others in blacklists.functions[the selected name]
			protectStack = { string, ...}         -- Select lists from blacklists.functions (created by the stackBanLists option) to block "some.game.function" from calling any of them
		},

		Current stackBanLists names:
			harmful
			doubtful
			observed
	]]
	control = {
		["Ban"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["BroadcastLua"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["cam.Start3D"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["ChatPrint"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["ClientsideModel"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["CompileFile"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, stackBanLists = { "harmful" } },
	-- To-do: Test
	["CompileString"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, stackBanLists = { "harmful" }, failed = "" },
		["concommand.Add"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["debug.getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" }, stackBanLists = { "harmful" } },
		["debug.getinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectDebugGetinfo" }, stackBanLists = { "harmful" }, failed = {} },
		["debug.getregistry"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["Error"] = {},
		["file.Delete"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["file.Exists"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
	-- To-do: needs fix for Pac3
	--["file.Find"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["file.Read"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["file.Write"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["game.CleanUpMap"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
	-- To-do: Scan commands
	["game.ConsoleCommand"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["game.KickID"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["getfenv"] = { filters = { "Filters_CheckStack", "Filters_ProtectEnvironment" }, stackBanLists = { "harmful" } },
		["hook.Add"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["hook.GetTable"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["hook.Remove"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["HTTP"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["http.Fetch"] = { filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" }, stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["http.Post"] = { filters = { "Filters_CheckStack", "Filters_CheckHttpFetchPost" }, stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["include"] = {},
		["jit.util.funcinfo"] = { filters = { "Filters_CheckStack", "Filters_ProtectAddresses" }, stackBanLists = { "harmful" } },
		["jit.util.funck"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["Kick"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["net.ReadHeader"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
	-- To-do: Scan text
	["net.ReadString"] = {},
	-- To-do: 
	["net.Receive"] = { filters = { "Filters_CheckStack" }, protectStack = { "harmful" } },
		["net.Start"] = {},
	-- To-do: Scan text
	["net.WriteString"] = {},
	-- To-do: Test trace persistence
	["pcall"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["PrintMessage"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["require"] = {},
	-- To-do: Scan commands
	["RunConsoleCommand"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
		["RunString"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "", stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["RunStringEx"] = { filters = { "Filters_CheckStack", "Filters_CheckStrCode" }, failed = "", stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["setfenv"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["sound.PlayURL"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["surface.PlaySound"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "observed" } },
		["timer.Create"] = { filters = "Filters_CheckTimers" },
		["timer.Destroy"] = {},
		["timer.Exists"] = {},
		["timer.Simple"] = { filters ="Filters_CheckTimers" },
		["tostring"] = { filters = "Filters_ProtectAddresses", fast = true },
		["util.AddNetworkString"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["util.NetworkIDToString"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
		["util.ScreenShake"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "doubtful" } },
	-- To-do: Test trace persistence
	["xpcall"] = { filters = { "Filters_CheckStack" }, stackBanLists = { "harmful" } },
	},

	blacklists = {
		-- Every stackBanLists declaration in BS.control will merge into a functions["stackBanLists name"] list here
		functions = {},

		-- Snippets, syntax and symbols that are usually only seen in backdoors
		snippets = {
			"‪", -- U+202a
			"=_G",
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

		-- Commands that are usually executed by backdoors
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
	}
}


-- FILES SCANNER
-- -----------------------------------------------------------------------------------

-- Don't add common patterns to the blacklists and suspect lists, or the addon will return
-- many false positives and probably turn the console into a giant log hell.

BS.filesScanner = {
	-- These extensions will never be considered as not suspect by the file scanner.
	-- The bs_scan command scans only for files with these extensions.
	dangerousExtensions = { "lua", "txt" , "vmt", "dat", "json" },

	-- The folders checked by the scanner if none are specified (bs_scan command)
	foldersToScan = { "addons", "lua", "gamemode", "data" },

	-- Print low-risk results in the console
	printLowRisk = false,

	-- Discard a result if it's from a file with only BS.filesScanner.suspect_suspect detections
	discardVeryLowRisk = true,

	-- Ignore our own folders
	ignoreBSFolders = true,

	-- Detections with these chars will be considered as not suspect (at first) for tested strings
	-- that aren't from files with extensions listed in scanner.dangerousExtensions.
	--   Avoid false positives with non Lua files
	notSuspect = {
		"ÿ",
		"", -- 000F
	},

	-- Very edge snippets, syntax and symbols that virtually only backdoors use
	--   High-risk
	blacklistHigh = {
		"‪", -- U+202a
		"(_G)",
		",_G,",
		"!true",
		"!false",
	},

	-- Edge snippets, syntax and symbols that virtually only backdoors use
	--   High-risk
	blacklistHigh_suspect = {
		"=_G", -- Note: used by backdoors to start hiding names or create a better environment
	},

	-- Functions that sometimes appear in normal scripts, but are usually seen in backdoors
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

-- Exception: BS.live.control functions configured with the "fast" option

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

-- Exception: BS.live.control functions configured with the "fast" option

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
		{ "RunString", "RunString" },
		{ "pcall", "pcall" },
		{ "xpcall", "xpcall" },
		{ "pcall", "xpcall" },
		{ "xpcall", "pcall" }
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