-- by Hussein Ali
function hsoIsEventHandlerAdded(sEventName, pElementAttachedTo, func)
    if type(sEventName) == 'string' and isElement(pElementAttachedTo) and type(func) == 'function' then
        local aAttachedFunctions = getEventHandlers(sEventName, pElementAttachedTo)
        if type(aAttachedFunctions) == 'table' and #aAttachedFunctions > 0 then
            for i, v in ipairs(aAttachedFunctions) do
                if v == func then
                    return true
                end
            end
        end
    end
    return false
end

local hsoShowingTime = 1000 * 3
local hsoIdleTime = 1000 * 25
local hsoHidingTime = 1000 * 3

local hsoWindow = {}
local hsoAnimationTime = 500
local hsoGovInfo = nil
local hsoVoiceSettings = nil
local hsoPanelData = {}

local hsoScreenW, hsoScreenH = guiGetScreenSize()
local hsoGovWidth, hsoGovHeight = (900 / 1920) * hsoScreenW, (195 / 1080) * hsoScreenH
local hsoMainFont = dxCreateFont("hso.ttf", math.floor(hsoScreenH / 60)) or "default-bold"

function hsoOnMemoFocus() exports.dgs:dgsSetInputEnabled(true) end
function hsoOnMemoLoseFocus() exports.dgs:dgsSetInputEnabled(false) end

function hsoUpdateImagePreview()
    if not (hsoWindow.main and isElement(hsoWindow.main)) then return end

    if isElement(hsoWindow.imagePreview) then
        destroyElement(hsoWindow.imagePreview)
        hsoWindow.imagePreview = nil
    end

    local selectedIndex = exports.dgs:dgsComboBoxGetSelectedItem(hsoWindow.imageSelector)
    if not selectedIndex or selectedIndex <= 0 then
        hsoWindow.imagePreview = exports.dgs:dgsCreateImage(0.65, 0.18, 0.27, 0.11, nil, true, hsoWindow.mainBG)
        exports.dgs:dgsSetProperty(hsoWindow.imagePreview, "color", tocolor(0, 0, 0, 150))
        return
    end
    
    local filename = hsoPanelData.images[selectedIndex].file
    if filename then
        local imagePath = "img/" .. filename
        hsoWindow.imagePreview = exports.dgs:dgsCreateImage(0.65, 0.18, 0.27, 0.11, imagePath, true, hsoWindow.mainBG)
    end
end

function hsoHandleDgsWindowClose()
    if not (hsoWindow.main and isElement(hsoWindow.main)) then return end
    
    if isElement(hsoWindow.currentPreviewTexture) then
        destroyElement(hsoWindow.currentPreviewTexture)
    end

    exports.dgs:dgsSetInputEnabled(false)
    hsoWindow = {}
    hsoPanelData = {}
    showCursor(false)
end

