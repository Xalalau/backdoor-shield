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
		local original = self:Functions_GetCurrent(k)
		self.control[k].debug_getinfo = debug.getinfo(original)
		self.control[k].jit_util_funcinfo = jit.util.funcinfo(original)
		self:Functions_Detour(k, v.filter)
	end
end

function BS:Functions_CallProtected(funcName, args)
	return self:Functions_GetCurrent(funcName, _G)(unpack(args))
end

function BS:Functions_GetCurrent(funcName, env)
	local f1, f2, f3 = unpack(string.Explode(".", funcName))
	env = env or self.__G

	return f3 and env[f1][f2][f3] or f2 and env[f1][f2] or f1 and env[f1]
end

function BS:Functions_Detour_Aux(funcName, func, env)
	local f1, f2, f3 = unpack(string.Explode(".", funcName))
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
			unpack(string.Explode(".", funcName))

			return self:Functions_CallProtected(funcName, args)
		end
	end

	self:Functions_Detour_Aux(funcName, Detour)
	self.control[funcName].detour = Detour
end

function BS:Functions_RemoveDetours()
	for k,v in pairs(self.control) do
		self:Functions_Detour_Aux(k, self:Functions_GetCurrent(k, self.__G_SAFE))
	end
end