--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

-- Generate random name
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

-- Save the creation time of our files 
function BS:Utils_GetFilesCreationTimes()
    local times = {}

    local function GetRecursive(dir)
        local files, dirs = file.Find(dir .. "*", "LUA")
    
        if not dirs then
            return
        end
    
        for _, subDir in ipairs(dirs) do
            GetRecursive(dir .. subDir .. "/")
        end
    
        for k, _file in ipairs(files) do
            times[dir .. _file] =  file.Time(dir .. _file, "LUA")
        end 
    end

    GetRecursive(self.folder.lua .. "/")

    return times
end

-- Convert the path of a file in the addons folder to a game's mounted one.
-- I'll save it and prevent us from scanning twice.
function BS:Utils_ConvertAddonPath(path, forceConvertion)
    local corvertedPath
    
    if forceConvertion or string.sub(path, 1, 7) == "addons/" then
        corvertedPath = ""

        for k, pathPart in ipairs(string.Explode("/", path)) do
            if k > 2 then
                corvertedPath = corvertedPath .. "/" .. pathPart
            end
        end

        corvertedPath = string.sub(corvertedPath, 2, string.len(corvertedPath))
    end

    return corvertedPath or path
end