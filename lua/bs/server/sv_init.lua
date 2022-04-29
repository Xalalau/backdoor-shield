--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Create our protectedCalls table
local function ProtectedCalls_Init(BS)
	for funcName,_ in pairs(BS.live.control) do
		if BS.live.control[funcName].protectStack then
            BS.protectedCalls[funcName] = BS:Detours_GetFunction(funcName)
        end
    end
end
table.insert(BS.locals, ProtectedCalls_Init)

-- Create our protectedCalls table
local function ArgumentsFunctions_Init(BS)
	for funcName,funcTab in pairs(BS.liveControlsBackup) do
        if istable(funcTab.filters) then
            for _,filter in pairs(funcTab.filters) do
                if filter == "Filters_CheckStack" and funcTab.stackBanLists then
                    for _,stackBanListName in pairs(funcTab.stackBanLists) do
                        if not BS.live.blacklists.functions[stackBanListName] then
                            BS.live.blacklists.functions[stackBanListName] = {}
                        end
                        table.insert(BS.live.blacklists.functions[stackBanListName], funcName)
                    end
                end
            end
        end
    end
end
table.insert(BS.locals, ArgumentsFunctions_Init)

function BS:Initialize()
    -- Print logo
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

    ███████╗██╗  ██╗██╗███████╗██╗     ██████╗   2020-2022
    ██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗  Xalalau Xubilozo
    ███████╗███████║██║█████╗  ██║     ██║  ██║  MIT License
    ╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║]],
    [3] = [[
    ███████║██║  ██║██║███████╗███████╗██████╔╝  ██ ]] .. self.version .. [[

    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝      

    Real-time blocking of suspicious executions, function protection against
    detouring, malware scanner and detailed detection logs.

    To set custom black and white lists, edit the definitions file:
    addons/backdoor-shield/lua/bs/server/definitions.lua
    You can also avoid unnecessary warnings in the console this way.

    Logs are located in: "garrysmod/data/]] .. self.folder.data .. [["

    Disclaimer: This addon will by no means solve all your problems, it's
    just a tool created for self-interest research. - Xalalau
    ]],
    [4] = [[
    Commands:
    |
    |-> bs_scan FOLDER(S)       Recursively scan lua, txt, vmt, dat and
    |                           json files in FOLDER(S).
    |
    |-> bs_scan_full FOLDER(S)  Recursively scan all files in FOLDER(S).
       
        * If no folder is defined, it'll scan addons, lua, gamemode and
          data folders.

    -------------------------------------------------------------------]],
    [5] = [[
    |                                                                 |
    |        Live reloading in turned on! The addon is unsafe!        |
    |                    Command bs_tests added.                      |
    |                                                                 |
    -------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------]] }

    if not self.__G.BS_reloaded then
        for _, str in ipairs(logo) do
            if _ == 5 and not self.devMode then continue end
            print(str)
        end

        print()
    end

    -- Create cvars

    -- Command to scan all files in the main/selected folders
    concommand.Add("bs_scan", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            self:Folders_Scan(args, self.filesScanner.dangerousExtensions)
        end
    end)

    -- Command to scan some files in the main/selected folders
    concommand.Add("bs_scan_full", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            self:Folders_Scan(args)
        end
    end)

    -- Command to run an automatic set of tests
    if self.devMode then
        concommand.Add("bs_tests", function(ply, cmd, args)
            if not ply:IsValid() or ply:IsAdmin() then
                self:Debug_RunTests(args)
            end
        end)
    end

    -- Set live reloading

    self:LiveReloading_Set()

    -- Set live protection

    if self.live.isOn then
        self:Detours_Init()

        ProtectedCalls_Init(self)

        ArgumentsFunctions_Init(self)

        self:Detours_SetAutoCheck()

        self:Stack_Init()

        if not GetConVar("sv_hibernate_think"):GetBool() then
            hook.Add("Initialize", self:Utils_GetRandomName(), function()
                RunConsoleCommand("sv_hibernate_think", "1")

                timer.Simple(self.devMode and 99999999 or 300, function()
                    RunConsoleCommand("sv_hibernate_think", "0")
                end)
            end)
        end
    end
end
