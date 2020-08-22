--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

-- Live reload the addon when a file is modified
-- Note: UNSAFE! BS will be rebuilt exposed to the common addons environment
function BS:LiveReloading_Set()
    if self.LIVERELOADING then
        local name = self:Utils_GetRandomName()

        timer.Create(name, 0.1, 0, function()
            for k,v in pairs(self:Utils_GetFilesCreationTimes()) do
                if v ~= self.FILETIMES[k] then
                    print(self.ALERT .. " Reloading addon...")

                    for k,v in pairs(self.control) do
                        local f1, f2, f3 = unpack(string.Explode(".", k))
            
                        self:Functions_SetDetour_Aux(self:Functions_GetCurrent(f1, f2, f3, self.__G_SAFE), f1, f2, f3)
                    end

                    include("bs/init.lua")

                    timer.Destroy(name)
                end
            end
        end)
    end
end
