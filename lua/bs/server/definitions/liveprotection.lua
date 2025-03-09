--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
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

    -- Show a small window at the top left alerting admins about detections and warnings
    alertAdmins = true,

    -- Undo detouring on protected functions
    -- This should never be turned off, but it's here in case you want to disable it. Logs will continue to be generated
    protectDetours = true,

    -- Live protection detours table
    --[[
        ["some.game.function"] = {                -- Declaring a function in a field will keep it safe from external detouring
            detour = function                     -- Our detoured function address (Automatically managed)
            filters = string or { string, ... }   -- Internal functions to execute any extra security checks we want (following the declared order)
            retunOnDetection = some result        -- Return a value other than nil if the filters detected a threat and stop the execution
            multiplayerOnly = boolean             -- If the protection is only usefull on multiplayer
        },
    ]]
    detours = {
        ["Ban"]                    = { filters =   "Filter_ScanStack" },
        ["BroadcastLua"]           = { filters =   "Filter_ScanStack" },
        ["cam.Start3D"]            = { filters =   "Filter_ScanStack" },
        ["ChatPrint"]              = { filters =   "Filter_ScanStack" },
        ["ClientsideModel"]        = { filters =   "Filter_ScanStack" },
        ["CompileFile"]            = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, retunOnDetection = function() return end },
        ["CompileString"]          = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, retunOnDetection = "" },-- To-do: Test
        ["concommand.Add"]         = { filters =   "Filter_ScanStack" },
        ["debug.getfenv"]          = { filters = { "Filter_ScanStack", "Filter_ProtectEnvironment" }, retunOnDetection = {} },
        ["debug.getinfo"]          = { filters = { "Filter_ScanStack", "Filter_ProtectDebugGetinfo" }, retunOnDetection = {} },
        ["debug.getregistry"]      = { filters =   "Filter_ScanStack", retunOnDetection = {} },
        ["Error"]                  = {},
        ["file.Delete"]            = { filters =   "Filter_ScanStack", retunOnDetection = false },
        ["file.Exists"]            = { filters =   "Filter_ScanStack" },
        --["file.Find"]            = { filters =   "Filter_ScanStack" },-- To-do: needs fix for Pac3
        ["file.Read"]              = { filters =   "Filter_ScanStack" },
        ["file.Write"]             = { filters =   "Filter_ScanStack" },
        ["game.CleanUpMap"]        = { filters =   "Filter_ScanStack" },
        ["game.ConsoleCommand"]    = { filters =   "Filter_ScanStack" },-- To-do: Scan commands
        ["game.KickID"]            = { filters =   "Filter_ScanStack" },
        ["getfenv"]                = { filters = { "Filter_ScanStack", "Filter_ProtectEnvironment" }, retunOnDetection = {} },
        ["hook.Add"]               = { filters =   "Filter_ScanStack" },
        ["hook.GetTable"]          = { filters =   "Filter_ScanStack", retunOnDetection = {} },
        ["hook.Remove"]            = { filters =   "Filter_ScanStack" },
        ["HTTP"]                   = { filters =   "Filter_ScanStack" },
        ["http.Fetch"]             = { filters = { "Filter_ScanStack", "Filter_ScanHttpFetchPost" } },
        ["http.Post"]              = { filters = { "Filter_ScanStack", "Filter_ScanHttpFetchPost" } },
        ["include"]                = { multiplayerOnly = true }, -- Breaks footstep sounds on singleplayer
        ["jit.util.funcinfo"]      = { filters = { "Filter_ScanStack", "Filter_ProtectAddresses" }, retunOnDetection = {} },
        ["jit.util.funck"]         = { filters =   "Filter_ScanStack" },
        ["Kick"]                   = { filters =   "Filter_ScanStack" },
        ["net.ReadHeader"]         = { filters =   "Filter_ScanStack" },
        ["net.ReadString"]         = {},-- To-do: Scan text 
        ["net.Receive"]            = { filters =   "Filter_ScanStack" },-- To-do: ?
        ["net.Start"]              = {},
        ["net.WriteString"]        = {},-- To-do: Scan text
        ["pcall"]                  = { filters =   "Filter_ScanStack", retunOnDetection = function() return unpack(false, "") end },-- To-do: Test trace persistence
        ["PrintMessage"]           = { filters =   "Filter_ScanStack" },
        ["require"]                = {},
        ["RunConsoleCommand"]      = { filters =   "Filter_ScanStack" },-- To-do: Scan commands
        ["RunString"]              = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, retunOnDetection = "" },
        ["RunStringEx"]            = { filters = { "Filter_ScanStack", "Filter_ScanStrCode" }, retunOnDetection = "" },
        ["SendLua"]                = { filters =   "Filter_ScanStack" },
        ["setfenv"]                = { filters =   "Filter_ScanStack" },
        ["sound.PlayURL"]          = { filters =   "Filter_ScanStack" },
        ["surface.PlaySound"]      = { filters =   "Filter_ScanStack" },
        ["timer.Create"]           = { filters =   "Filter_ScanTimers" },
        ["timer.Destroy"]          = {},
        ["timer.Exists"]           = {},
        ["timer.Simple"]           = { filters =   "Filter_ScanTimers" },
        --["tostring"]             = { filters =   "Filter_ProtectAddresses" },-- unstable and slow (remove loose and whitelists checks to test it)
        ["util.AddNetworkString"]  = { filters =   "Filter_ScanStack" },
        ["util.NetworkIDToString"] = { filters =   "Filter_ScanStack" },
        ["util.ScreenShake"]       = { filters =   "Filter_ScanStack" },
        ["xpcall"]                 = { filters =   "Filter_ScanStack", retunOnDetection = function() return unpack(false, "") end }-- To-do: Test trace persistence
    },

    blacklists = {
        -- List of prohibited strings in filtered function arguments
        -- These filters use the following list: Filter_ScanStrCode
        arguments = {
            -- Any syntax
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
                "startingmoney" -- DarkRP variable
            },

            -- Console commands and variables
            console = {
                "rcon_password",
                "sv_password",
                "sv_gravity",
                "sv_friction",
                "sv_allowcslua",
                "sv_password",
                "sv_hostname",
                "rp_resetallmoney",
                "hostport"
            }
        },

        -- Define a list of functions prohibited from calling a function
        -- These filters use the following list: Filter_ScanStrCode, Filter_ScanStack
        stack = {
            ["Ban"]                    = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["BroadcastLua"]           = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["cam.Start3D"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["ChatPrint"]              = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["ClientsideModel"]        = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["CompileFile"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["CompileString"]          = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["concommand.Add"]         = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["debug.getfenv"]          = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["debug.getinfo"]          = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["debug.getregistry"]      = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["file.Delete"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["file.Exists"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            --["file.Find"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["file.Read"]              = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["file.Write"]             = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["game.CleanUpMap"]        = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["game.ConsoleCommand"]    = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["game.KickID"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["getfenv"]                = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["hook.Add"]               = { "CompileString", "CompileFile", "http.Fetch", "http.Post",              "RunStringEx" },
            ["hook.GetTable"]          = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["hook.Remove"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["HTTP"]                   = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["http.Fetch"]             = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["http.Post"]              = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["jit.util.funcinfo"]      = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["jit.util.funck"]         = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["Kick"]                   = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["net.ReadHeader"]         = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["net.Receive"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["pcall"]                  = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["RunConsoleCommand"]      = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["RunString"]              = { "CompileString", "CompileFile", "http.Fetch", "http.Post",              "RunStringEx", "net.Receive" },
            ["RunStringEx"]            = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["SendLua"]                = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["setfenv"]                = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["sound.PlayURL"]          = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["surface.PlaySound"]      = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["util.AddNetworkString"]  = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["util.NetworkIDToString"] = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" },
            ["util.ScreenShake"]       = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx" },
            ["xpcall"]                 = { "CompileString", "CompileFile", "http.Fetch", "http.Post", "RunString", "RunStringEx", "net.Receive" }
        }
    },

    whitelists = {
        -- Whitelisted folders
        folders = {
            "lua/dlib", -- dLib
            "lua/pac3", -- Pac3
            "lua/playx", -- PlayX
            "lua/smh", -- Stop Motion Helper
            "lua/ulib", -- Ulib
            "lua/ulx", -- ULX
            "lua/wire" -- Wiremod
        },
    
        -- Whitelisted files
        files = {
            "lua/entities/gmod_wire_expression2/core/extloader.lua", -- Wiremod
            "lua/entities/info_wiremapinterface/init.lua", -- Wiremod
            "gamemodes/base/entities/entities/lua_run.lua", -- GMod
            "lua/easychat/autoloader.lua", -- Easy Chat
            "lua/autorun/gb-radial.lua", -- Overhauled Radial Menu
            "lua/autorun/hat_init.lua", -- Henry's Animation Tool
            "lua/vrmod/0/vrmod_api.lua", -- VR Mod
            "lua/atmos/init.lua" -- atmos
        },

        -- Whitelist http.Fetch() and http.Post() urls
        --   Don't scan the downloaded content, just run it normally to start checking again
        urls = {
            "http://www.geoplugin.net/"
        },
    
        -- Whitelist snippets
        --   Ignore detections containing the listed texts
        --   Be very careful to add items here! Ideally, this list should never be used
        snippets = {
        }
    },

    -- Loose detections
    --   Detections from these lists will generate only warnings
    loose = {
        -- Loose folders
        folders = {
        },

        -- Loose files
        files = {
        }
    }
}
