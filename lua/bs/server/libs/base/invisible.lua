--[[
    2020-2022 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

BS.UTF8InvisibleChars = {
    -- Source: https://github.com/microsoft/vscode/blob/bb5215fff67fd9f40e247a353cc0e5e84a28f49f/src/vs/base/common/strings.ts#L1175
    -- Thank you, VSCode!
    -- Check chars online: https://www.soscisurvey.de/tools/view-chars.php
	-- About source code spoofing: https://www.unicode.org/L2/L2022/22007-avoiding-spoof.pdf
    -- Decimal UTF-16BE invisible characters list:

    --  Note: To get these numbers unicode id convert them to hexadecimal and add U+ in front of the result
    --        You can also use utf8.char() to get the string back

    --[9] = true, -- Tab
	--[10] = true, -- New line
	[11] = true,
	[12] = true,
	--[13] = true, -- Carriage Return
	--[32] = true, -- Space
	[127] = true,
	[160] = true,
	[173] = true,
	[847] = true,
	[1564] = true,
	[4447] = true,
	[4448] = true,
	[6068] = true,
	[6069] = true,
	[6155] = true,
	[6156] = true,
	[6157] = true,
	[6158] = true,
	[7355] = true,
	[7356] = true,
	[8192] = true,
	[8193] = true,
	[8194] = true,
	[8195] = true,
	[8196] = true,
	[8197] = true,
	[8198] = true,
	[8199] = true,
	[8200] = true,
	[8201] = true,
	[8202] = true,
	[8203] = true,
	[8204] = true,
	[8205] = true,
	[8206] = true,
	[8207] = true,
	[8234] = true,
	[8235] = true,
	[8236] = true,
	[8237] = true,
	[8238] = true,
	[8239] = true,
	[8287] = true,
	[8288] = true,
	[8289] = true,
	[8290] = true,
	[8291] = true,
	[8292] = true,
	[8293] = true,
	[8294] = true,
	[8295] = true,
	[8296] = true,
	[8297] = true,
	[8298] = true,
	[8299] = true,
	[8300] = true,
	[8301] = true,
	[8302] = true,
	[8303] = true,
	[10240] = true,
	[12288] = true,
	[12644] = true,
	[65024] = true,
	[65025] = true,
	[65026] = true,
	[65027] = true,
	[65028] = true,
	[65029] = true,
	[65030] = true,
	[65031] = true,
	[65032] = true,
	[65033] = true,
	[65034] = true,
	[65035] = true,
	[65036] = true,
	[65037] = true,
	[65038] = true,
	[65039] = true,
	[65279] = true,
	[65440] = true,
	[65520] = true,
	[65521] = true,
	[65522] = true,
	[65523] = true,
	[65524] = true,
	[65525] = true,
	[65526] = true,
	[65527] = true,
	[65528] = true,
	[65532] = true,
	[78844] = true,
	[119155] = true,
	[119156] = true,
	[119157] = true,
	[119158] = true,
	[119159] = true,
	[119160] = true,
	[119161] = true,
	[119162] = true,
	[917504] = true,
	[917505] = true,
	[917506] = true,
	[917507] = true,
	[917508] = true,
	[917509] = true,
	[917510] = true,
	[917511] = true,
	[917512] = true,
	[917513] = true,
	[917514] = true,
	[917515] = true,
	[917516] = true,
	[917517] = true,
	[917518] = true,
	[917519] = true,
	[917520] = true,
	[917521] = true,
	[917522] = true,
	[917523] = true,
	[917524] = true,
	[917525] = true,
	[917526] = true,
	[917527] = true,
	[917528] = true,
	[917529] = true,
	[917530] = true,
	[917531] = true,
	[917532] = true,
	[917533] = true,
	[917534] = true,
	[917535] = true,
	[917536] = true,
	[917537] = true,
	[917538] = true,
	[917539] = true,
	[917540] = true,
	[917541] = true,
	[917542] = true,
	[917543] = true,
	[917544] = true,
	[917545] = true,
	[917546] = true,
	[917547] = true,
	[917548] = true,
	[917549] = true,
	[917550] = true,
	[917551] = true,
	[917552] = true,
	[917553] = true,
	[917554] = true,
	[917555] = true,
	[917556] = true,
	[917557] = true,
	[917558] = true,
	[917559] = true,
	[917560] = true,
	[917561] = true,
	[917562] = true,
	[917563] = true,
	[917564] = true,
	[917565] = true,
	[917566] = true,
	[917567] = true,
	[917568] = true,
	[917569] = true,
	[917570] = true,
	[917571] = true,
	[917572] = true,
	[917573] = true,
	[917574] = true,
	[917575] = true,
	[917576] = true,
	[917577] = true,
	[917578] = true,
	[917579] = true,
	[917580] = true,
	[917581] = true,
	[917582] = true,
	[917583] = true,
	[917584] = true,
	[917585] = true,
	[917586] = true,
	[917587] = true,
	[917588] = true,
	[917589] = true,
	[917590] = true,
	[917591] = true,
	[917592] = true,
	[917593] = true,
	[917594] = true,
	[917595] = true,
	[917596] = true,
	[917597] = true,
	[917598] = true,
	[917599] = true,
	[917600] = true,
	[917601] = true,
	[917602] = true,
	[917603] = true,
	[917604] = true,
	[917605] = true,
	[917606] = true,
	[917607] = true,
	[917608] = true,
	[917609] = true,
	[917610] = true,
	[917611] = true,
	[917612] = true,
	[917613] = true,
	[917614] = true,
	[917615] = true,
	[917616] = true,
	[917617] = true,
	[917618] = true,
	[917619] = true,
	[917620] = true,
	[917621] = true,
	[917622] = true,
	[917623] = true,
	[917624] = true,
	[917625] = true,
	[917626] = true,
	[917627] = true,
	[917628] = true,
	[917629] = true,
	[917630] = true,
	[917631] = true,
	[917760] = true,
	[917761] = true,
	[917762] = true,
	[917763] = true,
	[917764] = true,
	[917765] = true,
	[917766] = true,
	[917767] = true,
	[917768] = true,
	[917769] = true,
	[917770] = true,
	[917771] = true,
	[917772] = true,
	[917773] = true,
	[917774] = true,
	[917775] = true,
	[917776] = true,
	[917777] = true,
	[917778] = true,
	[917779] = true,
	[917780] = true,
	[917781] = true,
	[917782] = true,
	[917783] = true,
	[917784] = true,
	[917785] = true,
	[917786] = true,
	[917787] = true,
	[917788] = true,
	[917789] = true,
	[917790] = true,
	[917791] = true,
	[917792] = true,
	[917793] = true,
	[917794] = true,
	[917795] = true,
	[917796] = true,
	[917797] = true,
	[917798] = true,
	[917799] = true,
	[917800] = true,
	[917801] = true,
	[917802] = true,
	[917803] = true,
	[917804] = true,
	[917805] = true,
	[917806] = true,
	[917807] = true,
	[917808] = true,
	[917809] = true,
	[917810] = true,
	[917811] = true,
	[917812] = true,
	[917813] = true,
	[917814] = true,
	[917815] = true,
	[917816] = true,
	[917817] = true,
	[917818] = true,
	[917819] = true,
	[917820] = true,
	[917821] = true,
	[917822] = true,
	[917823] = true,
	[917824] = true,
	[917825] = true,
	[917826] = true,
	[917827] = true,
	[917828] = true,
	[917829] = true,
	[917830] = true,
	[917831] = true,
	[917832] = true,
	[917833] = true,
	[917834] = true,
	[917835] = true,
	[917836] = true,
	[917837] = true,
	[917838] = true,
	[917839] = true,
	[917840] = true,
	[917841] = true,
	[917842] = true,
	[917843] = true,
	[917844] = true,
	[917845] = true,
	[917846] = true,
	[917847] = true,
	[917848] = true,
	[917849] = true,
	[917850] = true,
	[917851] = true,
	[917852] = true,
	[917853] = true,
	[917854] = true,
	[917855] = true,
	[917856] = true,
	[917857] = true,
	[917858] = true,
	[917859] = true,
	[917860] = true,
	[917861] = true,
	[917862] = true,
	[917863] = true,
	[917864] = true,
	[917865] = true,
	[917866] = true,
	[917867] = true,
	[917868] = true,
	[917869] = true,
	[917870] = true,
	[917871] = true,
	[917872] = true,
	[917873] = true,
	[917874] = true,
	[917875] = true,
	[917876] = true,
	[917877] = true,
	[917878] = true,
	[917879] = true,
	[917880] = true,
	[917881] = true,
	[917882] = true,
	[917883] = true,
	[917884] = true,
	[917885] = true,
	[917886] = true,
	[917887] = true,
	[917888] = true,
	[917889] = true,
	[917890] = true,
	[917891] = true,
	[917892] = true,
	[917893] = true,
	[917894] = true,
	[917895] = true,
	[917896] = true,
	[917897] = true,
	[917898] = true,
	[917899] = true,
	[917900] = true,
	[917901] = true,
	[917902] = true,
	[917903] = true,
	[917904] = true,
	[917905] = true,
	[917906] = true,
	[917907] = true,
	[917908] = true,
	[917909] = true,
	[917910] = true,
	[917911] = true,
	[917912] = true,
	[917913] = true,
	[917914] = true,
	[917915] = true,
	[917916] = true,
	[917917] = true,
	[917918] = true,
	[917919] = true,
	[917920] = true,
	[917921] = true,
	[917922] = true,
	[917923] = true,
	[917924] = true,
	[917925] = true,
	[917926] = true,
	[917927] = true,
	[917928] = true,
	[917929] = true,
	[917930] = true,
	[917931] = true,
	[917932] = true,
	[917933] = true,
	[917934] = true,
	[917935] = true,
	[917936] = true,
	[917937] = true,
	[917938] = true,
	[917939] = true,
	[917940] = true,
	[917941] = true,
	[917942] = true,
	[917943] = true,
	[917944] = true,
	[917945] = true,
	[917946] = true,
	[917947] = true,
	[917948] = true,
	[917949] = true,
	[917950] = true,
	[917951] = true,
	[917952] = true,
	[917953] = true,
	[917954] = true,
	[917955] = true,
	[917956] = true,
	[917957] = true,
	[917958] = true,
	[917959] = true,
	[917960] = true,
	[917961] = true,
	[917962] = true,
	[917963] = true,
	[917964] = true,
	[917965] = true,
	[917966] = true,
	[917967] = true,
	[917968] = true,
	[917969] = true,
	[917970] = true,
	[917971] = true,
	[917972] = true,
	[917973] = true,
	[917974] = true,
	[917975] = true,
	[917976] = true,
	[917977] = true,
	[917978] = true,
	[917979] = true,
	[917980] = true,
	[917981] = true,
	[917982] = true,
	[917983] = true,
	[917984] = true,
	[917985] = true,
	[917986] = true,
	[917987] = true,
	[917988] = true,
	[917989] = true,
	[917990] = true,
	[917991] = true,
	[917992] = true,
	[917993] = true,
	[917994] = true,
	[917995] = true,
	[917996] = true,
	[917997] = true,
	[917998] = true,
	[917999] = true
}