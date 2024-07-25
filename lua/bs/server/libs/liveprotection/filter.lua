--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Process a string passed by argument
local function ScanArgument(BS, str, funcName, detected, warning)
    if not isstring(str) then return end
    if BS:Scan_Whitelist(str, BS.live.whitelists.snippets) then return end

    if istable(detected) then
        -- Invisible characters
        local foundChars = BS:Scan_Characters(BS, str, "lua")

        for invalidCharName, linesTab in pairs(foundChars) do
            table.insert(detected, invalidCharName)
        end

        -- Blacklisted functions
        local stackBlacklist = BS.liveBlacklistStack_FixedFormat2D[funcName]
        if stackBlacklist then
            local foundTerms = BS:Scan_Blacklist(BS, str, stackBlacklist, detected)

            for term, linesTab in pairs(foundTerms) do
                table.insert(detected, term)
            end
        end

        -- Blacklisted snippets
        local foundTerms = BS:Scan_Blacklist(BS, str, BS.live.blacklists.arguments.snippets)

        for term, linesTab in pairs(foundTerms) do
            table.insert(detected, term)
        end

        -- Blacklisted console commands and variables
        local foundTerms = BS:Scan_Blacklist(BS, str, BS.live.blacklists.arguments.console)

        for term, linesTab in pairs(foundTerms) do
            table.insert(detected, term)
        end
    end

    if istable(warning) then
    end

    return
end
table.insert(BS.locals, ScanArgument)

-- Scan http.Fetch and http.Post contents
-- Add persistent trace support to the called functions
function BS:Filter_ScanHttpFetchPost(trace, funcName, args, isLoose)
    local url = args[1]

    local function Scan(args2)
        local detected = {}
        local warning = {}

        for _, whitelistedUrl in ipairs(self.live.whitelists.urls) do
            local urlStart = string.find(url, whitelistedUrl, nil, true)

            if urlStart and urlStart == 1 then
                return self:Detour_CallOriginalFunction(funcName, args)
            end
        end

        ScanArgument(self, url, funcName, detected, warning)

        for _, arg in pairs(args2) do
            if isstring(arg) then
                ScanArgument(self, arg, funcName, detected, warning)
            elseif istable(arg) then
                for k, v in ipairs(arg) do
                    ScanArgument(self, k, funcName, detected, warning)
                    ScanArgument(self, v, funcName, detected, warning)
                end
            end
        end

        local report = not isLoose and #detected > 0 and { "detected", "Execution blocked!", detected } or
                       (isLoose or #warning > 0) and { "warning", "Suspicious execution".. (isLoose and " in a low-risk location" or "") .."!" .. (isLoose and " Ignoring it..." or ""), warning }

        if report then
            local info = {
                type = report[1],
                folder = funcName,
                alert = report[2],
                func = funcName,
                trace = trace,
                url = url,
                detected = report[3],
                snippet = table.ToString(args2, "arguments", true),
                file = self:Trace_GetLuaFile(trace)
            }

            self:Report_LiveDetection(info)
        end

        if not self.live.blockThreats or isLoose or not report then
            self:Trace_SetPersistent(args[2], funcName, trace)

            self:Detour_CallOriginalFunction(funcName, args)
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

    return "runOnFilter"
end

-- Check CompileString, CompileFile, RunString and RunStringEX contents
function BS:Filter_ScanStrCode(trace, funcName, args, isLoose)
    local code = funcName == "CompileFile" and file.Read(args[1], "LUA") or args[1]
    local detected = {}
    local warning = {}

    ScanArgument(self, code, funcName, detected, warning)

    local report = not isLoose and #detected > 0 and { "detected", "Execution blocked!", detected } or
                   (isLoose or #warning > 0) and { "warning", "Suspicious execution".. (isLoose and " in a low-risk location" or "") .."!" .. (isLoose and " Ignoring it..." or ""), warning }

    if report then
        local info = {
            type = report[1],
            folder = funcName,
            alert = report[2],
            func = funcName,
            trace = trace,
            detected = report[3],
            snippet = code,
            file = self:Trace_GetLuaFile(trace)
        }

        self:Report_LiveDetection(info)
    end

    if self.live.blockThreats and report and not isLoose then
        return true
    end

    return false
end

-- Validate functions that can't call each other
--   Return false if we detect something or "true" if it's fine.
--   Note that "true" is really between quotes because we need to identify it and not pass the value forward.
local callersWarningCooldown = {} -- Don't flood the console with messages
function BS:Filter_ScanStack(trace, funcName, args, isLoose)
    local protectedFuncName = self:Stack_Check(funcName)
    local detectedFuncName = funcName

    if protectedFuncName then
        if not callersWarningCooldown[detectedFuncName] then
            callersWarningCooldown[detectedFuncName] = true
            timer.Simple(0.01, function()
                callersWarningCooldown[detectedFuncName] = nil
            end)    

            local info = {
                type = isLoose and "warning" or "detected",
                folder = protectedFuncName,
                alert = isLoose and "Warning! Prohibited function call in a low-risk location! Ignoring it..." or "Detected function call!",
                func = protectedFuncName,
                trace = trace,
                detected = { detectedFuncName },
                file = self:Trace_GetLuaFile(trace)
            }

            self:Report_LiveDetection(info)
        end

        if self.live.blockThreats and not isLoose then
            return true
        else
            return false
        end
    else
        return false
    end
end

-- Add persistent trace support to the function called by timers
function BS:Filter_ScanTimers(trace, funcName, args)
    self:Trace_SetPersistent(args[2], funcName, trace)

    return false
end

-- Hide our detours
--   Force getinfo to jump our functions
function BS:Filter_ProtectDebugGetinfo(trace, funcName, args)
    if isfunction(args[1]) then
        return self:Filter_ProtectAddresses(trace, funcName, args)
    else
        return { self:Stack_SkipBSFunctionss(args) }
    end
end

-- Hide our detours
--   These functions are used to verify if other functions have valid addresses:
--     debug.getinfo, jit.util.funcinfo and tostring
--     Note: using this filter inside tostring is still unstable
local checking = {}
function BS:Filter_ProtectAddresses(trace, funcName, args)
    if checking[funcName] then -- Avoid loops
        return self:Detour_CallOriginalFunction(funcName, args)
    end
    checking[funcName] = true

    local changedArg = false
    if args[1] and isfunction(args[1]) then
        for funcName, detourTab in pairs(self.liveDetours) do
            if args[1] == detourTab.detourFunc then
                args[1] = self:Detour_GetFunction(funcName, _G)
                changedArg = true
                break
            end
        end
    end

    checking[funcName] = nil

    if changedArg then
        return { self:Detour_CallOriginalFunction(funcName, args) }
    else
        return false
    end
end

-- Protect our custom environment
--   Don't return it!
--     getfenv and debug.getfenv
function BS:Filter_ProtectEnvironment(trace, funcName, args)
    local result = self:Detour_CallOriginalFunction(funcName, args)
    result = result == _G and self.__G or result

    if result == self.__G then
        local info = {
            type = "warning",
            alert = "A script got _G through " .. funcName .. "!",
            func = funcName,
            trace = trace,
            file = self:Trace_GetLuaFile(trace)
        }

        self:Report_LiveDetection(info)
    end

    return { result }
end
