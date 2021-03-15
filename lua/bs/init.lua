--[[
    2020-2021 Xalalau Xubilozo. MIT License
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
BS.folder.data = "backdoor-shield/"
BS.folder.lua = "bs/"
BS.folder.sv_modules = BS.folder.lua .. "server/modules/"
BS.folder.cl_modules = BS.folder.lua .. "client/modules/"

if SERVER then
    BS.reloaded = false -- Internal control to check the tool reloading state - don't change it. _G.BS_reloaded is also created to globally do the same thing

    BS.detections = { -- Counting
        blocks = 0,
        warnings = 0
    }

    BS.ignoredDetours = {} -- Ignored low risk detour detections. e.g { ["lua/ulib/shared/hook.lua"] = true }

    BS.protectedCalls = {} -- List of functions that can't call each other. e.g. { ["function name"] = detoured function address }

    BS.traceBank = {} -- List traces saved from some functions. e.g { ["lua/ulib/shared/hook.lua"] = { name = "fuction name", trace = trace } }

    BS.dangerousExtensions_Check = {} -- Auxiliar tables to check values faster
    BS.lowRiskFiles_Check = {}
    BS.suspect_suspect_Check = {}
end

local function GetFilesCreationTimes(BS)
    if SERVER then
        BS.filenames = BS:Utils_GetFilesCreationTimes() -- Get the creation time of each Lua game file
    end
end

local function SetControlsBackup(BS)
    if SERVER then
        BS.controlsBackup = table.Copy(BS.control) -- Get the creation time of each Lua game file
    end
end

-- Include our stuff

local function includeModules(dir, isClientModule)
    local files, dirs = file.Find( dir.."*", "LUA" )

    if not dirs then return end

    for _, fdir in pairs(dirs) do
        includeModules(dir .. fdir .. "/", isClientModule)
    end

    for k,v in pairs(files) do
        if SERVER and isClientModule then
            AddCSLuaFile(dir .. v)
        else
            include(dir .. v)
        end
    end 
end

if SERVER then
    AddCSLuaFile("autorun/client/bs_cl_autorun.lua")

    include(BS.folder.lua .. "server/definitions.lua")
    include(BS.folder.lua .. "server/sv_init.lua")
    includeModules(BS.folder.sv_modules)
end
includeModules(BS.folder.cl_modules, true)

-- Get the creation time of each Lua game file
GetFilesCreationTimes(BS)

-- Backup the controls table
SetControlsBackup(BS)

-- Protect environment

-- Isolate our addon functions
local BS_AUX = table.Copy(BS)
BS = nil
local BS = BS_AUX

-- Set our custom environment
local __G_SAFE = table.Copy(_G)
for k,v in pairs(BS)do
    if isfunction(v) then
        setfenv(v, __G_SAFE)
    end
end

-- Access the global table inside our custom environment
BS.__G = _G 

if SERVER then
    -- Create auxiliar tables to check values faster

     -- e.g. { [1] = "lua/derma/derma.lua" } turns into { "lua/derma/derma.lua" = true }, which is much better to do checks
    local generate = {
        { BS.lowRiskFiles, BS.lowRiskFiles_Check },
        { BS.dangerousExtensions, BS.dangerousExtensions_Check },
        { BS.suspect_suspect, BS.suspect_suspect_Check }
    }

    for _,tab in ipairs(generate) do
        for _,field in ipairs(tab[1]) do
            tab[2][field] = true
        end
    end

    -- Create our data folder

    if not file.Exists(BS.folder.data, "DATA") then
        file.CreateDir(BS.folder.data)
    end

    -- Call other specific initializations 

    BS:Initialize()
end