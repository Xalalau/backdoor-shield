--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- FILES SCANNER
-- -----------------------------------------------------------------------------------

-- Don't add common patterns to the blacklists and suspect lists, or the addon will return
-- many false positives and probably turn the console into a giant log hell.

BS.scanner = {
    -- These extensions will never be considered as not suspect by the file scanner.
    -- The bs_scan command scans only for files with these extensions.
    dangerousExtensions = { "lua", "txt" , "vmt", "dat", "json" },

    -- The folders checked by the scanner if none are specified (bs_scan command)
    foldersToScan = { "addons", "lua", "gamemodes", "data" },

    -- Print low-risk results in the console
    printLowRisk = false,

    -- Print detection lines in the console
    printLines = true,

    -- Discard results that didn't even get the low risk weight
    discardUnderLowRisk = true,

    -- Ignore our own folders
    ignoreBSFolders = true,

    -- Current risk thresholds:
    thresholds = {
        high = 15,
        medium = 10,
        low = 5
    },

    -- Weight reduction in detections
    counterWeights = {
        notSuspicious = -15,
        loose = -10
    },

    -- Weight increase in detections
    extraWeights = {
        invalidChar = 4, -- Do not set the weight at or above thresholds.low, this value eliminates many false positives.
        notLuaFile = 5
    },

    -- Avoid false positives with non Lua files
    --   Detections with these chars will be considered as not suspect (at first) for tested strings
    --   that aren't from files with extensions listed in the dangerousExtensions table.
    notSuspicious = {
        "ÿ",
        "" -- 000F
    },

    -- Blacklisted terms and their detection weights
    --   The blacklist can have functions, snippets, syntax and symbols as keys
    --   The number assigned to each line is a weight that will be added during the scan
    --   The weight of each detection is compared to the risk thresholds to determine the threat level
    blacklist = {
        ["(_G)"] = 15,
        [",_G,"] = 15,
        ["!true"] = 15,
        ["!false"] = 15,
        ["=_G"] = 12, -- Used by backdoors to start hiding names or create a new environment
        ["RunString"] = 10,
        ["CompileString"] = 8,
        ["CompileFile"] = 8,
        ["http.Fetch"] = 5,
        ["http.Post"] = 5,
        ["game.ConsoleCommand"] = 5,
        ["STEAM_0:"] = 5,
        ["debug.getinfo"] = 4,
        ["setfenv"] = 4,
        ["BroadcastLua"] = 3,
        ["SendLua"] = 3,
        ["_G["] = 2,
        ["_G."] = 2,
        ["_R["] = 2,
        ["_R."] = 2,
        ["pcall"] = 1,
        ["xpcall"] = 1,
        ["]()"] = 1,
        ["0x"] = 1,
        ["\\x"] = 1
    },

    -- Whitelists
    --      Detections that fall into this list are entirely ignored and don't generate logs.
    --      Each row added to these tables gives backdoors a new way to hide, so customize them as needed.
    whitelists = {
        -- Whitelisted folders
        folders = {
            "lua/wire", -- Wiremod
            "lua/entities/gmod_wire_expression2", -- Wiremod
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
            "gamemodes/base/entities/entities/lua_run.lua", -- GMod
            "lua/vgui/dhtml.lua", -- GMod
            "lua/derma/derma.lua" -- GMod
        },

        -- Whitelist snippets
        --   Ignore detections containing the listed texts
        --   Be very careful to add items here! Ideally, this list should never be used
        snippets = {
            --"RunHASHOb", -- Ignore a DRM. Note: backdoors have already been found under DRMs.
            --"RunningDRMe", -- Ignore a DRM. Note: backdoors have already been found under DRMs.
        },
    },

    -- Loose detections
    --   Detections from these lists will receive a great detection weight reduction
    loose = {
        -- Loose folders
        folders = {
        },

        -- Loose files
        files = {
        },
    }
}
