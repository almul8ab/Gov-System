-- by Hussein Ali
local hsoShowingTime = 1000 * 3
local hsoIdleTime = 1000 * 25
local hsoHidingTime = 1000 * 3
function hsoLoadConfig()
    local images = {}
    local songs = {}
    local xml = getResourceConfig("config.xml")
    if not xml then return false, false end
    local imagesParentNode = xmlFindChild(xml, "images", 0)
    if imagesParentNode then
        local imageNodes = xmlNodeGetChildren(imagesParentNode)
        for _, node in ipairs(imageNodes) do
            if xmlNodeGetName(node) == "image" then
                local name = xmlNodeGetAttribute(node, "name")
                local file = xmlNodeGetAttribute(node, "file")
                if name and file then
                    table.insert(images, { name = name, file = file })
                end
            end
        end
    end
    local songsParentNode = xmlFindChild(xml, "songs", 0)
    if songsParentNode then
        local songNodes = xmlNodeGetChildren(songsParentNode)
        for _, node in ipairs(songNodes) do
            if xmlNodeGetName(node) == "song" then
                local name = xmlNodeGetAttribute(node, "name")
                local file = xmlNodeGetAttribute(node, "file")
                if name and file then
                    table.insert(songs, { name = name, file = file })
                end
            end
        end
    end

    return images, songs
end

local hsoCoolingDown = {}
local hsoIsThereGovInProgress

function hsoOpenGovPanel(player, commandName, ...)
    local playerAccount = getPlayerAccount(player)
    if isGuestAccount(playerAccount) then return end

    if not isObjectInACLGroup("user." .. getAccountName(playerAccount), aclGetGroup("Admin")) then
        outputChatBox("هذا الأمر مخصص للإدارة فقط", player, 255, 0, 0)
        return
    end

    if hsoCoolingDown[player] then
        outputChatBox("يجب عليك الإنتظار قليلًا حتى تتمكن من إستعمال هذا الأمر مرةً أخرى", player, 255, 200, 0)
        return
    end

    hsoCoolingDown[player] = true
    setTimer(function() hsoCoolingDown[player] = nil end, 5000, 1)

    local images, songs = hsoLoadConfig()
    if not images or #images == 0 then
        outputChatBox("لا يمكن العثور على أي صور في config.xml. يرجى مراجعة الملف", player, 255, 0, 0)
        return
    end

    local addSongOption = songs and #songs > 0
    triggerClientEvent(player, "gov-system:openGovPanel", resourceRoot, "إرسال إعلان عــام", addSongOption, images, songs)
end
addCommandHandler("gov", hsoOpenGovPanel, false, false)

function hsoSendGov(message, withSong, selectedImage, selectedSong)
    local client = client
    local clientAccount = getPlayerAccount(client)
    if isGuestAccount(clientAccount) then return end
    if not isObjectInACLGroup("user." .. getAccountName(clientAccount), aclGetGroup("Admin")) then return end

    if hsoIsThereGovInProgress then
        outputChatBox("يرجى الإنتظار حتى ينتهي الإعلان الحالي", client, 255, 200, 0)
        return
    end

    if not fileExists("img/" .. selectedImage) or (withSong and not fileExists("songs/" .. selectedSong)) then
        outputChatBox("الملفات المختارة غير موجودة", client, 255, 0, 0)
        return
    end

    hsoIsThereGovInProgress = true

    local govTheme = {
        image = selectedImage,
        song = selectedSong,
        soundLevel = 0.5
    }

    local loggedInPlayers = hsoGetLoggedInPlayers()
    local totalTimeToFinish = (hsoShowingTime + hsoIdleTime + hsoHidingTime) + 500

    triggerClientEvent(loggedInPlayers, "gov-system:showGov", resourceRoot, message, withSong, govTheme)
    triggerClientEvent(client, "gov-system:closePanel", resourceRoot)

    setTimer(function() hsoIsThereGovInProgress = nil end, totalTimeToFinish, 1)
end
addEvent("gov-system:sendGov", true)
addEventHandler("gov-system:sendGov", resourceRoot, hsoSendGov)

function hsoGetLoggedInPlayers()
    local players = getElementsByType("player")
    local logged_in = {}
    for _, player in ipairs(players) do
        if not isGuestAccount(getPlayerAccount(player)) then
            table.insert(logged_in, player)
        end
    end
    return logged_in
end