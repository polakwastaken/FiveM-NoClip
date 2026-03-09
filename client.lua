local noclip = false
local speedIndex = 2
local scaleform = nil
local currentNoclipEntity = 0

local CONFIG = {
    -- Movement speed presets switched with mouse wheel.
    speeds = { 0.5, 1.0, 2.0, 5.0, 10.0 },
    -- Multiplier while boost key is held.
    boostMultiplier = 2.0,

    -- Key controls (FiveM control IDs).
    speedUpControl = 241,
    speedDownControl = 242,
    boostControl = 21,

    moveForwardControl = 32,
    moveBackControl = 33,
    moveLeftControl = 34,
    moveRightControl = 35,
    moveUpControl = 22,
    moveDownControl = 36,

    -- Ground detection probe settings for fast return-to-ground.
    groundProbeStartZ = 1200.0,
    groundProbeStep = 10.0,
    groundProbeIterations = 260,
    groundProbeYieldEvery = 20,
    -- Final Z offset above detected ground.
    groundPedOffset = 0.25,
    groundVehicleOffset = 1.0,
    -- Skip snap when already near ground.
    groundSnapMinDistance = 2.0,
    -- If entity is below ground, use a smaller threshold so slight under-map positions are still corrected.
    belowGroundSnapMinDistance = 0.1,

    -- Snap animation timing.
    snapMinMs = 450,
    snapMaxMs = 1400,
    snapMsPerDistance = 7.0,

    -- General loop/restore timing.
    restoreDelayMs = 150,
    noclipIdleWaitMs = 250,

    -- Keymapping command.
    hotkeyCommand = "noclip_key",
    hotkeyDefault = "F2",
}

local function RestoreEntityState(entity)
    if entity == 0 or not DoesEntityExist(entity) then
        return
    end

    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
    SetEntityVisible(entity, true, false)
    ResetEntityAlpha(entity)
    ActivatePhysics(entity)
    SetEntityDynamic(entity, true)
    SetEntityHasGravity(entity, true)
end

local function GetGroundZAtCoords(x, y)
    for i = 0, CONFIG.groundProbeIterations do
        local probeZ = CONFIG.groundProbeStartZ - (i * CONFIG.groundProbeStep)
        RequestCollisionAtCoord(x, y, probeZ)
        local found, groundZ = GetGroundZFor_3dCoord(x, y, probeZ, false)
        if found then
            return groundZ
        end

        if i % CONFIG.groundProbeYieldEvery == 0 then
            Wait(0)
        end
    end

    return nil
end

local function FastBringToGround(entity, inVehicle)
    if entity == 0 or not DoesEntityExist(entity) then
        return
    end

    local pos = GetEntityCoords(entity)
    local groundZ = GetGroundZAtCoords(pos.x, pos.y)
    if not groundZ then
        return
    end

    local targetZ = groundZ + (inVehicle and CONFIG.groundVehicleOffset or CONFIG.groundPedOffset)
    local distance = math.abs(pos.z - targetZ)
    local isBelowGround = pos.z < targetZ
    local minDistance = isBelowGround and CONFIG.belowGroundSnapMinDistance or CONFIG.groundSnapMinDistance
    if distance < minDistance then
        return
    end

    local durationMs = math.min(CONFIG.snapMaxMs, math.max(CONFIG.snapMinMs, math.floor(distance * CONFIG.snapMsPerDistance)))
    local startTime = GetGameTimer()
    local startZ = pos.z

    while true do
        local t = (GetGameTimer() - startTime) / durationMs
        if t >= 1.0 then
            break
        end

        local eased = t * t * (3.0 - (2.0 * t))
        local newZ = startZ + ((targetZ - startZ) * eased)
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, newZ, true, true, true)
        Wait(0)
    end

    SetEntityCoordsNoOffset(entity, pos.x, pos.y, targetZ, true, true, true)
end

local function SetupScaleform()
    scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    local function AddButton(index, control, text)
        PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(index)
        PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, control, true))
        PushScaleformMovieFunctionParameterString(text)
        PopScaleformMovieFunctionVoid()
    end

    AddButton(0, CONFIG.moveForwardControl, "Forward")
    AddButton(1, CONFIG.moveBackControl, "Back")
    AddButton(2, CONFIG.moveLeftControl, "Left")
    AddButton(3, CONFIG.moveRightControl, "Right")
    AddButton(4, CONFIG.moveUpControl, "Up")
    AddButton(5, CONFIG.moveDownControl, "Down")
    AddButton(6, CONFIG.speedUpControl, "Speed +")
    AddButton(7, CONFIG.speedDownControl, "Speed -")
    AddButton(8, CONFIG.boostControl, "Boost")

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()
end

