--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Generate random name
function BS:Utils_GetRandomName()
    local name = string.ToTable("qwertyuiopsdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM")
    local newName = ""
    local aux, rand
    
    for i = 1, #name do
        rand = math.random(#name)
        aux = name[i]
        name[i] = name[rand]
        name[rand] = aux
    end

    for i = 1, #name do
        newName = newName .. name[i]
    end

    return newName
end

-- Save the creation time of our files 
function BS:Utils_GetFilesCreationTimes()
    local times = {}

    local function GetRecursive(dir)
        local files, dirs = file.Find(dir .. "*", "LUA")
    
        if not dirs then
            return
        end
    
        for _, subDir in ipairs(dirs) do
            GetRecursive(dir .. subDir .. "/")
        end
    
        for k, _file in ipairs(files) do
            times[dir .. _file] =  file.Time(dir .. _file, "LUA")
        end 
    end

    GetRecursive(self.folder.lua .. "/")

    return times
end

-- Convert the path of a file in the addons folder to a game's mounted one.
-- I'll save it and prevent us from scanning twice.
function BS:Utils_ConvertAddonPath(path, forceConvertion)
    local corvertedPath
    
    if forceConvertion or string.sub(path, 1, 7) == "addons/" then
        corvertedPath = ""

        for k, pathPart in ipairs(string.Explode("/", path)) do
            if k > 2 then
                corvertedPath = corvertedPath .. "/" .. pathPart
            end
        end

        corvertedPath = string.sub(corvertedPath, 2, string.len(corvertedPath))
    end

    return corvertedPath or path
end

-- Issue: https://stackoverflow.com/questions/9356169/utf-8-continuation-bytes
-- This function was written by Ceifa. It also replaces utf8.codepoint, which often gives errors.
function BS:Utils_GetFullByte(str, startPos)
    local firstbyte = string.byte(str[startPos])
    local continuations = firstbyte >= 0xF0 and 3 or firstbyte >= 0xE0 and 2 or firstbyte >= 0xC0 and 1

    if not continuations then
        return firstbyte
    end

    local endPos = startPos + continuations
    local otherbytes = { string.byte(str, startPos + 1, endPos) }

    local codePoint = 0
    for _, byte in ipairs(otherbytes) do
        -- codePoint = codePoint << 6 | byte & 0x3F
        codePoint = bit.band(bit.bor(bit.lshift(codePoint, 6), byte), 0x3F)
        -- firstbyte = firstbyte << 1
        firstbyte = bit.lshift(firstbyte, 1)
    end

    -- codePoint = codePoint | ((firstbyte & 0x7F) << continuations * 5)
    codePoint = bit.bor(codePoint, bit.lshift(bit.band(firstbyte, 0x7F), continuations * 5))
    return codePoint
end
