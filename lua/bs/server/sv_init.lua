--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
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

BS.VERSION = "V.git.1.3+"

BS.LIVERELOADING = true -- If true, will enable code live reloading (unsafe! Only used while developing)
-- It creates and uses _G.BS_RELOADING to globally control the state

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
    correcting some	changes and warning about suspicious activity,
    but you may also:

    1) Set custom black and white lists directly in the main file.
    Don't leave warnings circulating on the console and make exceptions
    whenever you want.

    2) Scan your addons and investigate the results:
    |--> "bs_scan": Recursively scan GMod and all the mounted contents
    |--> "bs_scan <folder>": Recursively scan the seleceted folder

    All logs are located in: "garrysmod/data/]] .. self.FOLDER.DATA .. [["


    ██ ]] .. self.VERSION .. [[


    ©2020 Xalalau Xubilozo. All Rights Reserved.
    -------------------------------------------------------------------]]
local logo4 = [[
    |                                                                 |
    |        Live reloading in turned on! The addon is unsafe!        |
    |                                                                 |
    -------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------]]

    if not _G.BS_RELOADING then
        print(logo)
        print(logo2)
        print(logo3)
        if self.LIVERELOADING then
            print(logo4)
        end
        print()
    end

    self:LiveReloading_Set()

    if not file.Exists(self.FOLDER.DATA, "DATA") then
        file.CreateDir(self.FOLDER.DATA)
    end

    self.control["http.Fetch"].filter = self.Validate_HttpFetch
    self.control["CompileFile"].filter = self.Validate_CompileFile
    self.control["CompileString"].filter = self.Validate_CompileOrRunString_Ex
    self.control["RunString"].filter = self.Validate_CompileOrRunString_Ex
    self.control["RunStringEx"].filter = self.Validate_CompileOrRunString_Ex
    self.control["getfenv"].filter = self.Validate_GetFEnv
    self.control["debug.getfenv"].filter = self.Validate_GetFEnv
    self.control["debug.getinfo"].filter = self.Validate_DebugGetInfo
    self.control["jit.util.funcinfo"].filter = self.Validate_JitUtilFuncinfo

    for k,v in pairs(self.control) do
        self.control[k].original = self:Functions_GetCurrent(unpack(string.Explode(".", k)))
        self.control[k].short_src = debug.getinfo(self.control[k].original).short_src
        self.control[k].source = debug.getinfo(self.control[k].original).source
        self.control[k].jit_util_funcinfo = jit.util.funcinfo(self.control[k].original)
        self:Functions_SetDetour(k, v.filter)
    end

    if not GetConVar("sv_hibernate_think"):GetBool() then
        hook.Add("Initialize", self:Utils_GetRandomName(), function()
            RunConsoleCommand("sv_hibernate_think", "1")

            timer.Simple(300, function()
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
	BS:Scan_Folders(args)
end)

BS:Initialize()
