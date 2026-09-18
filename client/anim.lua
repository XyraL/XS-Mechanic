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

--[[ What the mechanic looks like working.

     One pose for everything — the same welding the bench uses. There used to
     be a different animation per category, which read well on paper and in
     practice meant a mechanic janitor-sweeping a respray and reading a
     clipboard at an interior. The bench pose is the one that looks like
     somebody making a car work, so it is the one every job gets. ]]
local POSE = { dict = 'amb@world_human_welding@male@base', clip = 'base' }

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

    -- The pose is played with flag 49, which makes it a SECONDARY task, and a
    -- secondary task does not always come off with StopAnimTask alone. This is
    -- safe here and nowhere else: anything the mechanic does next is started
    -- after the panel has already gone.
    local ped = cache and cache.ped or PlayerPedId()
    if ped and DoesEntityExist(ped) then ClearPedSecondaryTask(ped) end

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

    --[[ And asked again for a moment afterwards.

         A stop that lands while the pose is still blending in does not always
         take, and the pose is a loop with no duration — so when it does not
         take, it never ends. Only the tablet pose is touched, so whatever the
         mechanic starts doing next is left alone. ]]
    CreateThread(function()
        for _ = 1, 8 do
            Wait(250)

            if Anim.holding then return end

            local ped = cache and cache.ped or PlayerPedId()
            if not ped or not DoesEntityExist(ped) then return end

            if IsEntityPlayingAnim(ped, DICT, CLIP, 3) then stopPose() end
        end
    end)
end

-- A dictionary that will not load leaves ox_lib waiting on one that never
-- arrives, so it is asked for here and the answer decides what gets played.
local function loadable(entry)
    if not entry then return nil end

    pcall(function() lib.requestAnimDict(entry.dict, 1200) end)

    if HasAnimDictLoaded(entry.dict) then return entry end

    return nil
end

function Anim.For()
    return loadable(POSE) or loadable(FALLBACK)
end

--[[ Working on a car.

     ox_lib plays and clears the animation itself, which is the whole point of
     handing it over: there is no window where the pose is running and the
     progress bar has already gone.

     Returns true if the mechanic saw it through. ]]
function Anim.Work(seconds, label)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return true end

    local entry = Anim.For()

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
