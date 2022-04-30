--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Process a string
function BS:Arguments_Scan(str, funcName, detected, warning)
	if not isstring(str) then return end
	if self:Scan_CheckWhitelist(str, self.whitelists.snippets) then return end

    local IsSuspect = "true"

	if detected then
        -- Check stack blacklists
        local protectStack = self.live.control[funcName].protectStack

        if protectStack then
            for _,stackBanListName in ipairs(protectStack) do
                self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.functions[stackBanListName], detected)
            end
        end

        self:Scan_CheckCharset(str, "lua", detected, true)
        self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.snippets, detected)
        self:Scan_ProcessList(self, str, IsSuspect, self.live.blacklists.cvars, detected)
    end

	if warning then
    end

	return
end
