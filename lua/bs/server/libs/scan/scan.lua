--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- !! WARNING !! I'm using string.find() with patterns disabled in some functions!
-- I could enable them running string.PatternSafe() but this calls string.gsub()
-- with 13 pattern escape replacements and my scanner is already intensive enouth.

-- Find whitelisted detetections
function BS:Scan_CheckWhitelist(str, whitelist)
	local found = false

	if str and #whitelist > 0 then
		for _,allowed in pairs(whitelist)do
			if string.find(str, allowed, nil, true) then
				found = true

				break
			end
		end
	end

	return found
end

-- Try to find Lua files with obfuscations
-- ignorePatterns is used to scan files that already has other detections
function BS:Scan_CheckCharset(str, ext, list, ignorePatterns)
	if str and ext == "lua" then
		local lines, count = "", 0

		-- Search line by line, so we have the line numbers
		for lineNumber,lineText in ipairs(string.Explode("\n", str, false)) do
			-- Check char by char
			for _,_char in ipairs(string.ToTable(lineText)) do
				-- If we find a suspect character, take a closer look
				if utf8.force(_char) ~= _char then
					-- Let's eliminate as many false positives as possible by searching for common backdoor patterns
					if ignorePatterns or (
					   string.find(lineText, "function") or
					   string.find(lineText, "return") or
					   string.find(lineText, "then") or
					   string.find(lineText, " _G") or
					   string.find(lineText, "	_G")) then

						count = count + 1
						lines = lines .. lineNumber .. "; "
					end
					break
				end
			end
		end

		if count > 0 then
			local plural = count > 1 and "s" or ""
			table.insert(list, "Uncommon Charset, line" .. plural .. ": " .. lines)
		end
	end
end

-- Process a string according to our white, black and suspect lists
function BS:Scan_ProcessList(BS, str, IsSuspect, list, list2)
	for k,v in pairs(list) do
		if string.find(string.gsub(str, " ", ""), v, nil, true) then
			if v == "=_G" or v == "=_R" then -- Since I'm not using patterns, I do some extra checks on _G and _R to avoid false positives.
				local check = string.gsub(str, "%s+", " ")
				local strStart, strEnd = string.find(check, v, nil, true)
				if not strStart then
					strStart, strEnd = string.find(check, v == "=_G" and "= _G" or "= _R", nil, true)
				end

				local nextChar = check[strEnd + 1] or "-"

				if nextChar == " " or nextChar == "\n" or nextChar == "\r\n" then
					if not IsSuspect then
						return true
					else
						table.insert(list2, v)
					end
				end
			else
				if not IsSuspect then
					return true
				else
					table.insert(list2, v)
				end
			end
		end
	end
end
