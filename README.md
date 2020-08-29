# Backdoor Shield

Protect your Garry's Mod server against backdoors.

![logo](https://i.imgur.com/DJlASZh.png)

## Install

Clone or download the files inside your **addons folder**.

## Configure

- Edit the addon settings in "**lua/bs/server/sv_init.lua.**";
- Edit the scan definitions in "**lua/bs/server/definitions.lua.**".

## Commands

    # Recursively scan folders and investigate the results:
    |
    |--> bs_scan folder(s)
    |
    |       scan all files in folder(s) or in lua, gamemode and data
    |       folders.
    |
    |--> bs_scan_fast folder(s)

            scan lua, txt, vmt, dat and json files in folder(s) or in
            lua, gamemode and data folders.

    # Run a series of tests when BS.DEVMODE is set to true:
    |
    | --> bs_tests

## !!WARNING!!

>Consider that this addon just gives you an extra layer of security! You'll be able to scan your files and avoid a series of unwanted executions with a basic real-time protection, but don't think that it'll get you out of all troubles!
