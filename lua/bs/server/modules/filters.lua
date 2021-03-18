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

-- Create our protectedCalls table
function BS:Filters_CheckStack_Init()
	local function setField(protectedFunc)
		self.protectedCalls[protectedFunc] = self:Detours_GetFunction(protectedFunc)
	end

	for protectedFunc,_ in pairs(self.controlsBackup) do
		local filters = self.controlsBackup[protectedFunc].filters

		if isstring(filters) then
			if filters == "Filters_CheckStack" then
				setField(protectedFunc)
			end
		elseif istable(filters) then
			for k,filters2 in ipairs(filters) do
				if filters2 == "Filters_CheckStack" then
					setField(protectedFunc)
					break
				end
			end
		end
	end
end

-- HACKS: For some reason this function is EXTREMELY temperamental! I was unable to use the
-- code inside the orignal function, to pass parameters and even to freely write variables
-- or acceptable syntax. It only works when it's this mess. Test each changed line if you
-- want to touch it, or you will regret it bitterly.
-- If the stack is good, return false
-- If the stack is bad, return "protected func name" and "detected func name"
local BS_protectedCalls_Hack
local BS_traceBank_Hack
local _debug = {}
_debug.getinfo = debug.getinfo   -- Store original function addresses during the addon initialization
_debug.getlocal = debug.getlocal -- It's done this way to work around a function address verification problem specific of that function crazy
local hack_Callers_identify ={ [tostring(_debug.getinfo)] = true }
local function Filters_CheckStack_Aux()
	local counter = { increment = 1, detected = 0, firstDetection = "" } -- Do NOT add more variables other than inside this table, or the function is going to stop working
	while true do
		local func = _debug.getinfo(counter.increment, "flnSu" )
		local name, value = _debug.getlocal(1, 2, counter.increment)
		if func == nil then break end
		if value then
			-- Update the name and address using info from the trace bank, if it's the case
			local traceBank = BS_traceBank_Hack[tostring(value.func)]
			if traceBank then
				local func = _G
				for k,v in ipairs(string.Explode(".", traceBank.name)) do
					func = func[v]
				end
				value.func = func -- Use the address of the last function from the older stack, so we can keep track of what's happening
				value.name = traceBank.name -- Update the name just to make prints nicer in here
			end
			-- Now we are going to check if it's a protected function call
			if value.func then
				for funcName,funcAddress in pairs(BS_protectedCalls_Hack) do -- I tried to use the function address as index but it doesn't work here
					if tostring(value.func) == tostring(funcAddress) then -- I tried to compare the addresses directly but it also doesn't work here
						value.name = funcName -- Update the name just to make prints nicer in here
						counter.detected = counter.detected + 1
						if counter.detected == 2 then  -- The rule is that we can't have 2 protected calls stacked, so return what we've found
							return counter.firstDetection, funcName
						else
							counter.firstDetection = funcName -- Get the pretty name of the first protected call to return it later, if it's the case
						end
						break
					end
				end
			end
			-- Debug
			--print(value.name and value.name or "")
			--print(value.func)
		end
		counter.increment = counter.increment + 1
	end
	return false
end
--table.insert(BS.locals, Filters_CheckStack_Aux) -- I can't check the stack in the wrong environment

-- Validate functions that can't call each other
local callersWarningCooldown = {} -- Don't flood the console with messages
function BS:Filters_CheckStack(trace, funcName, args)
	-- Hacks, explained above Filters_CheckStack_Aux()
	--   Expose internal values to this file local scope
	if not BS_protectedCalls_Hack then
		BS_protectedCalls_Hack = table.Copy(self.protectedCalls)
	end
	if not BS_traceBank_Hack then
		BS_traceBank_Hack = self.traceBank
	end

	local detectedFuncName, protectedFuncName = Filters_CheckStack_Aux()

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
		return true
	end
end

-- Add persistent trace support to the function called by timers
function BS:Filters_CheckTimers(trace, funcName, args)
	self:Trace_Set(args[2], funcName, trace)

	return self:Detours_CallOriginalFunction(funcName, args)
end

-- HACK: this function is as bad as Filters_CheckStack_Aux()
local argsPop = {}
local function Filters_ProtectDebugGetinfo_Aux()
	local vars = { increment = 1, foundGetinfo = false, args }
	for k,v in ipairs(argsPop) do -- This is how I'm passing arguments
		vars.args = v
		argsPop[k] = nil
		break
	end
	while true do
		local func = _debug.getinfo(vars.increment, "flnSu" )
		local name, value = _debug.getlocal(1, 2, vars.increment)
		if func == nil then break end
		--print(value.name)
		--print(value.func == debug.getinfo)
		if value then
			if vars.foundGetinfo then
				if vars.args[1] == 1 then
					return _debug.getinfo(vars.increment, vars.args[2])
				end
				vars.args[1] = vars.args[1] - 1
			elseif value.func == debug.getinfo then
				if vars.args[1] == 1 then
					return _debug.getinfo(vars.increment, vars.args[2])
				else
					vars.foundGetinfo = true
					vars.args[1] = vars.args[1] - 1
				end
			end
		end
		vars.increment = vars.increment + 1
	end
end
--table.insert(BS.locals, Filters_ProtectDebugGetinfo_Aux) -- I can't check the stack in the wrong environment

-- Hide our detours
--   Force getinfo to jump our functions
function BS:Filters_ProtectDebugGetinfo(trace, funcName, args)
	if isfunction(args[1]) then
		return self:Filters_ProtectAddresses(trace, funcName, args)
	else
		table.insert(argsPop, args)
		return Filters_ProtectDebugGetinfo_Aux()
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
