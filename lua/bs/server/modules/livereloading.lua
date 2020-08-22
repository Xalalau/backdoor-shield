--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

-- Live reload the addon when a file is modified
-- Note: UNSAFE! BS will be rebuilt exposed to the common addons environment
function BS:LiveReloading_Set()
    local name = "BS_LiveReloading"

    if self.LIVERELOADING and not timer.Exists(name) then
        self.__G.BS_RELOADING = false

        timer.Create(name, 0.2, 0, function()
            for k,v in pairs(self:Utils_GetFilesCreationTimes()) do
                if v ~= self.FILETIMES[k] then
                    print(self.ALERT .. " Reloading...")

                    for k,v in pairs(self.control) do
                        local f1, f2, f3 = unpack(string.Explode(".", k))
            
                        self:Functions_SetDetour_Aux(self:Functions_GetCurrent(f1, f2, f3, self.__G_SAFE), f1, f2, f3)
                    end

                    self.__G.BS_RELOADING = true

                    timer.Simple(0.01, function()
                        include("bs/init.lua")
                    end)

                    timer.Destroy(name)
                end
            end
        end)
    end
end
