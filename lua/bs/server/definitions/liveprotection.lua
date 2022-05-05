--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- REAL TIME PROTECTION
-- -----------------------------------------------------------------------------------

-- In-game detouring protection and backdoor detection

BS.live = {
	-- Turn on the real time detections
	isOn = true, 

	-- Block backdoors activity
	-- This should never be turned off, but it's here in case you want to get infected on purpose to generate more logs
	blockThreats = true, 

	-- Undo detouring on protected functions
	-- This should never be turned off, but it's here in case you want to disable it. Logs will continue to be generated
	undoDetours = true,

	-- Show a small window at the top left alerting admins about detections and warnings
	alertAdmins = true,

	-- Live protection main control table
	--[[
		["some.game.function"] = {                -- Declaring a function in a field will keep it safe from external detouring
			detour = function                     -- Our detoured function address (Automatically managed)
			filters = string or { string, ... }   -- Internal functions to execute any extra security checks we want (following the declared order)
				failed = type                     -- Set "failed" if you've set multiple "filters" and need to return fail values other than nil

			-- If you've set the "Filter_ScanStack" filter:

			stackBanLists = { string, ...}        -- You can create blacklists of functions by adding names here. "some.game.function" will be grouped with others in blacklists.functions[the selected name]
			protectStack = { string, ...}         -- Select lists from blacklists.functions (created by the stackBanLists option) to block "some.game.function" from calling any of them
		},

		Current stackBanLists names:
			harmful
			doubtful
			observed
	]]
	control = {
		["Ban"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["BroadcastLua"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["cam.Start3D"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["ChatPrint"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["ClientsideModel"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["CompileFile"] = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, stackBanLists = { "harmful" } },
	-- To-do: Test
	["CompileString"] = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, stackBanLists = { "harmful" }, failed = "" },
		["concommand.Add"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["debug.getfenv"] = { filters = { "Filter_ScanStack", "Filter_ProtectEnvironment" }, stackBanLists = { "harmful" } },
		["debug.getinfo"] = { filters = { "Filter_ScanStack", "Filter_ProtectDebugGetinfo" }, stackBanLists = { "harmful" }, failed = {} },
		["debug.getregistry"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["Error"] = {},
		["file.Delete"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["file.Exists"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
	-- To-do: needs fix for Pac3
	--["file.Find"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["file.Read"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["file.Write"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["game.CleanUpMap"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
	-- To-do: Scan commands
	["game.ConsoleCommand"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["game.KickID"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["getfenv"] = { filters = { "Filter_ScanStack", "Filter_ProtectEnvironment" }, stackBanLists = { "harmful" } },
		["hook.Add"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["hook.GetTable"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["hook.Remove"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["HTTP"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["http.Fetch"] = { filters = { "Filter_ScanStack", "Filter_ScanHttpFetchPost" }, stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["http.Post"] = { filters = { "Filter_ScanStack", "Filter_ScanHttpFetchPost" }, stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["include"] = {},
		["jit.util.funcinfo"] = { filters = { "Filter_ScanStack", "Filter_ProtectAddresses" }, stackBanLists = { "harmful" } },
		["jit.util.funck"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["Kick"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["net.ReadHeader"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
	-- To-do: Scan text
	["net.ReadString"] = {},
	-- To-do: 
	["net.Receive"] = { filters = { "Filter_ScanStack" }, protectStack = { "harmful" } },
		["net.Start"] = {},
	-- To-do: Scan text
	["net.WriteString"] = {},
	-- To-do: Test trace persistence
	["pcall"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["PrintMessage"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["require"] = {},
	-- To-do: Scan commands
	["RunConsoleCommand"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
		["RunString"] = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, failed = "", stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["RunStringEx"] = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, failed = "", stackBanLists = { "harmful" }, protectStack = { "harmful", "doubtful", "observed" } },
		["setfenv"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["sound.PlayURL"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["surface.PlaySound"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "observed" } },
		["timer.Create"] = { filters = "Filter_ScanTimers" },
		["timer.Destroy"] = {},
		["timer.Exists"] = {},
		["timer.Simple"] = { filters ="Filter_ScanTimers" },
		--["tostring"] = { filters = "Filter_ProtectAddresses" }, -- unstable and slow (remove loose and whitelists checks to test it)
		["util.AddNetworkString"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["util.NetworkIDToString"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
		["util.ScreenShake"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "doubtful" } },
	-- To-do: Test trace persistence
	["xpcall"] = { filters = { "Filter_ScanStack" }, stackBanLists = { "harmful" } },
	},

	blacklists = {
		-- Every stackBanLists declaration in BS.control will merge into a functions["stackBanLists name"] list here
		functions = {},

		-- Snippets, syntax and symbols that are usually only seen in backdoors
		snippets = {
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
	},

	whitelists = {
		-- Whitelisted folders
		folders = {
			"lua/wire", -- Wiremod
			"lua/ulx", -- ULX
			"lua/ulib", -- Ulib
			"lua/pac3", -- Pac3
			"lua/smh", -- Stop Motion Helper
			"lua/playx" -- PlayX
		},
	
		-- Whitelisted files
		files = {
			"lua/entities/gmod_wire_expression2/core/extloader.lua", -- Wiremod
			"lua/entities/info_wiremapinterface/init.lua", -- Wiremod
			"gamemodes/base/entities/entities/lua_run.lua" -- GMod
		},
	
		-- Whitelist for Filter_ScanStack combinations
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
		--   Ignore detections containing the listed texts
		--   Be very careful to add items here! Ideally, this list should never be used
		snippets = {
		},
	},

	-- Loose detections
	--   Detections from these lists will generate only warnings
	loose = {
		-- Loose folders
		folders = {
		},

		-- Loose files
		files = {
		},
	}
}
