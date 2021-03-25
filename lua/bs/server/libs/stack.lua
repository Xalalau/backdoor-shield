--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/

   HACKS: For some reason these functions are EXTREMELY temperamental! I was unable to use the
   nested code, to pass arguments and even to freely write variables or acceptable syntax. They
   only work when it's this mess. Test each changed line if you want to touch them, or you'll
   regret it bitterly!

   Note: I can't check the stack in the wrong environment, so don't use this:
     table.insert(BS.locals, some_function)
   when there're _debug.getinfo or _debug.getlocal present.
]]

-- I can't pass arguments or move the functions to our environment, so I copy my tables locally
local BS_protectedCalls_Hack
local BS_traceBank_Hack

-- Protect against detouring and always get real results
local _debug = {}
_debug.getinfo = debug.getinfo   
_debug.getlocal = debug.getlocal

local _string = {}
_string.Explode = string.Explode
_string.find = string.find

local _tostring = tostring
local _ipairs = ipairs
local _pairs = pairs
local __G = _G

-- Workaround to pass arguments
local argsPop = {}

-- Copy some tables locally (also a workaround)
function BS:Stack_Init()
	BS_protectedCalls_Hack = table.Copy(self.protectedCalls)
	BS_traceBank_Hack = self.traceBank
end

-- Insert arguments into argsPop
local function InsertArgs(args)
    table.insert(argsPop, args)
end
table.insert(BS.locals, InsertArgs)

-- Check for prohibited function combinations (scanning by address)
-- If the stack is good, return false
-- If the stack is bad, return "protected func name"
local function Stack_Check()
	local vars = { -- Note: adding new variables outside this table can break the function for some reason
		increment = 1,
		detected = 0,
		currentFuncAddress,
		currentFuncName
	}

	-- This is how I'm passing arguments
	for k,arg in _ipairs(argsPop) do
		vars.currentFuncAddress = arg[1]
		vars.currentFuncName = arg[2]
		argsPop[k] = nil
		break
	end

	while true do
		local func = _debug.getinfo(vars.increment, "flnSu" )

		if func == nil then break end

		local name, value = _debug.getlocal(1, 2, vars.increment)

		if value then
			-- Update the name and address using info from the trace bank, if it's the case
			local traceBank = BS_traceBank_Hack[_tostring(value.func)]

			if traceBank then
				local func = __G

				for k,v in _ipairs(_string.Explode(".", traceBank.name)) do
					func = func[v]
				end

				value.func = func -- Use the address of the last function from the older stack, so we can keep track of what's happening
				value.name = traceBank.name
			end
	
			-- Now we are going to check if it's a protected function call
			if value.func then
				-- Find the current call
				if vars.detected == 0 and _tostring(value.func) == _tostring(vars.currentFuncAddress) then -- I tried to compare the addresses directly but it doesn't work here
					-- Debug
					--print("---> FOUND CURRENT CALL")

					vars.detected = vars.detected + 1
					value.name = vars.currentFuncName
				else
					-- Find a forbidden previous caller
					for funcName,funcAddress in _pairs(BS_protectedCalls_Hack) do -- I tried to use the function address as index but it doesn't work here
					   if vars.detected == 1 and _tostring(value.func) == _tostring(funcAddress) then 
							-- Debug
							--print("---> FOUND FORBIDDEN CALLER")

							vars.detected = vars.detected + 1
							value.name = funcName
					   end
					end
				end
			end
		end

		-- Debug
		--print(value.name and value.name or "")
		--print(value.func)
		
		-- Forbidden caller found
		if vars.detected == 2 then
			return value.name
		end

		vars.increment = vars.increment + 1
	end
	return false
end

function BS:Stack_Check(funcName)
	InsertArgs({ self:Detours_GetFunction(funcName), funcName })
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
	local vars = { -- Note: adding new variables outside this table can break the function for some reason
		increment = 1,
		skipLevel = false, 
		foundGetinfo = false,
		foundBSAgain = false,
		requiredStackLevel,
		requiredFields,
		luaFolder,
		args
	}

	-- This is how I'm passing arguments
	for k,arg in _ipairs(argsPop) do
		vars.requiredStackLevel = arg[1]
		vars.requiredFields = arg[2]
		vars.luaFolder = arg[3]
		argsPop[k] = nil

		break
	end

	while true do
		local func = _debug.getinfo(vars.increment, "flnSu" )

		if func == nil then break end

		local name, value = _debug.getlocal(1, 2, vars.increment)

		if value then
			-- Step 4: skip BS files.
			--         The correct result is the top of the stack.
			--         If the required stack level is out of bounds, this loop will break, because we skipped a level in step 2.
			if vars.foundBSAgain then
				local result = _debug.getinfo(vars.increment, vars.requiredFields)

				if not _string.find(_debug.getinfo(vars.increment,"S")["short_src"], "/lua/" .. vars.luaFolder) then
					if vars.requiredStackLevel == 1 then
						return result
					end

					vars.requiredStackLevel = vars.requiredStackLevel - 1
				end
			-- Step 3: Keep going until stack level is 1 and return if it's not checking BS files.
			--         If BS files are found, skip then.
			elseif vars.foundGetinfo then
				local result = _debug.getinfo(vars.increment, vars.requiredFields) 

				if result and
				   _string.find(_debug.getinfo(vars.increment,"S")["short_src"], "/lua/" .. vars.luaFolder) then

					vars.foundBSAgain = true
				else
					if vars.requiredStackLevel == 1 then
						return result
					end

					vars.requiredStackLevel = vars.requiredStackLevel - 1
				end
			-- Step 2: Skip a stack level, so we can check the stack locally using vars.
			elseif vars.skipLevel then
				vars.foundGetinfo = true
			-- Step 1: Find debug.getinfo.
			--         Return if the stack level is 1.
			elseif value.func == debug.getinfo then
				if vars.requiredStackLevel == 1 then
					return _debug.getinfo(vars.increment, vars.requiredFields)
				else
					vars.skipLevel = true
					vars.requiredStackLevel = vars.requiredStackLevel - 1
				end
			end

			--Debug
			--print(value.name)
			--print(value.func == debug.getinfo)
		end

		vars.increment = vars.increment + 1
	end
end

function BS:Stack_SkipBSFunctions(args)
	table.insert(args, self.folder.lua)
	InsertArgs(args)
    return Stack_SkipBSFunctions()
end