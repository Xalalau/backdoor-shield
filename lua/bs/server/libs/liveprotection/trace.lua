--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Try to get a stored trace given any function address
function BS:Trace_Get(currentTrace)
    local stackedTraceInfo = self.traceStacks[tostring(self:Stack_GetTopFunctionAddress())]
    local stackedTrace = stackedTraceInfo and stackedTraceInfo.trace
    local newFullTrace = (stackedTrace and ("\n      (+) BS - Persistent Trace" .. stackedTrace .. "") or "\n") .. "      " .. currentTrace .. "\n"
    local newFullTraceClean

    -- Let's remove older stacked traces from the result if they exist
    if stackedTrace ~= "" then
        local _, countstackedTraces = string.gsub(newFullTrace, "(+)", "")

        if countstackedTraces >= 2 then
            local stackedTracesCounter = 0
            newFullTraceClean = "\n"

            for k, traceLine in ipairs(string.Explode("\n", newFullTrace)) do
                if string.find(traceLine, "(+)", nil, true) then
                    stackedTracesCounter = stackedTracesCounter + 1
                end
                if stackedTracesCounter > countstackedTraces - 1 then
                    newFullTraceClean = newFullTraceClean .. traceLine .. "\n"
                end
            end
        end
    end

    return newFullTraceClean or newFullTrace
end

-- Store a trace associated to a specific function that will lose it
function BS:Trace_Set(func, name, trace)
    local stackedTrace = self.traceStacks[tostring(self:Stack_GetTopFunctionAddress())]

    if stackedTrace then
        trace = stackedTrace.trace .. trace
    end

    self.traceStacks[tostring(func)] = { name = name, trace = trace }
end

-- Get the correct detected lua file from a trace stack
function BS:Trace_GetLuaFile(trace)
    -- The trace is a path starting with @
    if trace and string.sub(trace, 1, 1) == "@" then
        return self:Utils_ConvertAddonPath(string.sub(trace, 2))
    end

    -- No trace or it's "[c]"
    if not trace or string.len(trace) == 4 then
        trace = debug.traceback()
    end

    local traceLines = string.Explode("\n", trace)
    local index

    -- From the trace top to the bottom:
    --   Find "stack traceback:", skip our own files and get the first valid lua file
    local foundStackStart
    for k, traceLine in ipairs(traceLines) do
        if not foundStackStart and string.Trim(traceLine) == "stack traceback:" then
            foundStackStart = true
        elseif foundStackStart then
            if not string.find(traceLine, "/lua/" .. self.folder.lua, nil, true) and not string.find(traceLine, "main chunk", nil, true) and string.find(traceLine, ".lua", nil, true) then
                index = k
                break
            end
        end
    end

    return index and self:Utils_ConvertAddonPath(string.Trim(string.Explode(":",traceLines[index])[1])) or trace and string.find(trace, ".lua", nil, true) and trace or ""
end

-- Check if the trace is of a low-risk detection
function BS:Trace_IsLoose(trace)
    local isLoose = false
    local luaFile = self:Trace_GetLuaFile(trace)

    if self.liveLooseFiles_InverseTab[luaFile] then
        isLoose = true
    else
        for _,v in ipairs(self.live.loose.folders) do
            local start = string.find(luaFile, v, nil, true)

            if start == 1 then
                isLoose = true

                break
            end
        end
    end

    return isLoose
end

-- Check if the trace is of a whitelisted detection
function BS:Trace_IsWhitelisted(trace)
    local isWhitelisted = false
    local luaFile = self:Trace_GetLuaFile(trace)

    if self.liveWhitelistsFiles_InverseTab[luaFile] then
        isWhitelisted = true
    else
        for _, _file in ipairs(self.live.whitelists.folders) do
            local start = string.find(luaFile, _file, nil, true)

            if start == 1 then
                isWhitelisted = true
                break
            end
        end
    end

    return isWhitelisted
end