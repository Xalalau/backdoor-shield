--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Find whitelisted detetections
function BS:Scan_Whitelist(str, whitelist)
	local found = false

	if str and #whitelist > 0 then
		for _, allowed in ipairs(whitelist)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

-- Process a string according to our white, black and suspect lists
function BS:Scan_Blacklist(str, blacklist)
    local foundTerms = {}
	local lineEnd = string.find(str, "\r\n", nil, true) and "\r\n" or "\n"

	for lineNumber, line in ipairs(string.Explode(lineEnd, str, false)) do
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

-- cache into the local lexical scope
local string_byte = string.byte

-- Try to find Lua files with obfuscations
-- ignorePatterns is used to scan files that already has other detections
function BS:Scan_Characters(str, ext)
	local foundChars = {}

	if str and ext == "lua" then
		local lineEnd = string.find(str, "\r\n", nil, true) and "\r\n" or "\n"

		-- Scan string
		for lineNumber, line in ipairs(string.Explode(lineEnd, str, false)) do
			-- Check entire line
			if utf8.force(line) == "�" then
				-- Decrease the number of false positives
				if string.find(line, "=", nil, true) or
					string.find(line, "local", nil, true) or
					string.find(line, "function", nil, true) or
					string.find(line, "return", nil, true) or
					string.find(line, "then", nil, true) or
					string.find(line, " _G", nil, true) or
					string.find(line, "\t_G", nil, true) then

					foundChars["Invalid UTF-8 char"] = foundChars["Invalid UTF-8 char"] or {}
					table.insert(foundChars["Invalid UTF-8 char"], lineNumber)
				end
			end

			local foundInLine = {}
			for i = 1, #line, 1 do
				local byte = string_byte(line, i)
				if self.UTF8InvisibleChars[byte] and not foundInLine[byte] then
					foundInLine[byte] = true
					foundChars[byte] = foundChars[byte] or {}
					table.insert(foundChars[byte], { lineNumber = lineNumber, count = #line[i] })
				end
			end
		end
	end

	return foundChars
end
