--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

function BS:Functions_InitDetouring()
	for protectedFunc, protectedFuncTab in pairs(self.control) do
		self.control[protectedFunc].filter = self[protectedFuncTab.filter]
		self:Functions_SetDetour(protectedFunc, protectedFuncTab.filter)
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

function BS:Functions_SetDetour_Aux(funcName, func, env)
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

function BS:Functions_SetDetour(funcName, customFilter)
	function Detour(...)
		local args = {...} 
		local trace = debug.traceback()

		self:Validate_Detour(funcName, self.control[funcName], trace)

		if customFilter then
			return customFilter(self, trace, funcName, args)
		else
			return self:Functions_CallProtected(funcName, args)
		end
	end

	self:Functions_SetDetour_Aux(funcName, Detour)
	self.control[funcName].detour = Detour
end

function BS:Functions_RemoveDetours()
	for k,v in pairs(self.control) do
		self:Functions_SetDetour_Aux(k, self:Functions_GetCurrent(k, _G))
	end
end