function hsoCreateGovPanel(headerName, addSongOption, images, songs)
    if not images or #images == 0 then
        outputChatBox("No images found in config.xml", 255, 0, 0)
        return
    end

    hsoPanelData.images = images
    hsoPanelData.songs = songs

    local panelWidth, panelHeight = (874 / 1920) * hsoScreenW, (593 / 1080) * hsoScreenH
    hsoWindow.main = exports.dgs:dgsCreateWindow((hsoScreenW - panelWidth) / 2, (hsoScreenH - panelHeight) / 2, panelWidth, panelHeight, "عراق لاند : نظام الأعلانات", false)
    exports.dgs:dgsSetProperty(hsoWindow.main, "color", tocolor(29, 29, 44, 255))
    exports.dgs:dgsSetProperty(hsoWindow.main, "font", hsoMainFont)
    exports.dgs:dgsAlphaTo(hsoWindow.main, 1, "OutQuad", hsoAnimationTime)
    addEventHandler("onDgsWindowClose", hsoWindow.main, hsoHandleDgsWindowClose, false)

    hsoWindow.mainBG = exports.dgs:dgsCreateImage(0.02, 0.04, 0.95, 0.87, nil, true, hsoWindow.main)
    exports.dgs:dgsSetProperty(hsoWindow.mainBG, "color", tocolor(39, 41, 61, 255))
    
    hsoWindow.imagePreview = exports.dgs:dgsCreateImage(0.65, 0.18, 0.27, 0.11, nil, true, hsoWindow.mainBG)
    exports.dgs:dgsSetProperty(hsoWindow.imagePreview, "color", tocolor(0, 0, 0, 150))

    hsoWindow.header = exports.dgs:dgsCreateLabel(0.01, 0.07, 0.98, 0.10, headerName, true, hsoWindow.mainBG)
    exports.dgs:dgsLabelSetHorizontalAlign(hsoWindow.header, "center")
    exports.dgs:dgsLabelSetVerticalAlign(hsoWindow.header, "center")
    exports.dgs:dgsSetProperty(hsoWindow.header, "font", hsoMainFont)

    hsoWindow.memo = exports.dgs:dgsCreateMemo(0.08, 0.18, 0.55, 0.40, "", true, hsoWindow.mainBG)
    exports.dgs:dgsMemoSetMaxLength(hsoWindow.memo, 600)
    exports.dgs:dgsSetProperty(hsoWindow.memo, "font", hsoMainFont)
    addEventHandler("onDgsFocus", hsoWindow.memo, hsoOnMemoFocus, false)
    addEventHandler("onDgsBlur", hsoWindow.memo, hsoOnMemoLoseFocus, false)
    local imageLabel = exports.dgs:dgsCreateLabel(0.08, 0.57, 0.55, 0.05, ":اختر الصورة", true, hsoWindow.mainBG)
    exports.dgs:dgsSetProperty(imageLabel, "font", hsoMainFont)

    hsoWindow.imageSelector = exports.dgs:dgsCreateComboBox(0.08, 0.63, 0.55, 0.05, "", true, hsoWindow.mainBG)
    exports.dgs:dgsSetProperty(hsoWindow.imageSelector, "font", hsoMainFont)
    for _, imageData in ipairs(images) do
        exports.dgs:dgsComboBoxAddItem(hsoWindow.imageSelector, imageData.name)
    end
    exports.dgs:dgsComboBoxSetSelectedItem(hsoWindow.imageSelector, 1)
    addEventHandler("onDgsComboBoxSelect", hsoWindow.imageSelector, hsoUpdateImagePreview, false)

    if addSongOption then
        local songLabel = exports.dgs:dgsCreateLabel(0.08, 0.68, 0.55, 0.05, ":اختر الأغنية", true, hsoWindow.mainBG)
        exports.dgs:dgsSetProperty(songLabel, "font", hsoMainFont)

        hsoWindow.songSelector = exports.dgs:dgsCreateComboBox(0.08, 0.74, 0.55, 0.05, "", true, hsoWindow.mainBG)
        exports.dgs:dgsSetProperty(hsoWindow.songSelector, "font", hsoMainFont)
        if songs and #songs > 0 then
            for _, songData in ipairs(songs) do
                exports.dgs:dgsComboBoxAddItem(hsoWindow.songSelector, songData.name)
            end
            exports.dgs:dgsComboBoxSetSelectedItem(hsoWindow.songSelector, 1)
        end

        hsoWindow.soundCheckBox = exports.dgs:dgsCreateCheckBox(0.08, 0.82, 0.25, 0.05, "تشغيل الصوت ؟", false, true, hsoWindow.mainBG)
        exports.dgs:dgsSetProperty(hsoWindow.soundCheckBox, "font", hsoMainFont)
    end

    hsoWindow.sendButton = exports.dgs:dgsCreateButton(0.36, 0.85, 0.29, 0.09, "إرسال الإعلان", true, hsoWindow.mainBG)
    exports.dgs:dgsSetProperty(hsoWindow.sendButton, "font", hsoMainFont)
    addEventHandler("onDgsMouseClickUp", hsoWindow.sendButton, hsoSendGov, false)

    hsoUpdateImagePreview()
end

function hsoOpenGovPanel(headerName, addSongOption, images, songs)
    if hsoWindow.main and isElement(hsoWindow.main) then return end
    showCursor(true)
    hsoCreateGovPanel(headerName, addSongOption, images, songs)
end
addEvent("gov-system:openGovPanel", true)
addEventHandler("gov-system:openGovPanel", resourceRoot, hsoOpenGovPanel)

function hsoSendGov(button, state)
    if button ~= "left" then return end

    local govMsg = exports.dgs:dgsGetText(hsoWindow.memo) or ""
    if utf8.len(govMsg) < 10 then
        outputChatBox("الإعلان الذي كتبته قصير جدًا", 255, 0, 0)
        return
    end

    if hsoGovInfo then
        outputChatBox("يرجى الإنتظار حتى ينتهي الإعلان الحالي", 255, 200, 0)
        return
    end

    local selectedImageIndex = exports.dgs:dgsComboBoxGetSelectedItem(hsoWindow.imageSelector)
    if not selectedImageIndex or selectedImageIndex <= 0 then
        outputChatBox("الرجاء اختيار صورة", 255, 0, 0)
        return
    end
    local selectedImage = hsoPanelData.images[selectedImageIndex].file

    local withSong = false
    local selectedSong = ""
    if hsoWindow.soundCheckBox and exports.dgs:dgsCheckBoxGetSelected(hsoWindow.soundCheckBox) then
        withSong = true
        
        local selectedSongIndex = exports.dgs:dgsComboBoxGetSelectedItem(hsoWindow.songSelector)
        if not selectedSongIndex or selectedSongIndex <= 0 then
            outputChatBox("الرجاء اختيار أغنية", 255, 0, 0)
            return
        end
        selectedSong = hsoPanelData.songs[selectedSongIndex].file
    end

    triggerServerEvent("gov-system:sendGov", resourceRoot, govMsg, withSong, selectedImage, selectedSong)
end

function hsoClosePanel()
    if not (hsoWindow.main and isElement(hsoWindow.main)) then return end
    
    if isElement(hsoWindow.imagePreview) then
        destroyElement(hsoWindow.imagePreview)
    end

    exports.dgs:dgsSetInputEnabled(false)
    destroyElement(hsoWindow.main)
    hsoWindow = {}
    hsoPanelData = {}
    showCursor(false)
