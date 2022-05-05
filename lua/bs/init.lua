--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

--[[
    Main structure initialization:

    > BS table (global vars + include code);
    > protect environment;
    > create auxiliar tables;
    > create our data folder;
    > call other server and client init.
]]

AddCSLuaFile()

BS = {}
BS.__index = BS

-- Global vars/controls

BS.version = "V. 1.8+ (GitHub)"

BS.alert = "[Backdoor Shield]"
BS.folder = {}
BS.folder.data = "backdoor-shield"
BS.folder.lua = "bs"
BS.folder.sv_libs = BS.folder.lua .. "/server/libs"
BS.folder.cl_libs = BS.folder.lua .. "/client/libs"

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
--  self.__G.BS_reloaded -- Internal control: tell the newer code that it's from a refresh, so we can do adjustments like hide the initial screen

    BS.count = { -- Counting
        detections = 0,
        warnings = 0
    }

    BS.ignoredDetours = {} -- Ignored low-risk detour detections. e.g { ["lua/ulib/shared/hook.lua"] = true }

    BS.protectedCalls = {} -- List of functions that can't call each other. e.g. { ["function name"] = detoured function address }

    BS.traceStacks = {} -- List traces saved from some functions. e.g { ["function address"] = { name = "fuction name", trace = trace } }

    -- Inversed tables, used to search values faster
    BS.scannerDangerousExtensions_InverseTab = {}
    BS.looseFiles_InverseTab = {}
    BS.whitelistsFiles_InverseTab = {}

    -- Iversed tables forced to ipairs
    BS.scannerBlacklist_InverseIpairsTab = {}
end

BS.locals = {} -- Register local functions addresses, set their environment to protected, cease to exist

local function GetFilesCreationTimes(BS)
    if SERVER then
        BS.filenames = BS:Utils_GetFilesCreationTimes() -- Get the creation time of each Lua game file
    end
end

local function SetControlsBackup(BS)
    if SERVER then
        BS.liveControlsBackup = table.Copy(BS.live.control) -- Create a copy of the main protection table. It contains the filter names before they turn into functions
    end
end

-- Include our stuff

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

    include(BS.folder.lua .. "/server/definitions.lua")
    include(BS.folder.lua .. "/server/sv_init.lua")
    include(BS.folder.lua .. "/server/invisible.lua")
    includeLibs(BS.folder.sv_libs .. "/")
end
includeLibs(BS.folder.cl_libs .. "/", true)

-- Get the creation time of each Lua game file
GetFilesCreationTimes(BS)

-- Backup the controls table
SetControlsBackup(BS)

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
    -- Create auxiliar tables to check values faster

     -- e.g. { [1] = "lua/derma/derma.lua" } turns into { "lua/derma/derma.lua" = true }, which is much better to do checks
    local inverseIpairs = {
        { BS.loose.files, BS.looseFiles_InverseTab },
        { BS.loose.folders, BS.looseFolders_InverseTab },
        { BS.whitelists.files, BS.whitelistsFiles_InverseTab },
        { BS.scanner.dangerousExtensions, BS.scannerDangerousExtensions_InverseTab },
    }

    for _, tabs in ipairs(inverseIpairs) do
        for _, field in ipairs(tabs[1]) do
            tabs[2][field] = true
        end
    end

    local inversePairsToIpais = {
        { BS.scanner.blacklist, BS.scannerBlacklist_InverseIpairsTab }
    }

    for k, tabs in ipairs(inversePairsToIpais) do
        for newValue, _ in pairs(tabs[1]) do
            table.insert(tabs[2], newValue)
        end
    end

    -- Create our data folder

    if not file.Exists(BS.folder.data, "DATA") then
        file.CreateDir(BS.folder.data)
    end

    -- Call other specific initializations 

    BS:Initialize()
end