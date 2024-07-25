--[[
    Copyright (C) 2020 Xalalau Xubilozo. MIT License
    https://xalalau.com/
--]]

local notification
local text_warning

local function CreateNotification()
    local iconSize = 16
    local border = 10
    local line = 25
    local dLabelHeight = 16

    local panelInfo = {
        width = 170,
        height,
        x = 30,
        y = 30
    }

    local iconWarningInfo = {
        width = iconSize,
        height = iconSize,
        x = border,
        y = border
    }

    local headerInfo = {
        width = panelInfo.width,
        height = dLabelHeight,
        x = border * 2 + iconSize,
        y = border
    }

    local contentInfo = {
        width = panelInfo.width,
        height = dLabelHeight,
        x = border * 2 + iconSize,
        y = headerInfo.y + line
    }

    panelInfo.height = contentInfo.y + contentInfo.height + border

    notification = vgui.Create("DPanel")
    notification:SetPos(panelInfo.x, panelInfo.y)
    notification:SetSize(panelInfo.width, panelInfo.height)
    notification:SetBackgroundColor(Color(31, 31, 31))
    notification:Show()

    local icon_warning = vgui.Create("DImage", notification)
    icon_warning:SetPos(iconWarningInfo.x, iconWarningInfo.y)
    icon_warning:SetSize(iconWarningInfo.width, iconWarningInfo.height)
    icon_warning:SetImage("icon16/shield.png")

    local header = vgui.Create("DLabel", notification)
    header:SetPos(headerInfo.x, headerInfo.y)
    header:SetSize(headerInfo.width, headerInfo.height)
    header:SetText("Backdoor Shield")
    header:SetColor(Color(255, 255, 255))

    text_warning = vgui.Create("DLabel", notification)
    text_warning:SetPos(contentInfo.x, contentInfo.y)
    text_warning:SetSize(contentInfo.width, contentInfo.height)
    text_warning:SetColor(Color(165, 165, 165))
end

net.Receive("BS_AddNotification", function()
    if not notification then
        CreateNotification()
    end

    text_warning:SetText(net.ReadString() .. " detections / " .. net.ReadString() .. " warnings")

    timer.Create("BS_HideNotification", 12, 1, function()
        notification:Hide()
    end)
end)
