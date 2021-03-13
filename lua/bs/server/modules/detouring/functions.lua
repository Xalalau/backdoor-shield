--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

function BS:Functions_InitDetouring()
	for protectedFunc,_ in pairs(self.control) do
		local filters = self.control[protectedFunc].filters
		local failed = self.control[protectedFunc].failed

		if isstring(filters) then
			self.control[protectedFunc].filters = self[self.control[protectedFunc].filters]
			filters = { self.control[protectedFunc].filters }
		elseif istable(filters) then
			for k,filters2 in ipairs(filters) do
				self.control[protectedFunc].filters[k] = self[self.control[protectedFunc].filters[k]]
			end

			filters = self.control[protectedFunc].filters
		end

		self:Functions_SetDetour(protectedFunc, filters, failed)
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

function BS:Functions_SetDetour(funcName, filters, failed)
	local running = {}

	function Detour(...)
		local args = {...} 

		if running[funcName] then -- Avoid loops
			return self:Functions_CallProtected(funcName, args)
		end
		running[funcName] = true

		local trace = debug.traceback()

		self:Validate_Detour(funcName, self.control[funcName], trace)

		if filters then
			local i = 1
			for _,filter in ipairs(filters) do
				local result = filter(BSAux, trace, funcName, args)

				running[funcName] = nil

				if not result then
					return failed
				elseif i == #filters then
					return result
				end

				i = i + 1
			end
		else
			running[funcName] = nil

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
