--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/

    Backdoor Shield (BS) (Also known as bullshit detector)
]]

AddCSLuaFile()

-- ------------------------------------------------
-- Initialize pre files include variables

BS = {}

BS.version = "V. 1.10.0"

BS.alert = "[Backdoor Shield]"
BS.folder = {}
BS.folder.data = "backdoor-shield"
BS.folder.lua = "bs"
BS.folder.sv_libs = BS.folder.lua .. "/server/libs"
BS.folder.cl_libs = BS.folder.lua .. "/client/libs"

BS.locals = {} -- Register local functions addresses, set their environment to protected, cease to exist

BS.colors = {
    header = Color(255, 0, 255),
    key = Color(0, 255, 0),
    value = Color(255, 255, 255),
    message = Color(0, 255, 255),
    reload = Color(0, 255, 255),
    highRisk = Color(255, 0, 0),
    mediumRisk = Color(255, 255, 0),
    lowRisk = Color(0, 0, 255),
}

if SERVER then
    BS.reloaded = false -- Internal control: tell the older code that it's not running anymore, so we can turn off timers etc
--  BS.__G.BS_reloaded -- Internal control: tell the newer code that it's from a refresh, so we can do adjustments like hiding the initial screen

    -- Counting
    BS.liveCount = { 
        detections = 0,
        warnings = 0
    }
    --[[
        List of protected functions and their filters
        { 
            ["function name"] = {
                filters = { function filter, ... } 
                detour = function detour address
            },
            ...
        }
    ]]
    BS.liveDetours = {}
    -- List traces saved from some functions. e.g { ["function address"] = { name = "fuction name", trace = trace }, ... }
    BS.liveTraceStacks = {} 
    --[[
        Blocked calls
        {
            ["function name"] = {
                [detoured blocked caller address A] = blocked caller name,
                [original blocked caller address A] = blocked caller name,
                ...
            },
            ...
        }
    ]]
    BS.liveCallerBlacklist = {}

    -- Lists with structures focused on quick searches
    -- { [value] = true, ... }
    BS.scannerDangerousExtensions_EZSearch = {} 
    BS.scannerLooseFiles_EZSearch = {}
    BS.liveLooseFiles_EZSearch = {}
    BS.liveWhitelistsFiles_EZSearch = {}

    -- More lists with structures focused on quick searches

    -- Adjusts the internal format of some definitions, which have been changed for readability
    BS.scannerBlacklist_FixedFormat = {} -- { k = term, ... }
    BS.liveBlacklistStack_FixedFormat2D = {} -- { [id] = { k = term, ... }, ... }
end

-- ------------------------------------------------
-- Include files

local function includeLibs(dir, isClientLib)
    local files, dirs = file.Find( dir .. "*", "LUA" )

    if not dirs then return end

    for _, subDir in ipairs(dirs) do
        includeLibs(dir .. subDir .. "/", isClientLib)
    end

    for k, _file in ipairs(files) do
        if SERVER and isClientLib then
            AddCSLuaFile(dir .. _file)
        else
            include(dir .. _file)
        end
    end 
end

if SERVER then
    AddCSLuaFile("autorun/client/bs_cl_autorun.lua")

    include(BS.folder.lua .. "/server/definitions/main.lua")
    include(BS.folder.lua .. "/server/definitions/liveprotection.lua")
    include(BS.folder.lua .. "/server/definitions/filescanner.lua")
    include(BS.folder.lua .. "/server/sv_init.lua")
    includeLibs(BS.folder.sv_libs .. "/")
end
includeLibs(BS.folder.cl_libs .. "/", true)

-- ------------------------------------------------
-- Initialize post files include variables

if SERVER then
    BS.filenames = BS:Utils_GetFilesCreationTimes() -- Get the creation time of each Lua game file
end

-- ------------------------------------------------
-- Create our data folder

if SERVER then
    if not file.Exists(BS.folder.data, "DATA") then
        file.CreateDir(BS.folder.data)
    end
end

-- ------------------------------------------------
-- Protect environment

-- Isolate our addon functions
local BS_AUX = table.Copy(BS)
BS = nil
local BS = BS_AUX

-- Create a deep copy of the global table
local __G_SAFE = table.Copy(_G)

-- Set our custom environment to main functions
for _,v in pairs(BS)do
    if isfunction(v) then
        setfenv(v, __G_SAFE)
    end
end

-- Set our custom environment to local functions
for _,v in ipairs(BS.locals)do
    setfenv(v, __G_SAFE)
end
BS.locals = nil

-- Access the global table inside our custom environment
BS.__G = _G 

if SERVER then
    -- ------------------------------------------------
    -- Setup internal tables

    -- Create tables to check values faster

    -- e.g. { [1] = "lua/derma/derma.lua" } turns into { ["lua/derma/derma.lua"] = true }
     local inverseIpairs = {
        { BS.scanner.loose.files, BS.scannerLooseFiles_EZSearch },
        { BS.live.loose.files, BS.liveLooseFiles_EZSearch },
        { BS.live.whitelists.files, BS.liveWhitelistsFiles_EZSearch },
        { BS.scanner.dangerousExtensions, BS.scannerDangerousExtensions_EZSearch },
    }

    for _, tabs in ipairs(inverseIpairs) do
        for _, field in ipairs(tabs[1]) do
            tabs[2][field] = true
        end
    end

    -- Rearrange tables to the expected formats

    local inversePairsToIpais = {
        { BS.scanner.blacklist, BS.scannerBlacklist_FixedFormat }
    }

    for k, tabs in ipairs(inversePairsToIpais) do
        for newValue, _ in pairs(tabs[1]) do
            table.insert(tabs[2], newValue)
        end
    end

    for funcName, stackBlacklistTab in pairs(BS.live.blacklists.stack) do
        for k, blacklistedStackFuncName in pairs(stackBlacklistTab) do
            BS.liveBlacklistStack_FixedFormat2D[blacklistedStackFuncName] = BS.liveBlacklistStack_FixedFormat2D[blacklistedStackFuncName] or {}
            table.insert(BS.liveBlacklistStack_FixedFormat2D[blacklistedStackFuncName], funcName)
        end
    end

    -- ------------------------------------------------
    -- Call other specific initializations 

    BS:Initialize()
end