Placement = { active = false }

local cam, ghost, resolve
local mode, label, colour, radius, pinned, snapToGround

local CONTROLS = {
    confirm = 191,  -- Enter
    cancel  = 194,  -- Backspace
    forward = 32, back = 33, left = 34, right = 35,
    up = 22, down = 36,
    fast = 21, slow = 19,
    grow = 96, shrink = 97,
    snap = 47,      -- G
    drop = 73,      -- X
    fine = 21,
}

local function camForward()
    local rot = GetCamRot(cam, 2)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function aimPoint(distance)
    local from = GetCamCoord(cam)
    local to = from + (camForward() * distance)

    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16 + 256, cache.ped, 4)

    local _, hit, coords = GetShapeTestResult(ray)

    if hit == 1 then return coords end
    return to
end

local function surfaceUnder(x, y, z)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        x, y, z + 1.0, x, y, z - 6.0, 1 + 16 + 256, cache.ped, 4)

    local _, hit, coords = GetShapeTestResult(ray)
    if hit == 1 then return coords.z end
    return nil
end

local function drawGhost()
    if not ghost then return end

    local r, g, b = colour[1], colour[2], colour[3]

    DrawMarker(mode == 'zone' and 1 or 28,
        ghost.x, ghost.y, ghost.z + (mode == 'zone' and -0.05 or 0.0),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        mode == 'zone' and radius * 2 or 0.4,
        mode == 'zone' and radius * 2 or 0.4,
        mode == 'zone' and 0.6 or 0.4,
        r, g, b, 110, false, false, 2, false)

    if mode ~= 'zone' then
        DrawLine(ghost.x, ghost.y, ghost.z, ghost.x, ghost.y, ghost.z + 1.4, r, g, b, 180)
    end
end

local function stopCam()
    if cam then
        RenderScriptCams(false, true, 320, true, true)
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        cam = nil
    end

    ClearFocus()
    FreezeEntityPosition(cache.ped, false)
    lib.hideTextUI()

    Placement.active = false
end

local function finish(result)
    stopCam()

    local done = resolve
    resolve = nil
    if done then done(result) end
end

function Placement.Abort()
    if Placement.active then finish(nil) end
end

