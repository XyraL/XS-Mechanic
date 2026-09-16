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

local WORK = { dict = 'mini@repair', clip = 'fixing_a_ped' }

local function dropProp()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil
end

-- Only the tablet pose is stopped, never every task the ped has. ClearPedTasks
-- here used to kill whatever the ped had been asked to do next — which, since
-- the panel closes before a part is fitted, was the fitting animation itself.
local function stopPose()
    local ped = cache and cache.ped or PlayerPedId()

    if ped and DoesEntityExist(ped) and IsEntityPlayingAnim(ped, DICT, CLIP, 3) then
        StopAnimTask(ped, DICT, CLIP, 1.0)
    end
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
    end)
end

-- Stopping happens here and now rather than on the next tick of the loop above.
-- Anything started straight afterwards used to be wiped out by this arriving
-- half a second late.
function Anim.Stop()
    Anim.holding = false
    cleanup()
end

--[[ Working on a car.

     ox_lib plays and clears the animation itself, which is the whole point of
     handing it over: there is no window where the pose is running and the
     progress bar has already gone.

     Returns true if the mechanic saw it through. ]]
function Anim.Work(seconds, label)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return true end

    local done = lib.progressCircle({
        duration = math.floor(seconds * 1000),
        label = label or 'Working',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = WORK.dict,
            clip = WORK.clip,
            flag = 49,
        },
    })

    return done == true
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanup()
end)
