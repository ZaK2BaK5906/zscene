-- Variables globales
local placementMode = false
local currentPed = nil
local currentPedId = nil
local freecam = nil
local freecamCoords = nil
local pedRotation = 0.0
local spawnedPeds = {}

-- Fonction pour obtenir les coordonnées au sol avec retry
local function GetGroundZ(x, y, z)
    local retries = 0
    local maxRetries = 10
    local groundZ = z
    local found = false

    while retries < maxRetries and not found do
        found, groundZ = GetGroundZFor_3dCoord(x, y, z + 100.0, false)

        if found then
            return groundZ
        end

        retries = retries + 1
        Wait(100)
    end

    -- Si pas trouvé, retourner la coordonnée Z originale
    return z
end

-- Fonction pour créer la freecam
local function CreateFreecam(coords)
    freecam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(freecam, coords.x, coords.y, coords.z + 0.5)  -- Caméra à hauteur du ped
    SetCamRot(freecam, -10.0, 0.0, GetEntityHeading(PlayerPedId()))  -- Angle plus doux
    SetCamActive(freecam, true)
    RenderScriptCams(true, true, 500, true, true)

    freecamCoords = vector3(coords.x, coords.y, coords.z + 0.5)
end

-- Fonction pour détruire la freecam
local function DestroyFreecam()
    if freecam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(freecam, false)
        freecam = nil
        freecamCoords = nil
    end

    -- S'assurer que le joueur est visible et contrôlable
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    SetEntityAlpha(playerPed, 255, false)
    FreezeEntityPosition(playerPed, false)
end

-- Fonction pour obtenir les coordonnées du raycast
local function GetRaycastCoords()
    if not freecam then return nil end

    local camRot = GetCamRot(freecam, 2)
    local camCoord = GetCamCoord(freecam)

    local direction = RotationToDirection(camRot)
    local destination = vector3(
        camCoord.x + direction.x * 100.0,
        camCoord.y + direction.y * 100.0,
        camCoord.z + direction.z * 100.0
    )

    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        destination.x, destination.y, destination.z,
        -1,
        PlayerPedId(),
        0
    )

    local _, hit, coords, _, _ = GetShapeTestResult(rayHandle)

    if hit then
        -- Vérifier que les coordonnées ne sont pas trop basses (sous la map)
        if coords.z < -100.0 then
            return nil
        end

        -- Obtenir la vraie coordonnée Z du sol
        local groundZ = GetGroundZ(coords.x, coords.y, coords.z)
        return vector3(coords.x, coords.y, groundZ)
    end

    return nil
end

-- Fonction pour convertir rotation en direction
function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )

    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )

    return direction
end

-- Fonction pour spawner un ped
local function SpawnCinematicPed(pedId)
    local pedData = nil

    for _, ped in ipairs(Config.CinematicPeds) do
        if ped.id == pedId then
            pedData = ped
            break
        end
    end

    if not pedData then
        print("^1[ERROR] Ped ID " .. pedId .. " introuvable^7")
        return
    end

    -- Charger le modèle
    local modelHash = GetHashKey(pedData.model)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end

    if not HasModelLoaded(modelHash) then
        print("^1[ERROR] Impossible de charger le modèle " .. pedData.model .. "^7")
        return
    end

    -- Obtenir position devant le joueur (très proche pour MLO)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    local forwardX = playerCoords.x + (math.sin(math.rad(playerHeading)) * -0.8)  -- 0.8m seulement
    local forwardY = playerCoords.y + (math.cos(math.rad(playerHeading)) * 0.8)
    local forwardZ = playerCoords.z

    -- Obtenir coordonnée Z au sol avec retry
    local groundZ = GetGroundZ(forwardX, forwardY, forwardZ)

    -- Créer le ped
    local ped = CreatePed(4, modelHash, forwardX, forwardY, groundZ, playerHeading, false, true)

    SetEntityAlpha(ped, 150, false)  -- Plus transparent pour mieux voir
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)

    currentPed = ped
    currentPedId = pedId
    pedRotation = playerHeading

    print("^2[SUCCESS] Ped " .. pedData.label .. " spawné^7")

    -- Activer automatiquement le mode placement
    EnterPlacementMode()
