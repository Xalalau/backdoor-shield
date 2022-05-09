--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Create our liveCallerBlacklist table
local function InitSv_SetLiveCallerBlacklist(BS)
    for funcName, blacklistedCallers in pairs(BS.live.blacklists.stack) do
        BS.liveCallerBlacklist[funcName] = {}
        for k, blacklistedCallerName in ipairs(blacklistedCallers) do
            BS.liveCallerBlacklist[funcName][tostring(BS:Detour_GetFunction(blacklistedCallerName))] = blacklistedCallerName
            BS.liveCallerBlacklist[funcName][tostring(BS:Detour_GetFunction(blacklistedCallerName, _G))] = blacklistedCallerName
        end
    end
end
table.insert(BS.locals, InitSv_SetLiveCallerBlacklist)

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

    | Real-time protection | Anti detour | Malware scanner | Detailed logs |

    To set custom black and white lists, edit the definitions file:
    addons/backdoor-shield/lua/bs/server/definitions.lua

    Logs directory: "garrysmod/data/]] .. self.folder.data .. [["

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

    Enabled features:
    |]],
    [5] = [[

    -------- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --------]] }

    if not self.__G.BS_reloaded then
        for k, str in ipairs(logo) do
            if k == 5 then
                print("    |-> [" .. (self.live.isOn and "x" or " ") .. "] Live detection")
                print("    |-> [" .. (self.live.blockThreats and "x" or " ") .. "] Live blocking")
                print("    |-> [" .. (self.live.protectDetours and "x" or " ") .. "] Anti detour")
                print("    |-> [" .. (self.live.alertAdmins and "x" or " ") .. "] Alerts window")
                print("    |-> [" .. (self.devMode and "x" or " ") .. "] Dev mode")
            end 
            print(str)
        end

        print()
    end

    -- Create cvars

    -- Command to scan all files in the main/selected folders
    concommand.Add("bs_scan", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            self:Scanner_Start(args, self.scanner.dangerousExtensions)
        end
    end)

    -- Command to scan some files in the main/selected folders
    concommand.Add("bs_scan_full", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            self:Scanner_Start(args)
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

    -- Set auto reloading

    self:AutoReloading_Set()

    -- Set live protection

    if self.live.isOn then
        self:Detour_Init()

        InitSv_SetLiveCallerBlacklist(self)

        self:Detour_SetAutoCheck()

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
