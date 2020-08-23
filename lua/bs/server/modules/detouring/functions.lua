--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

function BS:Functions_InitDetouring()
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
		self:Functions_Detour(k, v.filter)
	end
end

function BS:Functions_GetCurrent(f1, f2, f3, env)
	env = env or self.__G

	return f3 and env[f1][f2][f3] or f2 and env[f1][f2] or f1 and env[f1]
end

function BS:Functions_Detour_Aux(func, f1, f2, f3, env)
	env = env or self.__G

	if f3 then
		env[f1][f2][f3] = func
	elseif f2 then
		env[f1][f2] = func
	elseif f1 then
		env[f1] = func
	end
end

function BS:Functions_Detour(funcName, customFilter)
	function Detour(...)
		local args = {...} 
		local trace = debug.traceback()

		self:Validate_Detour(funcName, self.control[funcName], trace)

		if customFilter then
			return customFilter(self, trace, funcName, args)
		else
			return self.control[funcName].original(unpack(args))
		end
	end

	self:Functions_Detour_Aux(Detour, unpack(string.Explode(".", funcName)))
	self.control[funcName].detour = Detour
end

function BS:Functions_RemoveDetours()
	for k,v in pairs(self.control) do
		local f1, f2, f3 = unpack(string.Explode(".", k))

		self:Functions_Detour_Aux(self:Functions_GetCurrent(f1, f2, f3, self.__G_SAFE), f1, f2, f3)
	end
end