-- Returns { x, y, z, h, radius } or nil if the admin backed out.
function Placement.Start(options)
    if Placement.active then return nil end

    options = options or {}
    mode = options.mode or 'point'
    label = options.label or 'Point'
    colour = options.colour or { 255, 166, 41 }
    radius = options.radius or 3.0
    pinned = false
    snapToGround = options.snapToGround
    if snapToGround == nil then snapToGround = Config.Builder.snapToGround == true end

    local ped = cache.ped
    local start = options.origin
        and vector3(options.origin.x, options.origin.y, options.origin.z)
        or GetEntityCoords(ped)

    ghost = {
        x = start.x, y = start.y, z = start.z,
        h = options.origin and options.origin.h or GetEntityHeading(ped),
    }

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, start.x, start.y, start.z + 2.0)
    SetCamRot(cam, -15.0, 0.0, GetEntityHeading(ped), 2)
    SetCamFov(cam, 60.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 320, true, true)

    FreezeEntityPosition(ped, true)
    Placement.active = true

    lib.showTextUI(([[
**Placing %s**
[Enter] Put it here
[WASD] Fly  ·  [Shift] fast  ·  [Alt] slow
[Q] / [E] Up and down
[Scroll] %s
[X] Drop to the floor
[G] Ground snap
[Backspace] Cancel]]):format(label, mode == 'zone' and 'Size' or 'Turn'),
        { position = 'left-center' })

    local promised = promise.new()
    resolve = function(value) promised:resolve(value) end

    CreateThread(function()
        local speeds = Config.Builder.cameraSpeed
        local nudge = Config.Builder.nudgeStep
        local manual = false

        while Placement.active do
            Wait(0)

            DisableAllControlActions(0)
            EnableControlAction(0, CONTROLS.confirm, true)
            EnableControlAction(0, CONTROLS.cancel, true)

            local pos = GetCamCoord(cam)
            local rot = GetCamRot(cam, 2)

            local dx = GetDisabledControlNormal(0, 1) * 6.0
            local dy = GetDisabledControlNormal(0, 2) * 6.0
            local pitch = math.max(-89.0, math.min(89.0, rot.x - dy))
            SetCamRot(cam, pitch, 0.0, rot.z - dx, 2)

            local speed = speeds.normal
            if IsDisabledControlPressed(0, CONTROLS.fast) then speed = speeds.fast end
            if IsDisabledControlPressed(0, CONTROLS.slow) then speed = speeds.slow end
            speed = speed * GetFrameTime()

            local fwd = camForward()

            -- X is east and Y is north, so the right of a forward (fx, fy) is
            -- (fy, -fx). Writing (-fy, fx) gives you left, and nothing catches
            -- it until somebody actually flies.
            local right = vector3(fwd.y, -fwd.x, 0.0)
            local move = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, CONTROLS.forward) then move = move + fwd end
            if IsDisabledControlPressed(0, CONTROLS.back) then move = move - fwd end
            if IsDisabledControlPressed(0, CONTROLS.right) then move = move + right end
            if IsDisabledControlPressed(0, CONTROLS.left) then move = move - right end
            if IsDisabledControlPressed(0, CONTROLS.up) then move = move + vector3(0.0, 0.0, 1.0) end
            if IsDisabledControlPressed(0, CONTROLS.down) then move = move - vector3(0.0, 0.0, 1.0) end

            if #move > 0.0 then
                pos = pos + move * speed
                SetCamCoord(cam, pos.x, pos.y, pos.z)
                if not pinned then manual = false end
            end

            SetFocusPosAndVel(pos.x, pos.y, pos.z, 0.0, 0.0, 0.0)

            if not manual then
                local hit = aimPoint(Config.Builder.placementRange)
                ghost.x, ghost.y, ghost.z = hit.x, hit.y, hit.z

                if snapToGround then
                    local found, groundZ = GetGroundZFor_3dCoord(ghost.x, ghost.y, ghost.z + 1.0, false)

                    -- Ground height is TERRAIN height. It ignores interior
                    -- floors, kerbs and anything raised, so a big drop means
                    -- it punched through the surface you were looking at.
                    if found and math.abs(ghost.z - groundZ) <= 1.5 then
                        ghost.z = groundZ
                    end
                end
            end

            if IsDisabledControlJustPressed(0, CONTROLS.snap) then
                snapToGround = not snapToGround
            end

            if IsDisabledControlJustPressed(0, CONTROLS.drop) then
                local floor = surfaceUnder(ghost.x, ghost.y, ghost.z)
                if floor then
                    ghost.z = floor
                    manual = true
                    pinned = true
                end
            end

            local step = IsDisabledControlPressed(0, CONTROLS.fine) and (nudge / 10) or nudge

            if IsDisabledControlPressed(0, 172) then ghost.y = ghost.y + step manual = true end
            if IsDisabledControlPressed(0, 173) then ghost.y = ghost.y - step manual = true end
            if IsDisabledControlPressed(0, 174) then ghost.x = ghost.x - step manual = true end
            if IsDisabledControlPressed(0, 175) then ghost.x = ghost.x + step manual = true end

            if mode == 'zone' then
                if IsDisabledControlPressed(0, CONTROLS.grow) then radius = math.min(60.0, radius + 0.1) end
                if IsDisabledControlPressed(0, CONTROLS.shrink) then radius = math.max(0.5, radius - 0.1) end
            else
                if IsDisabledControlPressed(0, CONTROLS.grow) then ghost.h = (ghost.h + 1.5) % 360 end
                if IsDisabledControlPressed(0, CONTROLS.shrink) then ghost.h = (ghost.h - 1.5) % 360 end
            end

            drawGhost()

            if IsDisabledControlJustPressed(0, CONTROLS.confirm) then
                finish({ x = ghost.x, y = ghost.y, z = ghost.z, h = ghost.h, radius = radius })
                break
            end

            if IsDisabledControlJustPressed(0, CONTROLS.cancel) then
                finish(nil)
                break
            end
        end
    end)

    return Citizen.Await(promised)
end
