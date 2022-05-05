--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Process a string passed by argument
function BS:Live_ScanArgument(str, funcName, detected, warning)
	if not isstring(str) then return end
	if self:Scan_Whitelist(str, self.whitelists.snippets) then return end

	if detected then
        -- Check stack blacklists
        local protectStack = self.live.control[funcName].protectStack

        if protectStack then
            for _,stackBanListName in ipairs(protectStack) do
                self:Scan_Blacklist(self, str, self.live.blacklists.functions[stackBanListName], detected)
            end
        end

        local foundChars = self:Scan_Characters(self, str, "lua")

        for invalidCharName, linesTab in pairs(foundChars) do
            table.insert(detected, invalidCharName)
        end

        local foundTerms = self:Scan_Blacklist(self, str, self.live.blacklists.snippets, detected)

        for k, term in ipairs(foundTerms) do
            table.insert(detected, term)
        end

        local foundTerms = self:Scan_Blacklist(self, str, self.live.blacklists.cvars, detected)

        for k, term in ipairs(foundTerms) do
            table.insert(detected, term)
        end
    end

	if warning then
    end

	return
end