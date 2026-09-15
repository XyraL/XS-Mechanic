Anim = { holding = false }

--[[ Holding the tablet.

     A prop in the left hand and a looping "looking at something" pose, played
     while the panel is open. Purely cosmetic — nothing waits on it, and if the
     model or the dictionary fails to load the interface still opens. ]]

local prop = nil

local DICT = 'amb@world_human_tourist_map@male@base'
local CLIP = 'base'
local MODEL = 'prop_cs_tablet'

-- SKEL_L_Hand. The tablet sits in the left hand so the right is free.
local BONE = 18905

local function cleanup()
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
    prop = nil

    local ped = cache and cache.ped or PlayerPedId()
    if ped and DoesEntityExist(ped) then ClearPedTasks(ped) end

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

        cleanup()
    end)
end

function Anim.Stop()
    if not Anim.holding then
        cleanup()
        return
    end

    Anim.holding = false
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanup()
end)