end

-- Fonction pour entrer en mode placement
function EnterPlacementMode()
    if not currentPed or not DoesEntityExist(currentPed) then
        print("^1[ERROR] Aucun ped à placer^7")
        return
    end

    placementMode = true
    local pedCoords = GetEntityCoords(currentPed)
    CreateFreecam(pedCoords)

    print("^3[INFO] Mode placement activé^7")
end

-- Fonction pour valider le placement
local function ValidatePlacement()
    if not currentPed or not DoesEntityExist(currentPed) then return end

    local coords = GetEntityCoords(currentPed)
    local heading = GetEntityHeading(currentPed)

    -- Rendre le ped normal
    ResetEntityAlpha(currentPed)
    SetEntityCollision(currentPed, true, true)
    FreezeEntityPosition(currentPed, true)

    -- Appliquer le scenario
    local pedData = nil
    for _, ped in ipairs(Config.CinematicPeds) do
        if ped.id == currentPedId then
            pedData = ped
            break
        end
    end

    if pedData and pedData.scenario then
        TaskStartScenarioInPlace(currentPed, pedData.scenario, 0, true)
    end

    -- Sauvegarder le ped spawné
    table.insert(spawnedPeds, {
        ped = currentPed,
        coords = coords,
        heading = heading,
        id = currentPedId
    })

    -- Print vector4 dans F8
    local vector4Str = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, heading)
    print("^2[PLACEMENT VALIDÉ] " .. vector4Str .. "^7")

    -- Nettoyer
    DestroyFreecam()
    placementMode = false
    currentPed = nil
    currentPedId = nil
    pedRotation = 0.0
end

-- Fonction pour annuler le placement
local function CancelPlacement()
    if currentPed and DoesEntityExist(currentPed) then
        DeleteEntity(currentPed)
    end

    DestroyFreecam()
    placementMode = false
    currentPed = nil
    currentPedId = nil
    pedRotation = 0.0

    print("^1[ANNULÉ] Placement annulé^7")
end

