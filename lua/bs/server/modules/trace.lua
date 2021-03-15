--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- HACK: this function is as bad as Validate_Callers_Aux()
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

-- Try to get a stored trace given any function address
function BS:Trace_Get()
    local bankedTrace = self.traceBank[tostring(Trace_Get_Aux())]
    return bankedTrace and bankedTrace.trace or ""
end

-- Store a trace associated to a specific function that will lose it
function BS:Trace_Set(func, name, trace)
    local bankedTrace = self.traceBank[tostring(Trace_Get_Aux())]

    if bankedTrace then
        trace = bankedTrace.trace .. trace
    end

    self.traceBank[tostring(func)] = { name = name, trace = trace }
end
