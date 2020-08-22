--[[
    ©2020 Xalalau Xubilozo. All Rights Reserved.
    https://tldrlegal.com/license/all-rights-served#summary
    https://xalalau.com/
--]]

function BS:Utils_GetRandomName()
    local name = string.ToTable("qwertyuiopsdfghjklzxcvbnm1234567890QWERTYUIOPASDFGHJKLZXCVBNM")
	local newName = ""
	local aux, rand
    
	for i = 1, #name do
		rand = math.random(#name)
		aux = name[i]
		name[i] = name[rand]
		name[rand] = aux
    end

    for i = 1, #name do
        newName = newName .. name[i]
    end

    return newName
end

function BS:Utils_GetFilesCreationTimes()
    local times = {}

    local function parseDir(dir)
        local files, dirs = file.Find(dir .. "*", "LUA")
    
        if not dirs then
            return
        end
    
        for _, fdir in pairs(dirs) do
            parseDir(dir .. fdir .. "/")
        end
    
        for k,v in pairs(files) do
            times[dir .. v] =  file.Time(dir .. v, "LUA")
        end 
    end

    parseDir(self.FOLDER.LUA)

    return times
end