end
addEvent("gov-system:closePanel", true)
addEventHandler("gov-system:closePanel", resourceRoot, hsoClosePanel)

function hsoShowGov(govMsg, withSong, govTheme)
    hsoGovInfo = {}
    local moveToY = hsoScreenH * 0.7916
    local startX = (hsoScreenW - hsoGovWidth) / 2
    local startY = hsoScreenH

    local dgsImage = exports.dgs:dgsCreateImage(startX, startY, hsoGovWidth, hsoGovHeight, nil, false)
    local texturePath = "img/" .. govTheme.image
    if not fileExists(texturePath) then
        outputChatBox("Image file not found: ".. texturePath)
        return
    end
    local texture = dxCreateTexture(texturePath)
    exports.dgs:dgsSetProperty(dgsImage, "image", texture)
    hsoGovInfo.texture = texture
    
    local topBorder = exports.dgs:dgsCreateImage(0, 0, 1, 0.04, nil, true, dgsImage)
    exports.dgs:dgsSetProperty(topBorder, "color", tocolor(255, 0, 0, 255))

    local label = exports.dgs:dgsCreateLabel(0.22, 0.26, 0.77, 0.73, govMsg, true, dgsImage, tocolor(255, 255, 255, 255))

    exports.dgs:dgsLabelSetHorizontalAlign(label, "right", true)
    exports.dgs:dgsLabelSetVerticalAlign(label, "top")
    exports.dgs:dgsSetProperty(label, "wordBreak", true)
    exports.dgs:dgsSetProperty(label, "font", hsoMainFont)

    hsoGovInfo.mainImage = dgsImage

    exports.dgs:dgsMoveTo(dgsImage, startX, moveToY, false, false, hsoShowingTime, "OutBack")

    setTimer(function()
        if not isElement(dgsImage) then return end
        exports.dgs:dgsMoveTo(dgsImage, startX, hsoScreenH, false, false, hsoHidingTime, "InBack")
        if withSong and hsoVoiceSettings and isElement(hsoVoiceSettings.sound) then
            hsoVoiceSettings.from = govTheme.soundLevel or 0.4
            hsoVoiceSettings.to = 0
            hsoVoiceSettings.start = getTickCount()
            hsoVoiceSettings._end = hsoHidingTime
            if not hsoIsEventHandlerAdded("onClientRender", root, hsoChangeSoundVolumeSlightly) then
                addEventHandler("onClientRender", root, hsoChangeSoundVolumeSlightly)
            end
        end
    end, hsoShowingTime + hsoIdleTime, 1)

    if withSong then
        local songPath = "songs/" .. govTheme.song
        if fileExists(songPath) then
            local sound = playSound(songPath)
            hsoVoiceSettings = {
                from = 0,
                to = govTheme.soundLevel or 0.4,
                start = getTickCount(),
                _end = hsoShowingTime,
                sound = sound
            }
            if not hsoIsEventHandlerAdded("onClientRender", root, hsoChangeSoundVolumeSlightly) then
                addEventHandler("onClientRender", root, hsoChangeSoundVolumeSlightly)
            end
        end
    end

    setTimer(hsoOnGovFinish, (hsoShowingTime + hsoIdleTime + hsoHidingTime) + 200, 1)
end
addEvent("gov-system:showGov", true)
addEventHandler("gov-system:showGov", resourceRoot, hsoShowGov)

function hsoOnGovFinish()
    if hsoGovInfo then
        if isElement(hsoGovInfo.mainImage) then destroyElement(hsoGovInfo.mainImage) end
        if isElement(hsoGovInfo.texture) then destroyElement(hsoGovInfo.texture) end
    end
    hsoGovInfo = nil
end

function hsoChangeSoundVolumeSlightly()
    if not (hsoVoiceSettings and isElement(hsoVoiceSettings.sound)) then
        if hsoIsEventHandlerAdded("onClientRender", root, hsoChangeSoundVolumeSlightly) then
            removeEventHandler("onClientRender", root, hsoChangeSoundVolumeSlightly)
        end
        hsoVoiceSettings = nil
        return
    end

    local progress = (getTickCount() - hsoVoiceSettings.start) / hsoVoiceSettings._end
    if progress > 1 then progress = 1 end
    
    local vol = interpolateBetween(hsoVoiceSettings.from, 0, 0, hsoVoiceSettings.to, 0, 0, progress, "Linear")
    setSoundVolume(hsoVoiceSettings.sound, vol)

    if progress >= 1 then
        if hsoIsEventHandlerAdded("onClientRender", root, hsoChangeSoundVolumeSlightly) then
            removeEventHandler("onClientRender", root, hsoChangeSoundVolumeSlightly)
        end
        if hsoVoiceSettings and hsoVoiceSettings.to == 0 then
            if isElement(hsoVoiceSettings.sound) then
                destroyElement(hsoVoiceSettings.sound)
            end
            hsoVoiceSettings = nil
        end
    end
end

addEventHandler("onClientResourceStop", resourceRoot, function()
    if isElement(hsoMainFont) then
        destroyElement(hsoMainFont)
    end
end)