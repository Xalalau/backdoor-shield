-- That will fix color code printing for linux SRCDS
-- SRCDS on linux doesn't support 256 color mode
-- So we have to detour MSGC and replace it for the available ones.
_MsgC = _MsgC or MsgC
_ErrorNoHalt = _ErrorNoHalt or ErrorNoHalt

local available_colors = {
    "\27[38;5;0m", "\27[38;5;18m", "\27[38;5;22m",
    "\27[38;5;12m", "\27[38;5;52m", "\27[38;5;53m",
    "\27[38;5;3m", "\27[38;5;240m", "\27[38;5;8m",
    "\27[38;5;4m", "\27[38;5;10m", "\27[38;5;14m",
    "\27[38;5;9m", "\27[38;5;13m", "\27[38;5;11m",
    "\27[38;5;15m", "\27[38;5;8m"
}

local tColorMap = {
    Color(0, 0, 0), Color(0, 0, 127), Color(0, 127, 0),
    Color(0, 127, 127), Color(127, 0, 0), Color(127, 0, 127),
    Color(127, 127, 0), Color(200, 200, 200), Color(127, 127, 127),
    Color(0, 0, 255), Color(0, 255, 0), Color(0, 255, 255),
    Color(255, 0, 0), Color(255, 0, 255), Color(255, 255, 0),
    Color(255, 255, 255), Color(128, 128, 128)
}

local tColorMap_len = #tColorMap
local color_clear_sequence = "\27[0m"

local function sequence_from_color(col)
    local dist, windist, ri

    for i = 1, tColorMap_len do
        dist = (col.r - tColorMap[i].r)^2 + (col.g - tColorMap[i].g)^2 + (col.b - tColorMap[i].b)^2

        if i == 1 or dist < windist then
            windist = dist
            ri = i
        end
    end

    return available_colors[ri]
end

function print_colored(color, text)
    local color_sequence = color_clear_sequence

    if istable(color) then
        color_sequence = sequence_from_color(color)
    elseif isstring(color) then
        color_sequence = color
    end

    if !isstring(color_sequence) then
        color_sequence = color_clear_sequence
    end

    Msg(color_sequence..text..color_clear_sequence)
end

function MsgC(...)
    local this_sequence = color_clear_sequence

    for k, v in ipairs({...}) do
        if istable(v) then
            this_sequence = sequence_from_color(v)
        else
            print_colored(this_sequence, tostring(v))
        end
    end
end

function ErrorNoHalt(msg)
    Msg('\27[41;15m')
    _ErrorNoHalt(msg)
    Msg(color_clear_sequence)
end

local tFiles = {}
local tFileColors = {}
local tTypeColors = {
    ["default"] = color_white,
    ["warn"] = color_orange,
    ["error"] = color_red,
    ["success"] = Color(0, 255, 0),
    ["info"] = color_yellow
}

local incr = SERVER and 5 or 10

local function LogPrint( err, module, file, line, realmcolor, typecolor, ...)
    if !module or !file then
        if CLIENT then
            chat.AddText("[BS] " .. err, SPrint(...))
        else
            MsgC("\n[BS] " .. err, SPrint(...) .."\n")
        end

        return
    end

    if CLIENT then
        chat.AddText(realmcolor,"[BS]".."["..module.."] ", typecolor, err, SPrint(...) .. "~> @" .. file ..":".. line .."\n")
    else
        MsgC(realmcolor,"[BS]".."["..module.."] ", typecolor, err, SPrint(...), " ~> @" .. file ..":".. line .."\n")
    end
end

function BS:Log(err, type, ...)
    local info = debug.getinfo(2)
    if !type or !tTypeColors[type] then type = "default" end
    if !(err ~= nil) then return end

    if not info then
        LogPrint(err, "DEBUG", nil, nil, nil, nil, ...)
        return
    end

    local iModuleStart
    local sModule = info.short_src
    sModule = string.Explode('/', sModule)
    for _, c in pairs(sModule) do
        if c == "gmod-backdoor-shield" then
            iModuleStart = _
        end
    end
    sModule = string.upper(sModule[iModuleStart+1])

    local sFile = info.short_src
    if tFiles[sFile] then
        sFile = tFiles[sFile]
    else
        local oldsFile = sFile
        sFile = string.Explode('/', sFile)
        sFile = sFile[#sFile]
        tFiles[oldsFile] = sFile
    end
    
    if istable(err) then
        err = table.ToString(err,"[TABLE] [" .. SPrint(...) .. "]\n Output:", true)
    end

    if tFileColors[sFile] then
        tFileColors[sFile] = HSVToColor(incr*60%360, SERVER and (game.IsDedicated() and 1 or 0.5) or 1, 0.8)
        incr = incr + 1
    else
        tFileColors[sFile] = HSVToColor(180%360, 1, 0.8)
    end

    local iLine = info.lastlinedefined

    LogPrint( err, sModule, sFile, iLine, tFileColors[sFile], tTypeColors[type], SPrint(...))
end
