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
			for k,_ in ipairs(filters) do
				self.control[protectedFunc].filters[k] = self[self.control[protectedFunc].filters[k]]
			end

			filters = self.control[protectedFunc].filters
		end

		self:Functions_SetDetour(protectedFunc, filters, failed)
	end
end

function BS:Functions_InitCallsProtection()
	for protectedFunc,_ in pairs(self.controlsBackup) do
		local filters = self.controlsBackup[protectedFunc].filters

		if isstring(filters) then
			if filters == "Validate_Callers" then
				self.protectedCalls[protectedFunc] = self.control[protectedFunc].detour
			end
		elseif istable(filters) then
			for k,filters2 in ipairs(filters) do
				if filters2 == "Validate_Callers" then
					self.protectedCalls[protectedFunc] = self.control[protectedFunc].detour
					break
				end
			end
		end
	end
end

function BS:Functions_CallProtected(funcName, args)
	return self:Functions_GetCurrent(funcName, _G)(unpack(args))
end

function BS:Functions_GetCurrent(funcName, env)
	env = env or self.__G
	local currentFunc = {}

	for k,v in ipairs(string.Explode(".", funcName)) do
		currentFunc[k] = currentFunc[k - 1] and currentFunc[k - 1][v] or env[v]
	end

	return currentFunc[#currentFunc]
end

function BS:Functions_SetDetour_Aux(funcName, newfunc, env)
	env = env or self.__G

	local function RecursiveRebuild(funcName, currentFunction)
		local newTable = {}
		local nameParts = string.Explode(".", funcName)
		local rejoin
		local index
	
		for k,v in ipairs(nameParts) do
			if k == 1 then
				currentFunction = currentFunction[v]
				index = v
	
				if isfunction(currentFunction) then
					newTable[v] = newfunc

					return newTable
				end
			end
	
			if k > 1 then
				rejoin = not rejoin and v or rejoin .. "." .. v
			end				
		end
	
		newTable[index] = RecursiveRebuild(rejoin, currentFunction)

		return newTable
	end

	table.Merge(env, RecursiveRebuild(funcName, env, newTable))
end

function BS:Functions_SetDetour(funcName, filters, failed)
	local running = {}

	function Detour(...)
		local args = {...} 

		if running[funcName] then -- Avoid loops
			return self:Functions_CallProtected(funcName, args)
		end
		running[funcName] = true

		local bankedTrace = self:Trace_Get()
		local trace = (bankedTrace and bankedTrace or "") .. "\n      " .. debug.traceback()

		self:Validate_Detour(funcName, trace)

		if filters then
			local i = 1
			for _,filter in ipairs(filters) do
				local result = filter(self, trace, funcName, args)

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
