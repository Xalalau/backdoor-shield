--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Initialize detours and filters from the control table
function BS:Detour_Init()
	for protectedFunc,_ in pairs(self.live.control) do
		local filters = self.live.control[protectedFunc].filters
		local failed = self.live.control[protectedFunc].failed

		if isstring(filters) then
			self.live.control[protectedFunc].filters = self[self.live.control[protectedFunc].filters]
			filters = { self.live.control[protectedFunc].filters }
		elseif istable(filters) then
			for k, _ in ipairs(filters) do
				self.live.control[protectedFunc].filters[k] = self[self.live.control[protectedFunc].filters[k]]
			end

			filters = self.live.control[protectedFunc].filters
		end

		self:Detour_Create(protectedFunc, filters, failed)
	end
end

-- Auto detouring protection
-- 	 First 5m running: check every 5s
-- 	 Later: check every 60s
-- This function isn't really necessary, but it's good for advancing detections
function BS:Detour_SetAutoCheck()
	local function SetAuto(name, delay)
		timer.Create(name, delay, 0, function()
			if self.reloaded then
				timer.Remove(name)

				return
			end

			for funcName,_ in pairs(self.live.control) do
				self:Detour_Validate(funcName)
			end
		end)
	end

	local name = self:Utils_GetRandomName()

	SetAuto(name, 5)

	timer.Simple(300, function()
		SetAuto(name, 60)
	end)
end

-- Protect a detoured address
function BS:Detour_Validate(funcName, trace, isLoose)
	local currentAddress = self:Detour_GetFunction(funcName)
	local detourAddress = self.live.control[funcName].detour
	local luaFile

    if not trace or string.len(trace) == 4 then
		local source = debug.getinfo(currentAddress, "S").source
        luaFile = self:Utils_ConvertAddonPath(string.sub(source, 1, 1) == "@" and string.sub(source, 2))
	else 
        luaFile = self:Trace_GetLuaFile()
    end

	if detourAddress ~= currentAddress then
		local info = {
			func = funcName,
			trace = trace or luaFile
		}

		if isLoose then
			info.type = "warning"
			info.alert = "Warning! Detour detected in a low-risk location. Ignoring it..."
		else
			info.type = "detour"
			info.alert = "Detour detected" .. (self.live.undoDetours and " and undone!" or "!")

			if self.live.undoDetours then
				self:Detour_SetFunction(funcName, detourAddress)
			end
		end

		self:Report_LiveDetection(info)

		return false
	end

	return true
end

-- Call an original game function from our protected environment
-- Note: It was created to simplify these calls directly from Detour_GetFunction()
function BS:Detour_CallOriginalFunction(funcName, args)
	return self:Detour_GetFunction(funcName, _G)(unpack(args))
end

-- Get a function address by name from a selected environment
function BS:Detour_GetFunction(funcName, env)
	env = env or self.__G
	local currentFunc = {}

	for k, funcNamePart in ipairs(string.Explode(".", funcName)) do
		currentFunc[k] = currentFunc[k - 1] and currentFunc[k - 1][funcNamePart] or env[funcNamePart]
	end

	return currentFunc[#currentFunc]
end

-- Update a function address by name in a selected environment
function BS:Detour_SetFunction(funcName, newfunc, env)
	env = env or self.__G

	local newTable = {}
	local newTableCurrent = newTable

	local lib = env
	local explodedFuncName = string.Explode(".", funcName)
	local totalParts = #explodedFuncName

	for k, partName in ipairs(explodedFuncName) do
		lib[partName] = k == totalParts and newfunc or lib[partName] or {}
		lib = lib[partName]
	end
end

-- Set a detour (including the filters)
-- Note: if a filter validates but doesn't return the result from Detour_CallOriginalFunction(), just return "true" (between quotes!)
function BS:Detour_Create(funcName, filters, failed)
	local running = {} -- Avoid loops

	function Detour(...)
		local args = {...} 

		-- Avoid loops
		if running[funcName] then
			return self:Detour_CallOriginalFunction(funcName, args)
		end
		running[funcName] = true

		-- Get and check the trace
		local trace = self:Trace_Get(debug.traceback())
		local isWhitelisted = self:Trace_IsWhitelisted(trace)

		if isWhitelisted then
			running[funcName] = nil

			return self:Detour_CallOriginalFunction(funcName, args)
		end

		local isLoose = self:Trace_IsLoose(trace)
		
		-- Check detour
		self:Detour_Validate(funcName, trace, isLoose)

		-- Run filters
		if filters then
			local i = 1
			for _,filter in ipairs(filters) do
				local result = filter(self, trace, funcName, args, isLoose)

				running[funcName] = nil

				if not result then
					return failed
				elseif i == #filters then
					return result ~= "true" and result or self:Detour_CallOriginalFunction(funcName, args)
				end

				i = i + 1
			end
		else
			running[funcName] = nil

			return self:Detour_CallOriginalFunction(funcName, args)
		end
	end

	-- Set detour
	self:Detour_SetFunction(funcName, Detour)
	self.live.control[funcName].detour = Detour
end

-- Remove our detours
-- Used only by auto reloading functions
function BS:Detour_Remove()
	for k, _ in pairs(self.live.control) do
		self:Detour_SetFunction(k, self:Detour_GetFunction(k, _G))
	end
end
