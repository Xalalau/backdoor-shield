--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Process a string
function BS:Arguments_Scan(trace, str, blocked, warning)
	if not isstring(str) then return end
	if self:Scan_CheckWhitelist(str, self.whitelists.snippets) then return end

    local IsSuspect = "true"

	if blocked then
        self:Scan_ProcessList(self, trace, str, IsSuspect, self.arguments.blacklists.snippets, blocked)
        self:Scan_ProcessList(self, trace, str, IsSuspect, self.arguments.blacklists.functions, blocked)
        self:Scan_ProcessList(self, trace, str, IsSuspect, self.arguments.blacklists.cvars, blocked)
        self:Scan_CheckCharset(str, "lua", blocked, true)
	end

	if warning then
        self:Scan_ProcessList(self, trace, str, IsSuspect, self.arguments.suspect.functions, warning)
    end

	return
end
