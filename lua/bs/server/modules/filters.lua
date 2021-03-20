--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Scan http.Fetch and http.Post contents
-- Add persistent trace support to the called functions
function BS:Filters_CheckHttpFetchPost(trace, funcName, args)
	local url = args[1]

	local function Scan(args2)
		local blocked = {{}, {}}
		local warning = {}
		local detected

		for k,v in pairs(self.whitelistUrls) do
			local urlStart = string.find(url, v)

			if urlStart and urlStart == 1 then
				return self:Detours_CallOriginalFunction(funcName, args)
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

		if #blocked[1] == 0 and #blocked[2] == 0 then
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
function BS:Filters_CheckStrCode(trace, funcName, args)
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

	return #blocked[1] == 0 and #blocked[2] == 0 and self:Detours_CallOriginalFunction(funcName, #args > 0 and args or {""})
end

-- Validate functions that can't call each other
local callersWarningCooldown = {} -- Don't flood the console with messages
function BS:Filters_CheckStack(trace, funcName, args)
	local detectedFuncName, protectedFuncName = self:Stack_Check()

	if protectedFuncName then
		if not callersWarningCooldown[protectedFuncName] then
			callersWarningCooldown[protectedFuncName] = true
			timer.Simple(0.01, function()
				callersWarningCooldown[protectedFuncName] = nil
			end)

			-- Whitelist
			local whitelisted
			for _,combo in pairs(self.whitelistedCallerCombos) do
				if protectedFuncName == combo[1] then
					if detectedFuncName == combo[2] then
						whitelisted = true
					end
				end
			end		

			if not whitelisted then
				local info = {
					type = "blocked",
					folder = protectedFuncName,
					alert = "Blocked function call!",
					func = protectedFuncName,
					trace = trace,
					detected = { detectedFuncName },
					file = self:Trace_GetLuaFile(trace)
				}

				self:Report_Detection(info)
			end
		end

		return false
	else
		-- This check is fine, but we cannot use its result in the main call
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
		self:Stack_InsertArgs(args)
		return Stack_SkipBSFunctions()
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
		for k,v in pairs(self.control) do
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
