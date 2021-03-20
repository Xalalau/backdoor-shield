--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Try to get a stored trace given any function address
function BS:Trace_Get(currentTrace)
    local bankedTraceTab = self.traceBank[tostring(self:Stack_GetTopFunctionAddress())]
    local bankedTrace = bankedTraceTab and bankedTraceTab.trace
    local newFullTrace = (bankedTrace and ("      (+) BS - Persistent Trace" .. bankedTrace .. "") or "\n") .. "      " .. currentTrace .. "\n"
    local newFullTraceClean

    -- Let's remove older banked traces from the result if they exist
    if bankedTrace ~= "" then
        local _, countBankedTraces = string.gsub(newFullTrace, "(+)", "")

        if countBankedTraces >= 2 then
            local bankedTracesCounter = 0
            newFullTraceClean = "\n"

            for k,v in ipairs(string.Explode("\n", newFullTrace)) do
                if string.find(v, "(+)") then
                    bankedTracesCounter = bankedTracesCounter + 1
                end
                if bankedTracesCounter > countBankedTraces - 1 then
                    newFullTraceClean = newFullTraceClean .. v .. "\n"
                end
            end
        end
    end

    return newFullTraceClean or newFullTrace
end

-- Store a trace associated to a specific function that will lose it
function BS:Trace_Set(func, name, trace)
    local bankedTrace = self.traceBank[tostring(self:Stack_GetTopFunctionAddress())]

    if bankedTrace then
        trace = bankedTrace.trace .. trace
    end

    self.traceBank[tostring(func)] = { name = name, trace = trace }
end

-- Get the correct detected lua file from a trace stack
function BS:Trace_GetLuaFile(trace)
    local traceParts = string.Explode("\n", trace)
    local index

    -- From the trace top to the bottom:
    --   Find "stack traceback:", skip our own files and get the first valid lua file
    local foundStackStart
    for k,v in ipairs(traceParts) do
        if not foundStackStart and string.Trim(v) == "stack traceback:" then
            foundStackStart = true
        elseif foundStackStart then
            if not string.find(v, "/lua/bs/") and string.find(v, ".lua") then
                index = k
                break
            end
        end
    end

    return self:Utils_ConvertAddonPath(string.Trim(string.Explode(":",traceParts[index])[1]))
end