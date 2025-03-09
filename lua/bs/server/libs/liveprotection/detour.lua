--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Initialize each detour with its filters
function BS:Detour_Init()
    for funcName, settingsDetourTab in pairs(self.live.detours) do
        local filterSetting = settingsDetourTab.filters or {}

        if isstring(filterSetting) then
            filterSetting = { filterSetting }
        end

        self.liveDetours[funcName] = {
            filters = {}
        }

        for k, filterName in ipairs(filterSetting) do
            self.liveDetours[funcName].filters[k] = self[filterName]
        end

        if not (game.SinglePlayer() and settingsDetourTab.multiplayerOnly) then
            self:Detour_Create(funcName, self.liveDetours[funcName].filters)
        end
    end
end

-- Auto detouring protection
--      First 5m running: check every 5s
--      Later: check every 60s
-- Note: This function isn't really necessary, but it's good for advancing detections
function BS:Detour_SetAutoCheck()
    local function SetAuto(name, delay)
        timer.Create(name, delay, 0, function()
            if self.reloaded then
                timer.Remove(name)

                return
            end

            for funcName, settingsDetourTab in pairs(self.live.detours) do
                if not (game.SinglePlayer() and settingsDetourTab.multiplayerOnly) then
                    self:Detour_Validate(funcName)
                end
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
    local detourAddress = self.liveDetours[funcName].detourFunc

    if not trace or string.len(trace) == 4 then
        local source = debug.getinfo(currentAddress, "S").source
        local luaFile = self:Utils_ConvertAddonPath(string.sub(source, 1, 1) == "@" and string.sub(source, 2))
        trace = [[ stack traceback:
          ]] .. luaFile
    end

    local isWhitelisted = self:Trace_IsWhitelisted(trace)

    if isWhitelisted then return isWhitelisted end -- I don't return if it's loose here because it doesn't matter and it saves processing

    local isLoose = self:Trace_IsLoose(trace)

    if detourAddress ~= currentAddress then
        local info = {
            func = funcName,
            trace = trace
        }

        if isLoose then
            info.type = "warning"
            info.alert = "Warning! Detour detected in a low-risk location. Ignoring it..."
        else
            info.type = "detour"
            info.alert = "Detour detected" .. (self.live.protectDetours and " and undone!" or "!")

            if self.live.protectDetours then
                self:Detour_SetFunction(funcName, detourAddress)
            end
        end

        self:Report_LiveDetection(info)
    end

    return isWhitelisted, isLoose
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
function BS:Detour_Create(funcName, filters)
    local running = {} -- Avoid loops

    function Detour(...)
        local args = {...} 

        -- Avoid loops
        if running[funcName] then
            return self:Detour_CallOriginalFunction(funcName, args)
        end
        running[funcName] = true

        -- Get and check the trace
        local trace = debug.traceback()
        trace = self:Trace_GetPersistent(trace)

        -- Check detour, whitelists and loose list
        local isWhitelisted, isLoose = self:Detour_Validate(funcName, trace)

        if isWhitelisted then
            running[funcName] = nil

            return self:Detour_CallOriginalFunction(funcName, args)
        end

        -- Run filters
        --[[
            Possible filter results:
                true = Detections. Stop the execution and return retunOnDetection if it exists
                false = No detections. If all filters return false, run the original function with the original args
                "runOnFilter" = the filter takes care of detecting threats and executing the functions
                table = No detections. The filter took care of executing the function and returned the result iside a table.
                        This feature can be used once per detoured function. This can be changed in the future if the need arises.
            Note: 
        ]]
        local runOnFilter = false
        local returnedResult = nil
        if filters then
            for k, filter in ipairs(filters) do
                local result = filter(self, trace, funcName, args, isLoose)

                if result == "runOnFilter" then
                    runOnFilter = true
                elseif istable(result) then
                    returnedResult = result
                elseif result == true then
                    running[funcName] = nil
    
                    return self.live.detours[funcName].retunOnDetection
                end

                if k == #filters then
                    running[funcName] = nil
                    if not runOnFilter then
                        if returnedResult then
                            return unpack(returnedResult)
                        else
                            return self:Detour_CallOriginalFunction(funcName, args)
                        end
                    end
                end
            end
        else
            running[funcName] = nil

            return self:Detour_CallOriginalFunction(funcName, args)
        end
    end

    -- Set detour
    self:Detour_SetFunction(funcName, Detour)
    self.liveDetours[funcName].detourFunc = Detour
end

-- Remove our detours
-- Used only by auto reloading functions
function BS:Detour_RemoveAll()
    for funcName, detourTab in pairs(self.liveDetours) do
        self:Detour_SetFunction(funcName, self:Detour_GetFunction(funcName, _G))
    end
end
