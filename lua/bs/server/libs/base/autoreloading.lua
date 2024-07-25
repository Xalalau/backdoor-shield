--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Auto reload the addon when a file is modified
-- Note: UNSAFE! BS will be rebuilt itself exposed to the common addons environment and there may come detoured functions
function BS:AutoReloading_Set()
    local name = "BS_AutoReloading"

    if self.devMode and not timer.Exists(name) then
        timer.Create(name, 0.2, 0, function()
            for fileName, creationTime in pairs(self:Utils_GetFilesCreationTimes()) do
                if creationTime ~= self.filenames[fileName] then
                    MsgC(self.colors.reload, self.alert .. " Reloading...\n")

                    self:Detour_RemoveAll()

                    self.reloaded = true

                    self.__G.BS_reloaded = true
                    timer.Simple(0.01, function()
                        include(self.folder.lua .. "/init.lua")

                        self.__G.BS_reloaded = nil
                    end)

                    timer.Remove(name)
                end
            end
        end)
    end
end
