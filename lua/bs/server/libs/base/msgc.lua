--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- That will fix color code printing for linux SRCDS
-- SRCDS on linux doesn't support 256 color mode
-- So we have to detour MSGC and replace it for the available ones.

if not system.IsLinux() then return end

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

local function SequenceFromColor(col)
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
table.insert(BS.locals, SequenceFromColor)

function BS:PrintColored(color, text)
    local color_sequence = color_clear_sequence

    if istable(color) then
        color_sequence = SequenceFromColor(color)
    elseif isstring(color) then
        color_sequence = color
    end

    if not isstring(color_sequence) then
        color_sequence = color_clear_sequence
    end

    Msg(color_sequence..text..color_clear_sequence)
end

function BS:MsgC(...)
    local this_sequence = color_clear_sequence

    for k, arg in ipairs({...}) do
        if istable(arg) then
            this_sequence = sequence_from_color(arg)
        else
            self:PrintColored(this_sequence, tostring(arg))
        end
    end
end
