--[[ Loaded last on the client.

     FiveM logs a missing manifest file once at startup and carries on, so the
     first thing that touches that file's global is where it blows up — and the
     stack points at the caller rather than the cause. Each optional global gets
     a no-op stub and a line in the console naming the file that is missing. The
     feature switches off, the resource keeps running. ]]

local missing = {}

local function optional(name, file, stub)
    if _G[name] ~= nil then return end

    _G[name] = stub or setmetatable({}, {
        __index = function() return function() end end,
    })

    missing[#missing + 1] = file
end

optional('Placement', 'client/placement.lua', { active = false, Start = function() return nil end, Abort = function() end })
optional('Builder', 'client/builder.lua')
optional('Zones', 'client/zones.lua', { Rebuild = function() end, Colour = {}, JobMatches = function() return false end, CanUseBay = function() return false end, InShop = function() return true end, ShopAt = function() return nil end, OnPoint = function() return nil end })
optional('Preview', 'client/preview.lua', { Show = function() return false end, Respray = function() return false end, Extra = function() return false end, Commit = function() end, StopCam = function() end, Snapshot = function() end, Restore = function() end, Control = function() return false end })
optional('Repair', 'client/repair.lua')
optional('Craft', 'client/craft.lua', { at = nil, Open = function() end, Close = function() end })
optional('Hud', 'client/hud.lua', { Update = function() end })
optional('Orders', 'client/orders.lua')
optional('Team', 'client/orders.lua', { NearestPlayer = function() return nil end })
optional('Stance', 'client/stance.lua', { Apply = function() end, Preview = function() end, Read = function() return {} end, Normalise = function() return nil end, Empty = function() return {} end, Restore = function() end })
optional('Stations', 'client/stations.lua', { CanUse = function() return false end, BayUnder = function() return nil end, Open = function() end, Apply = function() end, Repair = function() end, Wash = function() end })
optional('Perf', 'client/perf.lua', { Apply = function() end, Profile = function() return nil end, Forget = function() end })
optional('Odometer', 'client/service.lua', { Report = function() end })
optional('ServiceUI', 'client/service.lua', { Replace = function() end })
optional('Dyno', 'client/dyno.lua', { running = false, Run = function() end, Stop = function() end, Share = function() end })
optional('Nitrous', 'client/extras.lua', { active = false, Toggle = function() end, Level = function() return 0 end })
optional('Lighting', 'client/extras.lua', { Open = function() end, Set = function() end })
optional('Anim', 'client/anim.lua', { holding = false, Start = function() end, Stop = function() end, Work = function() return true end })
optional('Catalogue', 'client/catalogue.lua', { Build = function() return nil end, SupportsChameleon = function() return false end, IsElectric = function() return false end })
optional('Install', 'client/install.lua', { Use = function() end, ByHand = function() end, Pick = function() end })

-- Shared, not client, but the client is where a missing one is felt: without
-- it every part item registers an export that cannot resolve its own name.
optional('Paint', 'shared/paint.lua', { Families = {}, Colours = {}, ById = {}, Get = function() return nil end, Sheet = function() return {} end, Allowed = function() return false end })

if XSM and not XSM.StopPreview then
    XSM.StopPreview = function() end
end

if XSM and not XSM.PushBasket then
    XSM.PushBasket = function() end
end

if XSM and not XSM.NearPoints then
    XSM.NearPoints = function() return {} end
end

if #missing > 0 then
    print(('^1[XS-Mechanic]^0 %d file(s) missing from the client, features switched off:'):format(#missing))
    for _, file in ipairs(missing) do
        print(('^1[XS-Mechanic]^0   %s'):format(file))
    end
end
