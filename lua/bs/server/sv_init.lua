--[[
    2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

BS = {}
BS.__index = BS

BS.VERSION = "GitVub V1.4.1+"

BS.DEVMODE = true -- If true, will enable code live reloading, the command bs_tests and more time without hibernation (unsafe! Only used while developing)
BS.LIVEPROTECTION = true -- If true, will block backdoors activity. If off, you'll only have the the file scanner.

BS.ALERT = "[Backdoor Shield]"
BS.FILENAME = "backdoor_shield.lua"
BS.FOLDER = {}
BS.FOLDER.DATA = "backdoor-shield/"
BS.FOLDER.LUA = "bs/"
BS.FOLDER.MODULES = BS.FOLDER.LUA .. "server/modules/"

BS.RELOADED = false -- Internal control to check the tool reloading state - don't change it. _G.BS_RELOADED is also created to globally do the same thing

local __G_SAFE = table.Copy(_G) -- Our custom environment
BS.__G = _G -- Access the global table inside our custom environment

local function includeModules(dir)
    local files, dirs = file.Find( dir.."*", "LUA" )

    if not dirs then
        return
    end

    for _, fdir in pairs(dirs) do
        includeModules(dir .. fdir .. "/")
    end

    for k,v in pairs(files) do
        include(dir .. v)
    end 
end

include("definitions.lua")
includeModules(BS.FOLDER.MODULES)

local BS_AUX = table.Copy(BS)
BS = nil
local BS = BS_AUX

BS.FILETIMES = BS:Utils_GetFilesCreationTimes()

function BS:Initialize()
    -- https://manytools.org/hacker-tools/ascii-banner/
    -- Font: ANSI Shadow
    local logo = { [1] = [[

    ----------------------- Server Protected By -----------------------

    ██████╗  █████╗  ██████╗██╗  ██╗██████╗  ██████╗  ██████╗ ██████╗
    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗
    ██████╔╝███████║██║     █████╔╝ ██║  ██║██║   ██║██║   ██║██████╔╝
    ██╔══██╗██╔══██║██║     ██╔═██╗ ██║  ██║██║   ██║██║   ██║██╔══██╗]],
    [2] =  [[
    ██████╔╝██║  ██║╚██████╗██║  ██╗██████╔╝╚██████╔╝╚██████╔╝██║  ██║
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    ███████╗██╗  ██╗██╗███████╗██╗     ██████╗
    ██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗  2020 Xalalau Xubilozo
    ███████╗███████║██║█████╗  ██║     ██║  ██║  MIT License
    ╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║]],
    [3] = [[
    ███████║██║  ██║██║███████╗███████╗██████╔╝  ██ ]] .. self.VERSION .. [[

    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝      

    The security is performed by automatically blocking executions,
    correcting some changes and warning about suspicious activity, but
    you may also:

    1) Set custom black and white lists directly in the definitions file.
    Don't leave warnings on the console and make exceptions whenever you
    want. Logs are located in: "garrysmod/data/]] .. self.FOLDER.DATA .. [["
    ]],
    [4] = [[
    2) Recursively scan folders and investigate the results:
    |
    |--> bs_scan folder(s)
    |
    |       all files in folder(s) or in lua, gamemode and data folders.
    |
    |--> bs_scan_fast folder(s):

            lua, txt, vmt, dat and json files in folder(s) or in lua,
            gamemode and data folders.

    -------------------------------------------------------------------]],
    [5] = [[
    |                                                                 |
    |        Live reloading in turned on! The addon is unsafe!        |
    |                    Command bs_tests added.                      |
    |                                                                 |
    -------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------]] }

    if not self.__G.BS_RELOADED then
        for _, str in ipairs(logo) do
            if _ == 5 and !self.DEVMODE then continue end
            print(str)
        end

        print()
    end

    if not file.Exists(self.FOLDER.DATA, "DATA") then
        file.CreateDir(self.FOLDER.DATA)
    end

    self:LiveReloading_Set()

    if BS.LIVEPROTECTION then
        self:Functions_InitDetouring()

        self:Validate_AutoCheckDetouring()

        if not GetConVar("sv_hibernate_think"):GetBool() then
            hook.Add("Initialize", self:Utils_GetRandomName(), function()
                RunConsoleCommand("sv_hibernate_think", "1")

                timer.Simple(self.DEVMODE and 99999999 or 300, function()
                    RunConsoleCommand("sv_hibernate_think", "0")
                end)
            end)
        end
    end
end

-- Isolate our environment
for k,v in pairs(BS)do
    if isfunction(v) then
        setfenv(v, __G_SAFE)
    end
end

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

BS:Initialize()
