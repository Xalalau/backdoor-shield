--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Find whitelisted detetections
-- whitelist = { k = term } (ordered list)
function BS:Scan_Whitelist(str, whitelist)
    local found = false

    if str and #whitelist > 0 then
        for k, term in ipairs(whitelist)do
            if string.find(str, term, nil, true) then
                found = true

                break
            end
        end
    end

    return found
end

-- Process a string according to a blacklist
-- blacklist = { k = term } (ordered list)
-- returns: { [term] = { lineNumber = int lineNumber, count = int count }, ... }
function BS:Scan_Blacklist(BS, str, blacklist)
    local foundTerms = {}

    -- Scan each line
    for lineNumber, line in ipairs(string.Explode("\n", str, false)) do
        local strRemovedSpaces = string.gsub(line, " ", "")
        local foundInLine = {}

        for k, term in ipairs(blacklist) do
            if string.find(strRemovedSpaces, term, nil, true) then
                local count = select(2, string.gsub(strRemovedSpaces, string.PatternSafe(term), ""))

                if term == "=_G" or term == "=_R" then -- Since I'm not using patterns, I do some extra checks on _G and _R to avoid false positives.
                    local strSingleWhiteSpaces = string.gsub(str, "%s+", " ")
                    local strStart, strEnd = string.find(strSingleWhiteSpaces, term, nil, true)

                    if not strStart then
                        strStart, strEnd = string.find(strSingleWhiteSpaces, term == "=_G" and "= _G" or "= _R", nil, true)
                    end

                    local nextChar = strSingleWhiteSpaces[strEnd + 1] or "-"

                    if nextChar == "\t" or nextChar == " " or nextChar == "\n" or nextChar == "\r\n" then
                        foundTerms[term] = foundTerms[term] or {}
                        foundInLine[term] = true
                        table.insert(foundTerms[term], { lineNumber = lineNumber, count = count })
                    end
                else
                    foundTerms[term] = foundTerms[term] or {}
                    foundInLine[term] = true
                    table.insert(foundTerms[term], { lineNumber = lineNumber, count = count })
                end
            end
        end
    end

    return foundTerms
end

-- Search for spoofed code
function BS:Scan_Characters(BS, str, ext)
    local foundChars = {}

    -- Scan each line
    if str and ext == "lua" then
        for lineNumber, line in ipairs(string.Explode("\n", str, false)) do
            local foundInLine = {}
            for i = 1, #line, 1 do
                local byte = BS.Utils_GetFullByte(BS, line, i)
                if BS.UTF8InvisibleChars[byte] then
                    foundInLine[byte] = (foundInLine[byte] or 0) + 1
                end
            end

            for byte, count in pairs(foundInLine) do
                foundChars[byte] = foundChars[byte] or {}
                table.insert(foundChars[byte], {
                    lineNumber = lineNumber,
                    count = count
                })
            end
        end
    end

    return foundChars
end
