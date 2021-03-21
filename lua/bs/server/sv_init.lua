--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Create our protectedCalls table
local function ProtectedCalls_Init(BS)
	local function setField(protectedFunc)
		BS.protectedCalls[protectedFunc] = BS:Detours_GetFunction(protectedFunc)
	end

	for protectedFunc,_ in pairs(BS.controlsBackup) do
		local filters = BS.controlsBackup[protectedFunc].filters

		if isstring(filters) then
			if filters == "Filters_CheckStack" then
				setField(protectedFunc)
			end
		elseif istable(filters) then
			for k,filters2 in ipairs(filters) do
				if filters2 == "Filters_CheckStack" then
					setField(protectedFunc)
					break
				end
			end
		end
	end
end
table.insert(BS.locals, ProtectedCalls_Init)

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

    ███████╗██╗  ██╗██╗███████╗██╗     ██████╗   2020-2021
    ██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗  Xalalau Xubilozo
    ███████╗███████║██║█████╗  ██║     ██║  ██║  MIT License
    ╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║]],
    [3] = [[
    ███████║██║  ██║██║███████╗███████╗██████╔╝  ██ ]] .. self.version .. [[

    ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝      

    The security is performed by automatically blocking executions,
    correcting some changes and warning about suspicious activity, but
    you may also:

    1) Set custom black and white lists directly in the definitions file.
    Don't leave warnings on the console and make exceptions whenever you
    want. Logs are located in: "garrysmod/data/]] .. self.folder.data .. [["
    ]],
    [4] = [[
    2) Use these commands:
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
            self:Scan_Folders(args, self.dangerousExtensions)
        end
    end)

    -- Command to scan some files in the main/selected folders
    concommand.Add("bs_scan_full", function(ply, cmd, args)
        if not ply:IsValid() or ply:IsAdmin() then
            self:Scan_Folders(args)
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

    if self.liveProtection then
        self:Detours_Init()

        ProtectedCalls_Init(self)

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
