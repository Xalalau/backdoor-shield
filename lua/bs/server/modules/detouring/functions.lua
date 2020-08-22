--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

function BS:Functions_GetCurrent(f1, f2, f3, env)
	env = env or self.__G

	return f3 and env[f1][f2][f3] or f2 and env[f1][f2] or f1 and env[f1]
end

function BS:Functions_SetDetour_Aux(func, f1, f2, f3, env)
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
	function Replacement(...)
		local args = {...} 
		local trace = debug.traceback()

		self:Validate_Detour(funcName, self.control[funcName], trace)

		if customFilter then
			return customFilter(self, trace, funcName, args)
		else
			return self.control[funcName].original(unpack(args))
		end
	end

	self:Functions_SetDetour_Aux(Replacement, unpack(string.Explode(".", funcName)))
	self.control[funcName].replacement = Replacement
end