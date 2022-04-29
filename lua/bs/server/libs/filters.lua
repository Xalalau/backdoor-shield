--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/

    Note: if a filter validates but doesn't return the result from Detours_CallOriginalFunction(), just return "true" (between quotes!)
--]]

-- Scan http.Fetch and http.Post contents
-- Add persistent trace support to the called functions
function BS:Filters_CheckHttpFetchPost(trace, funcName, args, isLowRisk)
	local url = args[1]

	local function Scan(args2)
		local blocked = {}
		local warning = {}
		local detected

		for k,v in pairs(self.whitelists.urls) do
			local urlStart = string.find(url, v)

			if urlStart and urlStart == 1 then
				return self:Detours_CallOriginalFunction(funcName, args)
			end
		end

		self:Arguments_Scan(url, funcName, blocked, warning)

		for _,arg in pairs(args2) do
			if isstring(arg) then
				self:Arguments_Scan(arg, funcName, blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					self:Arguments_Scan(k, funcName, blocked, warning)
					self:Arguments_Scan(v, funcName, blocked, warning)
				end
			end
		end

		local detected = not isLowRisk and #blocked > 0 and { "blocked", "Execution " .. (self.live.blockThreats and "blocked!" or "detected!"), blocked } or
						 (isLowRisk or #warning > 0) and { "warning", "Suspicious execution".. (isLowRisk and " in a low-risk location" or "") .."!" .. (isLowRisk and " Ignoring it..." or ""), warning }

		if detected then
			local info = {
				type = detected[1],
				folder = funcName,
				alert = detected[2],
				func = funcName,
				trace = trace,
				url = url,
				detected = detected[3],
				snippet = table.ToString(args2, "arguments", true),
				file = self:Trace_GetLuaFile(trace)
			}

			self:Report_Detection(info)
		end

		if not self.live.blockThreats or isLowRisk or not detected then
			self:Trace_Set(args[2], funcName, trace)

			self:Detours_CallOriginalFunction(funcName, args)
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

	return true
end

-- Check CompileString, CompileFile, RunString and RunStringEX contents
function BS:Filters_CheckStrCode(trace, funcName, args, isLowRisk)
	local code = funcName == "CompileFile" and file.Read(args[1], "LUA") or args[1]
	local blocked = {}
	local warning = {}

	if not _G[funcName] then return "" end -- RunStringEx exists but is deprecated
	if not isstring(code) then return "" end -- Just checking

	self:Arguments_Scan(code, funcName, blocked, warning)

	local detected = not isLowRisk and #blocked > 0 and { "blocked", "Execution " .. (self.live.blockThreats and "blocked!" or "detected!"), blocked } or
	                 (isLowRisk or #warning > 0) and { "warning", "Suspicious execution".. (isLowRisk and " in a low-risk location" or "") .."!" .. (isLowRisk and " Ignoring it..." or ""), warning }

	if detected then
		local info = {
			type = detected[1],
			folder = funcName,
			alert = detected[2],
			func = funcName,
			trace = trace,
			detected = detected[3],
			snippet = code,
			file = self:Trace_GetLuaFile(trace)
		}

		self:Report_Detection(info)
	end

	return (not self.live.blockThreats or isLowRisk or not detected) and self:Detours_CallOriginalFunction(funcName, #args > 0 and args or {""})
end

-- Validate functions that can't call each other
--   Return false if we detect something or "true" if it's fine.
--   Note that "true" is really between quotes because we need to identify it and not pass the value forward.
local callersWarningCooldown = {} -- Don't flood the console with messages
function BS:Filters_CheckStack(trace, funcName, args, isLowRisk)
	local protectedFuncName = self:Stack_Check(funcName)
	local detectedFuncName = funcName
	local whitelisted

	if protectedFuncName then
		if not callersWarningCooldown[detectedFuncName] then
			callersWarningCooldown[detectedFuncName] = true
			timer.Simple(0.01, function()
				callersWarningCooldown[detectedFuncName] = nil
			end)	

			-- Whitelist
			for _,combo in pairs(self.whitelists.stack) do
				if protectedFuncName == combo[1] then
					if detectedFuncName == combo[2] then
						whitelisted = true
					end
				end
			end

			if not whitelisted then
				local info = {
					type = isLowRisk and "warning" or "blocked",
					folder = protectedFuncName,
					alert = isLowRisk and "Warning! Prohibited function call in a low-risk location! Ignoring it..." or self.live.blockThreats and "Blocked function call!" or "Detected function call!",
					func = protectedFuncName,
					trace = trace,
					detected = { detectedFuncName },
					file = self:Trace_GetLuaFile(trace)
				}

				self:Report_Detection(info)
			end
		end

		if not self.live.blockThreats or isLowRisk or whitelisted then
			return "true"
		else
			return false
		end
	else
		return "true"
	end
end

-- Add persistent trace support to the function called by timers
function BS:Filters_CheckTimers(trace, funcName, args)
	self:Trace_Set(args[2], funcName, trace)

	return self:Detours_CallOriginalFunction(funcName, args)
end

-- Hide our detours
--   Force getinfo to jump our functions
function BS:Filters_ProtectDebugGetinfo(trace, funcName, args)
	if isfunction(args[1]) then
		return self:Filters_ProtectAddresses(trace, funcName, args)
	else
		local result = self:Stack_SkipBSFunctions(args)
		return result
	end
end

-- Hide our detours
--   These functions are used to verify if other functions have valid addresses:
--     debug.getinfo, jit.util.funcinfo and tostring
local checking = {}
function BS:Filters_ProtectAddresses(trace, funcName, args)
	if checking[funcName] then -- Avoid loops
		return self:Detours_CallOriginalFunction(funcName, args)
	end
	checking[funcName] = true

	if args[1] and isfunction(args[1]) then
		for k,v in pairs(self.live.control) do
			if args[1] == v.detour then
				args[1] = self:Detours_GetFunction(k, _G)
				break
			end
		end
	end

	checking[funcName] = nil
	return self:Detours_CallOriginalFunction(funcName, args)
end

-- Protect our custom environment
--   Don't return it!
--     getfenv and debug.getfenv
function BS:Filters_ProtectEnvironment(trace, funcName, args)
	local result = self:Detours_CallOriginalFunction(funcName, args)
	result = result == _G and self.__G or result

	if result == self.__G then
		local info = {
			type = "warning",
			alert = "A script got _G through " .. funcName .. "!",
			func = funcName,
			trace = trace,
			file = self:Trace_GetLuaFile(trace)
		}

		self:Report_Detection(info)
	end

	return result
end