local function RemoveScaleform()
    if scaleform then
        SetScaleformMovieAsNoLongerNeeded(scaleform)
        scaleform = nil
    end
end

local function ToggleNoclip()
    noclip = not noclip

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local entity = vehicle ~= 0 and vehicle or ped

    if noclip then
        currentNoclipEntity = entity
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, false, false)
        SetEntityInvincible(ped, true)
        SetEntityVisible(entity, false, false)
        if vehicle ~= 0 then
            SetEntityVisible(ped, false, false)
        end
        SetupScaleform()
    else
        FastBringToGround(entity, vehicle ~= 0)

        RestoreEntityState(entity)
        RestoreEntityState(ped)
        if currentNoclipEntity ~= 0 and currentNoclipEntity ~= entity then
            RestoreEntityState(currentNoclipEntity)
        end

        SetEntityInvincible(ped, false)
        RemoveScaleform()

        local restorePed = ped
        local restoreEntity = entity
        local restoreTracked = currentNoclipEntity
        CreateThread(function()
            Wait(CONFIG.restoreDelayMs)
            RestoreEntityState(restorePed)
            RestoreEntityState(restoreEntity)
            if restoreTracked ~= 0 and restoreTracked ~= restoreEntity then
                RestoreEntityState(restoreTracked)
            end
        end)

        currentNoclipEntity = 0
    end
end

RegisterNetEvent("noclip:toggle", function()
    ToggleNoclip()
end)

RegisterCommand(CONFIG.hotkeyCommand, function()
    TriggerServerEvent("noclip:requestToggle")
end, false)

RegisterKeyMapping(CONFIG.hotkeyCommand, "Toggle noclip", "keyboard", CONFIG.hotkeyDefault)


local function RotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

CreateThread(function()
    while true do
        if noclip then
            Wait(0)

            if scaleform then
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
            end

            local ped = PlayerPedId()
            if not DoesEntityExist(ped) then goto continue end

            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = vehicle ~= 0 and vehicle or ped
            if not DoesEntityExist(entity) then goto continue end

            if currentNoclipEntity ~= entity then
                if currentNoclipEntity ~= 0 then
                    RestoreEntityState(currentNoclipEntity)
                end

                currentNoclipEntity = entity
                FreezeEntityPosition(entity, true)
                SetEntityCollision(entity, false, false)
                SetEntityVisible(entity, false, false)
                if vehicle ~= 0 then
                    SetEntityVisible(ped, false, false)
                end
            end

            SetEntityVisible(entity, false, false)
            if vehicle ~= 0 then
                SetEntityVisible(ped, false, false)
            end

            local camRot = GetGameplayCamRot(2)
            local dir = RotationToDirection(camRot)
            local pos = GetEntityCoords(entity)
            local speed = CONFIG.speeds[speedIndex]

            if IsControlJustPressed(0, CONFIG.speedUpControl) then
                speedIndex = math.min(#CONFIG.speeds, speedIndex + 1)
            end

            if IsControlJustPressed(0, CONFIG.speedDownControl) then
                speedIndex = math.max(1, speedIndex - 1)
            end

            if IsControlPressed(0, CONFIG.boostControl) then
                speed = speed * CONFIG.boostMultiplier
            end

            if IsControlPressed(0, CONFIG.moveForwardControl) then pos = pos + dir * speed end
            if IsControlPressed(0, CONFIG.moveBackControl) then pos = pos - dir * speed end

            local right = vector3(dir.y, -dir.x, 0.0)
            if IsControlPressed(0, CONFIG.moveLeftControl) then pos = pos - right * speed end
            if IsControlPressed(0, CONFIG.moveRightControl) then pos = pos + right * speed end

            if IsControlPressed(0, CONFIG.moveUpControl) then pos = pos + vector3(0.0, 0.0, speed) end
            if IsControlPressed(0, CONFIG.moveDownControl) then pos = pos - vector3(0.0, 0.0, speed) end

            SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, true, true, true)

            if vehicle ~= 0 then
                SetEntityHeading(vehicle, camRot.z)
            else
                SetEntityHeading(ped, camRot.z)
            end

            ::continue::
        else
            Wait(CONFIG.noclipIdleWaitMs)
        end
    end
end)
