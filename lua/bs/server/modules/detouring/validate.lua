--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

-- Auto check for detouring
-- 	 First 5m running: check every 5s
-- 	 Later: check every 60s
function BS:Validate_AutoCheckDetouring()
	local function SetAuto(name, delay)
		timer.Create(name, delay, 0, function()
			if self.RELOADED then
				timer.Destroy(name)

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
function BS:Validate_Detour(name, controlInfo, trace)
	local f1, f2, f3 = unpack(string.Explode(".", name))
	local currentAddress = self:Functions_GetCurrent(f1, f2, f3)
	local originalAddress = controlInfo.replacement or controlInfo.original

	if originalAddress ~= currentAddress then
		local info = {
			suffix = "detour",
			alert = "Detour captured and undone!",
			func = name,
			trace = trace or debug.getinfo(currentAddress, "S").source
		}

		self:Report_Detection(info)

		self:Functions_Detour_Aux(originalAddress, f1, f2, f3)

		return false
	end

	return true
end

-- Check http.fetch calls
function BS:Validate_HttpFetch(trace, funcName, args)
	local url = args[1]

	http.Fetch(url, function(...)
		local args2 = { ... }
		local blocked = {{}, {}}
		local warning = {}
		local detected

		for k,v in pairs(self.whitelistUrls) do
			local urlStart = string.find(url, v)

			if urlStart and urlStart == 1 then
				return self.control[funcName].original(unpack(args))
			end
		end

		self:Scan_String(trace, url, blocked, warning)

		for _,arg in pairs(args2) do
			if isstring(arg) then
				self:Scan_String(trace, arg, blocked, warning)
			elseif istable(arg) then
				for k,v in pairs(arg) do
					self:Scan_String(trace, k, blocked, warning)
					self:Scan_String(trace, v, blocked, warning)
				end
			end
		end

		local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

		if detected then
			local info = {
				suffix = detected[1],
				folder = funcName,
				alert = detected[2] .. " execution!",
				func = funcName,
				trace = trace,
				url = url,
				detected = detected[3],
				content = table.ToString(args2, "arguments", true)
			}

			self:Report_Detection(info)
		end

		if #blocked[1] == 0 and #blocked[2] == 0 then
			self.control[funcName].original(unpack(args))
		end
	end, args[3], args[4])
end

-- Check CompileString and RunString(EX) calls
function BS:Validate_CompileOrRunString_Ex(trace, funcName, args)
	local code = args[1]
	local blocked = {{}, {}}
	local warning = {}

	if not self.__G_SAFE[funcName] then -- RunStringEx exists but is deprecated
		return ""
	end

	self:Scan_String(trace, code, blocked, warning)

	local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

	if detected then
		local info = {
			suffix = detected[1],
			folder = funcName,
			alert = detected[2] .. " execution!",
			func = funcName,
			trace = trace,
			detected = detected[3],
			content = code
		}

		self:Report_Detection(info)
	end

	return #blocked[1] == 0 and #blocked[2] == 0 and self.control[funcName].original(unpack(args)) or ""
end

-- Check CompileFile calls
function BS:Validate_CompileFile(trace, funcName, args)
	local path = args[1]
	local content = file.Read(path, "LUA")
	local blocked = {{}, {}}
	local warning = {}

	if not isstring(content) then
		return
	end

	self:Scan_String(trace, content, blocked, warning)

	local detected = (#blocked[1] > 0 or #blocked[2] > 0) and { "blocked", "Blocked", blocked } or #warning > 0 and { "warning", "Suspect", warning }

	if detected then
		local info = {
			suffix = detected[1],
			folder = funcName,
			alert = detected[2] .. " execution!",
			func = funcName,
			trace = trace,
			detected = detected[3],
			content = content
		}

		self:Report_Detection(info)
	end

	return #blocked[1] == 0 and #blocked[2] == 0 and self.control[funcName].original(unpack(args))
end

-- Protect our custom environment
function BS:Validate_GetFEnv(trace, funcName, args)
	local result = self.control[funcName].original(unpack(args))
	result = result == self.__G_SAFE and self.__G or result

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

-- Mask our function replacements
function BS:Validate_DebugGetInfo(trace, funcName, args)
	local result = self.control[funcName].original(unpack(args))

	if result and (result.short_src or result.source) then
		for k,v in pairs(self.control) do
			local detour = self:Functions_GetCurrent(unpack(string.Explode(".", k)))

			if args[1] == detour then
				if result.short_src then
					result.short_src = v.short_src
				end

				if result.source then
					result.source = v.source
				end
			end
		end
	end

	return result
end

-- Mask our function replacements
function BS:Validate_JitUtilFuncinfo(trace, funcName, args)
	for k,v in pairs(self.control) do
		local detour = self:Functions_GetCurrent(unpack(string.Explode(".", k)))

		if args[1] == detour then
			return self.control[funcName].jit_util_funcinfo
		end
	end

	return self.control[funcName].original(unpack(args))
end