-- Thread principal pour le mode placement
CreateThread(function()
    while true do
        Wait(0)

        if placementMode then
            -- S'assurer que le joueur reste visible
            local playerPed = PlayerPedId()
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)

            -- Désactiver seulement les contrôles de mouvement (pas tous)
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- Enter
            DisableControlAction(0, 75, true) -- Exit Vehicle

            -- Mouvement de la caméra
            local camSpeed = 0.2
            local camRot = GetCamRot(freecam, 2)
            local camCoord = GetCamCoord(freecam)

            -- ZQSD pour déplacer
            local newX, newY, newZ = camCoord.x, camCoord.y, camCoord.z

            if IsControlPressed(0, 32) then -- W (Z sur AZERTY)
                local direction = RotationToDirection(camRot)
                newX = newX + direction.x * camSpeed
                newY = newY + direction.y * camSpeed
            end

            if IsControlPressed(0, 33) then -- S
                local direction = RotationToDirection(camRot)
                newX = newX - direction.x * camSpeed
                newY = newY - direction.y * camSpeed
            end

            if IsControlPressed(0, 34) then -- A (Q sur AZERTY)
                local direction = RotationToDirection(camRot)
                local perpDirection = vector3(-direction.y, direction.x, 0)
                newX = newX + perpDirection.x * camSpeed
                newY = newY + perpDirection.y * camSpeed
            end

            if IsControlPressed(0, 35) then -- D
                local direction = RotationToDirection(camRot)
                local perpDirection = vector3(-direction.y, direction.x, 0)
                newX = newX - perpDirection.x * camSpeed
                newY = newY - perpDirection.y * camSpeed
            end

            -- Espace / Ctrl pour monter/descendre
            if IsControlPressed(0, 22) then -- Espace
                newZ = newZ + camSpeed
            end

            if IsControlPressed(0, 36) then -- Ctrl
                newZ = newZ - camSpeed
            end

            SetCamCoord(freecam, newX, newY, newZ)
            freecamCoords = vector3(newX, newY, newZ)

            -- Rotation de la souris
            local mouseX = GetDisabledControlNormal(0, 1) * 5.0
            local mouseY = GetDisabledControlNormal(0, 2) * 5.0

            local newRotX = camRot.x - mouseY
            local newRotZ = camRot.z - mouseX

            -- Limiter la rotation verticale
            if newRotX > 89.0 then newRotX = 89.0 end
            if newRotX < -89.0 then newRotX = -89.0 end

            SetCamRot(freecam, newRotX, 0.0, newRotZ, 2)

            -- Déplacer le ped avec le raycast
            local rayCoords = GetRaycastCoords()
            if rayCoords and currentPed and DoesEntityExist(currentPed) then
                SetEntityCoords(currentPed, rayCoords.x, rayCoords.y, rayCoords.z, false, false, false, false)
                SetEntityHeading(currentPed, pedRotation)
            end

            -- Touche X pour rotation
            if IsControlJustPressed(0, 73) then -- X
                pedRotation = pedRotation + 15.0
                if pedRotation >= 360.0 then
                    pedRotation = pedRotation - 360.0
                end
            end

            -- Clic gauche pour valider
            if IsControlJustPressed(0, 24) then -- Clic gauche
                ValidatePlacement()
            end

            -- Clic droit pour annuler
            if IsControlJustPressed(0, 25) then -- Clic droit
                CancelPlacement()
            end

            -- Afficher les instructions avec rotation actuelle
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(
                "~b~MODE PLACEMENT~w~\n" ..
                "~g~ZQSD~w~ : Déplacer caméra\n" ..
                "~g~Souris~w~ : Regarder\n" ..
                "~g~Espace/Ctrl~w~ : Monter/Descendre\n" ..
                "~g~X~w~ : Rotation ped (+15°)\n" ..
                "~o~Rotation actuelle : " .. math.floor(pedRotation) .. "°~w~\n" ..
                "~g~Clic gauche~w~ : Valider\n" ..
                "~g~Clic droit~w~ : Annuler"
            )
            SetTextJustification(2)
            DrawText(0.95, 0.05)
        else
            Wait(500)
        end
    end
end)

-- Commande /cinelist - Liste des peds
RegisterCommand('cinelist', function()
    print("^2========== PEDS CINÉMATIQUES ==========^7")
    print("^3Utilisez /cinespawn [ID] pour spawner un ped^7")
    print("")

    for _, ped in ipairs(Config.CinematicPeds) do
        print(string.format("^5ID %d^7 : %s ^8(modèle: %s)^7", ped.id, ped.label, ped.model))
    end

    print("")
    print("^2========================================^7")
end, false)

-- Commande /cinespawn [ID]
RegisterCommand('cinespawn', function(source, args)
    local pedId = tonumber(args[1])

    if not pedId then
        print("^1[ERROR] Usage: /cinespawn [ID]^7")
        return
    end

    SpawnCinematicPed(pedId)
end, false)

-- Commande /cineplace [ID]
RegisterCommand('cineplace', function(source, args)
    local pedId = tonumber(args[1])

    if not pedId then
        print("^1[ERROR] Usage: /cineplace [ID]^7")
        return
    end

    SpawnCinematicPed(pedId)
end, false)

-- Commande /cineclear
RegisterCommand('cineclear', function()
    local count = 0

    for _, pedData in ipairs(spawnedPeds) do
        if DoesEntityExist(pedData.ped) then
            DeleteEntity(pedData.ped)
            count = count + 1
        end
    end

    spawnedPeds = {}

    -- Supprimer aussi le ped en cours de placement
    if currentPed and DoesEntityExist(currentPed) then
        DeleteEntity(currentPed)
        count = count + 1
    end

    if placementMode then
        DestroyFreecam()
        placementMode = false
        currentPed = nil
        currentPedId = nil
        pedRotation = 0.0
    end

    print("^2[SUCCESS] " .. count .. " ped(s) supprimé(s)^7")
end, false)

-- Debug
print("^2[ZScene] Script de placement de peds cinématiques chargé^7")
print("^3[INFO] Commandes: /cinelist, /cinespawn [ID], /cineplace [ID], /cineclear^7")
