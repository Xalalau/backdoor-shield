--[[
    2020-2021 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Live reload the addon when a file is modified
-- Note: UNSAFE! BS will be rebuilt itself exposed to the common addons environment and there may come detoured functions
function BS:LiveReloading_Set()
    local name = "BS_LiveReloading"

    if self.devMode and not timer.Exists(name) then
        timer.Create(name, 0.2, 0, function()
            for k,v in pairs(self:Utils_GetFilesCreationTimes()) do
                if v ~= self.filenames[k] then
                    MsgC(self.colors.reload, self.alert .. " Reloading...\n")

                    self:Detours_Remove()

                    self.reloaded = true

                    self.__G.BS_reloaded = true
                    timer.Simple(0.01, function()
                        include("bs/init.lua")

                        self.__G.BS_reloaded = nil
                    end)

                    timer.Remove(name)
                end
            end
        end)
    end
end
