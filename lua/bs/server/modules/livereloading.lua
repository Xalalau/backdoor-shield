--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Live reload the addon when a file is modified
-- Note: UNSAFE! BS will be rebuilt exposed to the common addons environment
function BS:LiveReloading_Set()
    local name = "BS_LiveReloading"

    if self.devMode and not timer.Exists(name) then
        self.__G.BS_reloaded = false

        timer.Create(name, 0.2, 0, function()
            for k,v in pairs(self:Utils_GetFilesCreationTimes()) do
                if v ~= self.filenames[k] then
                    print(self.alert .. " Reloading...")

                    self:Functions_RemoveDetours()

                    self.__G.BS_reloaded = true
                    self.reloaded = true

                    timer.Simple(0.01, function()
                        include("bs/init.lua")
                    end)

                    timer.Remove(name)
                end
            end
        end)
    end
end
