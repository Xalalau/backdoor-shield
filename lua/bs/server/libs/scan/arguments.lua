--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Process a string
function BS:Arguments_Scan(str, funcName, blocked, warning)
	if not isstring(str) then return end
	if self:Scan_CheckWhitelist(str, self.whitelists.snippets) then return end

    local IsSuspect = "true"

	if blocked then
        -- Check stack blacklists
        local protectStack = self.live.control[funcName].protectStack

        if protectStack then
            for _,stackBanListName in ipairs(protectStack) do
                self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.functions[stackBanListName], blocked)
            end
        end

        self:Scan_CheckCharset(str, "lua", blocked, true)
        self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.snippets, blocked)
        self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.cvars, blocked)
    end

	if warning then
    end

	return
end
