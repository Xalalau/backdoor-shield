--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

function BS:Detours_Init()
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

		self:Detours_Set(protectedFunc, filters, failed)
	end
end

-- Auto detouring protection
-- 	 First 5m running: check every 5s
-- 	 Later: check every 60s
function BS:Detours_SetAutoCheck()
	local function SetAuto(name, delay)
		timer.Create(name, delay, 0, function()
			if self.reloaded then
				timer.Remove(name)

				return
			end

			for funcName,_ in pairs(self.control) do
				self:Detours_Validate(funcName)
			end
		end)
	end

	local name = self:Utils_GetRandomName()

	SetAuto(name, 5)

	timer.Simple(300, function()
		SetAuto(name, 60)
	end)
end

-- Protect a detour address
function BS:Detours_Validate(funcName, trace)
	local currentAddress = self:Detours_GetFunction(funcName)
	local detourAddress = self.control[funcName].detour
	local trace_aux = debug.getinfo(currentAddress, "S").source

	if detourAddress ~= currentAddress then
		local info = {
			func = funcName,
			trace = trace or trace_aux
		}

		-- Check if it's a low risk detection. If so, only report
		local lowRisk = false

		if not trace_aux or string.len(trace_aux) == 4 then
			trace_aux = self:Trace_GetLuaFile(trace or debug.traceback())
		else
			trace_aux = self:Utils_ConvertAddonPath(string.sub(trace_aux, 1, 1) == "@" and string.sub(trace_aux, 2))
		end

		if self.lowRiskFiles_Check[trace_aux] then
			lowRisk = true
		else
			for _,v in pairs(self.lowRiskFolders) do
				local start = string.find(trace_aux, v, nil, true)

				if start == 1 then
					lowRisk = true

					break
				end
			end
		end

		if lowRisk then
			if self.ignoredDetours[trace_aux] then
				return true
			end

			info.type = "warning"
			info.alert = "Warning! Detour detected in a low risk location. Ignoring it..."
			self.ignoredDetours[trace_aux] = true
		else
			info.type = "detour"
			info.alert = "Detour captured and undone!"

			self:Detours_Set_Aux(funcName, detourAddress)
		end

		self:Report_Detection(info)

		return false
	end

	return true
end

function BS:Detours_CallOriginalFunction(funcName, args)
	return self:Detours_GetFunction(funcName, _G)(unpack(args))
end

function BS:Detours_GetFunction(funcName, env)
	env = env or self.__G
	local currentFunc = {}

	for k,v in ipairs(string.Explode(".", funcName)) do
		currentFunc[k] = currentFunc[k - 1] and currentFunc[k - 1][v] or env[v]
	end

	return currentFunc[#currentFunc]
end

function BS:Detours_Set_Aux(funcName, newfunc, env)
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

	table.Merge(env, RecursiveRebuild(funcName, env))
end

function BS:Detours_Set(funcName, filters, failed)
	local running = {}

	function Detour(...)
		local args = {...} 

		if running[funcName] then -- Avoid loops
			return self:Detours_CallOriginalFunction(funcName, args)
		end
		running[funcName] = true

		local trace = self:Trace_Get(debug.traceback())

		self:Detours_Validate(funcName, trace)

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

			return self:Detours_CallOriginalFunction(funcName, args)
		end
	end

	self:Detours_Set_Aux(funcName, Detour)
	self.control[funcName].detour = Detour
end

function BS:Detours_Remove()
	for k,v in pairs(self.control) do
		self:Detours_Set_Aux(k, self:Detours_GetFunction(k, _G))
	end
end
