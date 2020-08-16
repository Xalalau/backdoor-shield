local function GenerateRandomName()
    local name = string.ToTable("qwertyuiopásdfghjklç~zxcvbnm,.;´[1234567890-=!@#$%¨&*()_+QWERTYUIOPASDFGHJKLÇZXCVBNM<>")
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