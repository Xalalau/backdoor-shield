--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

--[[
    General initialization:

    > BS table (global vars/controls + include code);
    > protect environment;
    > create our data folder;
    > create cvars;
    > call other server and client init.
]]

AddCSLuaFile()

BS = {}
BS.__index = BS

-- Global vars/controls

BS.VERSION = "V GitHub 1.6.1+"

BS.ALERT = "[Backdoor Shield]"
BS.FOLDER = {}
BS.FOLDER.DATA = "backdoor-shield/"
BS.FOLDER.LUA = "bs/"
BS.FOLDER.SV_MODULES = BS.FOLDER.LUA .. "server/modules/"
BS.FOLDER.CL_MODULES = BS.FOLDER.LUA .. "client/modules/"

if SERVER then
    BS.DEVMODE = true -- If true, will enable code live reloading, the command bs_tests and more time without hibernation (unsafe! Only used while developing)
    BS.LIVEPROTECTION = true -- If true, will block backdoors activity. If off, you'll only have the the file scanner.

    if BS.DEVMODE then
        BS.RELOADED = false -- Internal control to check the tool reloading state - don't change it. _G.BS_RELOADED is also created to globally do the same thing
    end

    BS.DETECTIONS = { -- Counting
        BLOCKS = 0,
        WARNINGS = 0
    }

    BS.IGNORED_DETOURS = {} -- Ignored low risk detour detections. e.g { ["lua/ulib/shared/hook.lua"] = true }
end

local function GetFilesCreationTimes()
    if SERVER then
        BS.FILETIMES = BS:Utils_GetFilesCreationTimes() -- Get the creation time of each Lua game file
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

-- Redeclarate the lowRiskFiles list from definitions.lua, so that it's easy to use in the code
-- e.g. { [1] = "lua/derma/derma.lua" } turns into { "lua/derma/derma.lua" = true }, which is much better to do checks.
if SERVER then
    local lowRiskFiles_Aux = {}

    for _,v in pairs(BS.lowRiskFiles) do
        lowRiskFiles_Aux[v] = true
    end

    BS.lowRiskFiles = lowRiskFiles_Aux
    lowRiskFiles_Aux = nil
end

-- Isolate our environment

local BS_AUX = table.Copy(BS)
BS = nil
local BS = BS_AUX

local __G_SAFE = table.Copy(_G) -- Our custom environment
BS.__G = _G -- Access the global table inside our custom environment
BS.__G_SAFE = __G_SAFE


for k,v in pairs(BS)do
    if isfunction(v) then
        setfenv(v, __G_SAFE)
    end
end

if SERVER then
    -- Create our data folder

    if not file.Exists(BS.FOLDER.DATA, "DATA") then
        file.CreateDir(BS.FOLDER.DATA)
    end

    -- Create cvars

    -- Command to scan all files in the main/selected folders
    concommand.Add("bs_scan", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            BS:Scan_Folders(args)
        end
    end)

    -- Command to scan some files in the main/selected folders
    concommand.Add("bs_scan_fast", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            BS:Scan_Folders(args, { "lua", "txt" , "vmt", "dat", "json" })
        end
    end)

    -- Command to run an automatic set of tests
    if BS.DEVMODE then
        concommand.Add("bs_tests", function(ply, cmd, args)
            if not ply:IsValid() or ply:IsAdmin() then
                BS:Utils_RunTests()
            end
        end)
    end

    -- Call other specific initializations 

    BS:Initialize()
end