--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Auto check for detouring
-- 	 First 5m running: check every 5s
-- 	 Later: check every 60s
function BS:Validate_AutoCheckDetouring()
	local function SetAuto(name, delay)
		timer.Create(name, delay, 0, function()
			if self.RELOADED then
				timer.Remove(name)

				return
			end

			for k,v in pairs(self.control) do
				self:Validate_Detour(k, v)
			end
		end)
	end

	local name = self:Utils_GetRandomName()

	SetAuto(name, 5)

	timer.Simple(300, function()
		SetAuto(name, 60)
	end)
end

-- Check a detour
function BS:Validate_Detour(funcName, controlInfo, trace)
	local currentAddress = self:Functions_GetCurrent(funcName)
	local originalAddress = controlInfo.detour or controlInfo.original
	local trace_aux = debug.getinfo(currentAddress, "S").source

	if originalAddress ~= currentAddress then
		local info = {
			func = name,
			trace = trace or trace_aux
		}

		-- Check if it's a low risk detection. If so, only report
		local lowRisk = false
		trace_aux = self:Utils_ConvertAddonPath(string.sub(trace_aux, 1, 1) == "@" and string.sub(trace_aux, 2))

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
			if self.IGNORED_DETOURS[trace_aux] then
				return true
			end

			info.suffix = "warning"
			info.alert = "Warning! Detour detected in a low risk location. Ignoring it..."
			self.IGNORED_DETOURS[trace_aux] = true
		else
			info.suffix = "detour"
			info.alert = "Detour captured and undone!"

			self:Functions_SetDetour_Aux(funcName, originalAddress)
		end

		self:Report_Detection(info)

		return false
	end

	return true
end

-- Check http.fetch calls
function BS:Validate_HttpFetchPost(trace, funcName, args)
	local url = args[1]

	local function Scan(args2)
		local blocked = {{}, {}}
		local warning = {}
		local detected

		for k,v in pairs(self.whitelistUrls) do
			local urlStart = string.find(url, v)

			if urlStart and urlStart == 1 then
				return self:Functions_CallProtected(funcName, args)
			end
		end

		self:Scan_String(trace, url, "lua", blocked, warning)

		for _,arg in pairs(args2) do
			if isstring(arg) then
				self:Scan_String(trace, arg, "lua", blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					self:Scan_String(trace, k, "lua", blocked, warning)
					self:Scan_String(trace, v, "lua", blocked, warning)
				end
			end
		end

		local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Execution blocked!", blocked } or
		                 #warning > 0 and { "warning", "Suspicious execution!", warning }

		if detected then
			local info = {
				suffix = detected[1],
				folder = funcName,
				alert = detected[2],
				func = funcName,
				trace = trace,
				url = url,
				detected = detected[3],
				content = table.ToString(args2, "arguments", true)
			}

			self:Report_Detection(info)
		end

		if #blocked[1] == 0 and #blocked[2] == 0 then
			self:Functions_CallProtected(funcName, args)
		end
	end

	if funcName == "http.Fetch" then
		http.Fetch(url, function(...)
			local args2 = { ... }
			Scan(args2)
		end, function(...)
			local args2 = { ... }
			Scan(args2)
		end, args[4])
	elseif funcName == "http.Post" then
		http.Post(url, args[2], function(...)
			local args2 = { ... }
			args2[9999] = args[2]
			Scan(args2)
		end, function(...)
			local args2 = { ... }
			args2[9999] = args[2]
			Scan(args2)
		end, args[5])
	end
end

-- Check CompileString, CompileFile, RunString and RunStringEX calls
function BS:Validate_StrCode(trace, funcName, args)
	local code = funcName == "CompileFile" and file.Read(args[1], "LUA") or args[1]
	local blocked = {{}, {}}
	local warning = {}

	if not _G[funcName] then return "" end -- RunStringEx exists but is deprecated
	if not isstring(code) then return "" end -- Just checking

	self:Scan_String(trace, code, "lua", blocked, warning)

	local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Execution blocked!", blocked } or
	                 #warning > 0 and { "warning", "Suspicious execution!", warning }

	if detected then
		local info = {
			suffix = detected[1],
			folder = funcName,
			alert = detected[2],
			func = funcName,
			trace = trace,
			detected = detected[3],
			content = code
		}

		self:Report_Detection(info)
	end

	return #blocked[1] == 0 and #blocked[2] == 0 and self:Functions_CallProtected(funcName, #args > 0 and args or {""}) or not funcName == "CompileFile" and "" or nil
end

-- Protect our custom environment
function BS:Validate_Environment(trace, funcName, args)
	local result = self:Functions_CallProtected(funcName, args)
	result = result == _G and self.__G or result

	if result == self.__G then
		local info = {
			suffix = "warning",
			alert = "A script got _G through " .. funcName .. "!",
			func = funcName,
			trace = trace,
		}

		self:Report_Detection(info)
	end

	return result
end

-- Hide our detours
--   These functions are used to verify if other functions have valid addresses:
--     debug.getinfo, jit.util.funcinfo and tostring
local checking = {}
function BS:Validate_Adrresses(trace, funcName, args)
	if checking[funcName] then -- Avoid loops
		return self:Functions_CallProtected(funcName, args)
	end
	checking[funcName] = true

	if args[1] and isfunction(args[1]) then
		for k,v in pairs(self.control) do
			if args[1] == v.detour then
				args[1] = self:Functions_GetCurrent(k, _G)
				break
			end
		end
	end

	checking[funcName] = nil
	return self:Functions_CallProtected(funcName, args)
end
