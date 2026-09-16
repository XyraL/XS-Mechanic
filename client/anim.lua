Anim = { holding = false }

--[[ Holding the tablet, and working on a car.

     A prop in the left hand and a looping "looking at something" pose, played
     while the panel is open. Purely cosmetic — nothing waits on it, and if the
     model or the dictionary fails to load the interface still opens. ]]

local prop = nil

local DICT = 'amb@world_human_tourist_map@male@base'
local CLIP = 'base'
local MODEL = 'prop_cs_tablet'

-- SKEL_L_Hand. The tablet sits in the left hand so the right is free.
local BONE = 18905

--[[ What the mechanic looks like doing each kind of work.

     A bumper does not go on the same way as a set of wheels, and watching the
     same kneeling animation for all of it makes the shop feel like one job
     with different labels on it.

     Every dictionary here ships with the game. One that will not load falls
     back to the kneeling repair rather than leaving a progress bar running
     over a ped stood perfectly still. ]]
local WORK = {
    cosmetics   = { dict = 'amb@world_human_welding@male@base',          clip = 'base' },
    wheels      = { dict = 'mini@repair',                                clip = 'fixing_a_ped' },
    respray     = { dict = 'amb@world_human_janitor@male@base',          clip = 'base' },
    livery      = { dict = 'amb@world_human_janitor@male@base',          clip = 'base' },
    lights      = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base' },
    interior    = { dict = 'amb@world_human_clipboard@male@base',        clip = 'base' },
    extras      = { dict = 'amb@world_human_hammering@male@base',        clip = 'base' },
    plate       = { dict = 'amb@world_human_hammering@male@base',        clip = 'base' },
    performance = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base' },
    repair      = { dict = 'mini@repair',                                clip = 'fixing_a_ped' },
    service     = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base' },
    craft       = { dict = 'amb@world_human_welding@male@base',          clip = 'base' },
}

local FALLBACK = { dict = 'mini@repair', clip = 'fixing_a_ped' }

local function dropProp()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

--[[ Only the tablet pose is stopped, never every task the ped has.

     `ClearPedTasks` here used to kill whatever the ped had been asked to do
     next — which, since the panel closes before a part is fitted, was the
     fitting animation itself.

     And it is stopped unconditionally. Checking `IsEntityPlayingAnim` first
     looks careful and is worse: the pose reports as not playing while it is
     still blending in, so closing the tablet quickly left a looping animation
     running with nothing left that knew about it. ]]
local function stopPose()
    local ped = cache and cache.ped or PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return end

    StopAnimTask(ped, DICT, CLIP, 4.0)
end

local function cleanup()
    dropProp()
    stopPose()
    Anim.holding = false
end

function Anim.Start()
    if not Config.Tablet.animation then return end
    if Anim.holding then return end

    Anim.holding = true

    CreateThread(function()
        local ped = cache.ped

        local ok = pcall(function()
            lib.requestAnimDict(DICT, 3000)
            lib.requestModel(MODEL, 3000)
        end)

        -- The panel is already open by now. A missing asset costs the pose,
        -- nothing else.
        if not ok or not Anim.holding then
            if not Anim.holding then cleanup() end
            return
        end

        if not DoesEntityExist(ped) then return end

        TaskPlayAnim(ped, DICT, CLIP, 3.0, -1.0, -1, 49, 0, false, false, false)

        prop = CreateObject(joaat(MODEL), 0.0, 0.0, 0.0, true, true, false)

        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, BONE),
            0.05, 0.02, -0.02, 10.0, 160.0, 0.0,
            true, true, false, true, 1, true)

        SetModelAsNoLongerNeeded(joaat(MODEL))

        -- Walking away should not leave the pose stuck on.
        while Anim.holding do
            Wait(500)

            if not DoesEntityExist(ped) then break end

            if not IsEntityPlayingAnim(ped, DICT, CLIP, 3) then
                TaskPlayAnim(ped, DICT, CLIP, 3.0, -1.0, -1, 49, 0, false, false, false)
            end
        end

        -- Whatever ended the loop, the pose this thread started is this
        -- thread's to stop. Anim.Stop having already done it is harmless.
        cleanup()
    end)
end

-- Stopping happens here and now rather than on the next tick of the loop above.
-- Anything started straight afterwards used to be wiped out by this arriving
-- half a second late.
function Anim.Stop()
    Anim.holding = false
    cleanup()
end

-- A dictionary that will not load leaves ox_lib waiting on one that never
-- arrives, so it is asked for here and the answer decides what gets played.
local function loadable(entry)
    if not entry then return nil end

    pcall(function() lib.requestAnimDict(entry.dict, 1200) end)

    if HasAnimDictLoaded(entry.dict) then return entry end

    return nil
end

function Anim.For(category)
    return loadable(WORK[category or '']) or loadable(FALLBACK)
end

--[[ Working on a car.

     ox_lib plays and clears the animation itself, which is the whole point of
     handing it over: there is no window where the pose is running and the
     progress bar has already gone.

     Returns true if the mechanic saw it through. ]]
function Anim.Work(seconds, label, category)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return true end

    local entry = Anim.For(category)

    local done = lib.progressCircle({
        duration = math.floor(seconds * 1000),
        label = label or 'Working',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = entry and { dict = entry.dict, clip = entry.clip, flag = 49 } or nil,
    })

    return done == true
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanup()
end)
