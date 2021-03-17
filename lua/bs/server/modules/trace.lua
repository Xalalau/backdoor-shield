--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- HACK: this function is as bad as Filters_CheckStack_Aux()
local _debug = {}
_debug.getinfo = debug.getinfo
_debug.getlocal = debug.getlocal
local function Trace_Get_Aux()
	local vars = { increment = 1, func = nil }
	while true do
		local func = _debug.getinfo(vars.increment, "flnSu")
		local name, value = _debug.getlocal(1, 2, vars.increment)
		if func == nil then break end
		if value then
            vars.func = value.func
		end
		vars.increment = vars.increment + 1
	end
    return vars.func
end
--table.insert(BS.locals, Trace_Get_Aux) -- I can't check the stack in the wrong environment

-- Try to get a stored trace given any function address
function BS:Trace_Get(currentTrace, funcName)
    local bankedTraceTab = self.traceBank[tostring(Trace_Get_Aux())]
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

    if funcName == "RunString" then
        --print("RunString")

        --print(newFullTraceClean or newFullTrace)
    end

    return newFullTraceClean or newFullTrace
end

-- Store a trace associated to a specific function that will lose it
function BS:Trace_Set(func, name, trace)
    local bankedTrace = self.traceBank[tostring(Trace_Get_Aux())]

    if bankedTrace then
        trace = bankedTrace.trace .. trace
    end

    self.traceBank[tostring(func)] = { name = name, trace = trace }
end
