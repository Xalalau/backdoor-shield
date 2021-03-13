--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

--[[
    Main structure initialization:

    > BS table (global vars/controls + include code);
    > protect environment;
    > create auxiliar tables;
    > create our data folder;
    > call other server and client init.
]]

AddCSLuaFile()

BS = {}
BS.__index = BS

-- Global vars/controls

BS.VERSION = "V. 1.8+ (GitHub)"

BS.ALERT = "[Backdoor Shield]"
BS.FOLDER = {}
BS.FOLDER.DATA = "backdoor-shield/"
BS.FOLDER.LUA = "bs/"
BS.FOLDER.SV_MODULES = BS.FOLDER.LUA .. "server/modules/"
BS.FOLDER.CL_MODULES = BS.FOLDER.LUA .. "client/modules/"

if SERVER then
    BS.DEVMODE = true -- If true, will enable code live reloading, the command bs_tests and more time without hibernation (unsafe! Only used while developing)
    BS.LIVEPROTECTION = true -- If true, will block backdoors activity. If off, you'll only have the the file scanner.

    BS.DANGEROUSEXTENTIONS = { "lua", "txt" , "vmt", "dat", "json" }

    if BS.DEVMODE then
        BS.RELOADED = false -- Internal control to check the tool reloading state - don't change it. _G.BS_RELOADED is also created to globally do the same thing
    end

    BS.DETECTIONS = { -- Counting
        BLOCKS = 0,
        WARNINGS = 0
    }

    BS.IGNORED_DETOURS = {} -- Ignored low risk detour detections. e.g { ["lua/ulib/shared/hook.lua"] = true }

    BS.PROTECTEDCALLS = {} -- List of functions that can't call each other

    BS.DANGEROUSEXTENTIONS_Check = {} -- Auxiliar tables to check values faster
    BS.lowRiskFiles_Check = {}
    BS.suspect_suspect_Check = {}
end

local function GetFilesCreationTimes(BS)
    if SERVER then
        BS.FILETIMES = BS:Utils_GetFilesCreationTimes() -- Get the creation time of each Lua game file
    end
end

local function SetControlsBackup(BS)
    if SERVER then
        BS.CONTROLSBACKUP = table.Copy(BS.control) -- Get the creation time of each Lua game file
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

    include(BS.FOLDER.LUA .. "server/definitions.lua")
    include(BS.FOLDER.LUA .. "server/sv_init.lua")
    includeModules(BS.FOLDER.SV_MODULES)
end
includeModules(BS.FOLDER.CL_MODULES, true)

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
        { BS.DANGEROUSEXTENTIONS, BS.DANGEROUSEXTENTIONS_Check },
        { BS.suspect_suspect, BS.suspect_suspect_Check }
    }

    for _,tab in ipairs(generate) do
        for _,field in ipairs(tab[1]) do
            tab[2][field] = true
        end
    end

    -- Create our data folder

    if not file.Exists(BS.FOLDER.DATA, "DATA") then
        file.CreateDir(BS.FOLDER.DATA)
    end

    -- Call other specific initializations 

    BS:Initialize()
end