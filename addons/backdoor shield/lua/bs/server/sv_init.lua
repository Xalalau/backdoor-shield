--[[
    2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

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

BS = {}
BS.__index = BS

BS.VERSION = "V.1.4" 

BS.DEVMODE = false -- If true, will enable code live reloading + the command bs_tests (unsafe mode! Only used while developing)
BS.RELOADED = false
-- It also creates _G.BS_RELOADED to globally control the state

BS.ALERT = "[Backdoor Shield]"

BS.FILENAME = "backdoor_shield.lua"

BS.FOLDER = {}
BS.FOLDER.DATA = "backdoor shield/"
BS.FOLDER.LUA = "bs/"
BS.FOLDER.MODULES = BS.FOLDER.LUA .. "server/modules/"

BS.__G = _G -- Access the global table inside our custom environment

include("definitions.lua")
includeModules(BS.FOLDER.MODULES)

local BS_AUX = table.Copy(BS)
BS = nil
local BS = BS_AUX

BS.__G_SAFE = BS.__G -- Our custom environment
BS.__G = _G

BS.FILETIMES = BS:Utils_GetFilesCreationTimes()

function BS:Initialize()
    -- https://manytools.org/hacker-tools/ascii-banner/
    -- Font: ANSI Shadow
    local logo = [[

    ----------------------- Server Protected By -----------------------

    ██████╗  █████╗  ██████╗██╗  ██╗██████╗  ██████╗  ██████╗ ██████╗ 
    ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗
    ██████╔╝███████║██║     █████╔╝ ██║  ██║██║   ██║██║   ██║██████╔╝
    ██╔══██╗██╔══██║██║     ██╔═██╗ ██║  ██║██║   ██║██║   ██║██╔══██╗]]
    local logo2 = [[
    ██████╔╝██║  ██║╚██████╗██║  ██╗██████╔╝╚██████╔╝╚██████╔╝██║  ██║
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝

    ███████╗██╗  ██╗██╗███████╗██╗     ██████╗
    ██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗
    ███████╗███████║██║█████╗  ██║     ██║  ██║
    ╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║]]
    local logo3 = [[
    ███████║██║  ██║██║███████╗███████╗██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝

    The security is performed by automatically blocking executions,
    correcting some changes and warning about suspicious activity,
    but you may also:

    1) Set custom black and white lists directly in the definitions file.
    Don't leave warnings circulating on the console and make exceptions
    whenever you want.

    2) Scan your addons and investigate the results:
    |--> "bs_scan": Recursively scan GMod and all the mounted contents
    |--> "bs_scan <folder(s)>": Recursively scan the seleceted folder

    All logs are located in: "garrysmod/data/]] .. self.FOLDER.DATA .. [["


    ██ ]] .. self.VERSION .. [[


    2020 Xalalau Xubilozo. MIT License.
    -------------------------------------------------------------------]]
    local logo4 = [[
    |                                                                 |
    |        Live reloading in turned on! The addon is unsafe!        |
    |                                                                 |
    -------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------]]

    if not self.__G.BS_RELOADED then
        print(logo)
        print(logo2)
        print(logo3)
        if self.DEVMODE then
            print(logo4)
        end
        print()
    end

    if not file.Exists(self.FOLDER.DATA, "DATA") then
        file.CreateDir(self.FOLDER.DATA)
    end

    self:LiveReloading_Set()

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

-- Isolate our enironment
for k,v in pairs(BS)do
    if isfunction(v) then
        setfenv(v, BS.__G_SAFE)
    end
end

-- Command to scan folders
concommand.Add("bs_scan", function(ply, cmd, args)
    if not ply:IsValid() or ply:IsAdmin() then
        BS:Scan_Folders(args)
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
