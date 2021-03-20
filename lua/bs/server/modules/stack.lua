--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/

   HACKS: For some reason these functions are EXTREMELY temperamental! I was unable to use the
   code nested, to pass arguments and even to freely write variables or acceptable syntax. They
   only work when it's this mess. Test each changed line if you want to touch them, or you'll
   regret it bitterly!

   Note: I can't check the stack in the wrong environment, so don't use this here:
   table.insert(BS.locals, some_function)
]]

-- I can't pass arguments or move the functions to our environment, so I copy my tables locally
local BS_protectedCalls_Hack
local BS_traceBank_Hack

-- Protect against detouring and always get real results
local _debug = {}
_debug.getinfo = debug.getinfo   
_debug.getlocal = debug.getlocal

-- Workaround to pass arguments
local argsPop = {}

-- Copy some tables locally
function BS:Stack_Init()
	BS_protectedCalls_Hack = table.Copy(self.protectedCalls)
	BS_traceBank_Hack = self.traceBank
end

-- Insert arguments into argsPop
function BS:Stack_InsertArgs(args)
    table.insert(argsPop, args)
end

-- Check for prohibited function combinations (scanning by address)
-- If the stack is good, return false
-- If the stack is bad, return "detected func name" and "protected func name"
local function Stack_Check()
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

function BS:Stack_Check()
    return Stack_Check()
end

-- Get the function of the higher call in the stack
local function Stack_GetTopFunctionAddress()
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

function BS:Stack_GetTopFunctionAddress()
    return Stack_GetTopFunctionAddress()
end

-- Return the result debug.getinfo result skipping our functions
local function Stack_SkipBSFunctions()
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

function BS:Stack_SkipBSFunctions()
    return Stack_SkipBSFunctions()
end