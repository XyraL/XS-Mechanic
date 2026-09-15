Hud = {}

-- Drawn by the same NUI page, shown when a vehicle is connected and the panel
-- is closed. It never takes focus, and XSM.Send stays unconditional — gating
-- messages on the panel being open freezes the HUD.
function Hud.Update()
    local settings = XSM.state and XSM.state.settings or {}

    if not XSM.vehicle or not DoesEntityExist(XSM.vehicle) or settings.hud == false then
        XSM.Send('hud', { hud = false })
        return
    end

    local catalogue = XSM.catalogue
    if not catalogue then return end

    local engine = math.floor(GetVehicleEngineHealth(XSM.vehicle) / 10)
    local body = math.floor(GetVehicleBodyHealth(XSM.vehicle) / 10)
    local draft = XSM.state and XSM.state.invoice

    local rows = {
        { k = 'Vehicle', v = catalogue.name },
        { k = 'Engine', v = ('%d%%'):format(engine), percent = engine,
          track = engine < 40 and 't-bad' or engine < 70 and 't-warn' or '' },
        { k = 'Body', v = ('%d%%'):format(body), percent = body,
          track = body < 40 and 't-bad' or body < 70 and 't-warn' or '' },
    }

    local due = XSM.state and XSM.state.vehicle and XSM.state.vehicle.service
        and XSM.state.vehicle.service.due or 0

    if due > 0 then
        rows[#rows + 1] = { k = 'Service', v = ('%d DUE'):format(due), tone = 'bad' }
    end

    if draft and (draft.total or 0) > 0 then
        rows[#rows + 1] = { k = 'Draft', v = Util.Money(draft.total) }
    end

    XSM.Send('hud', {
        hud = {
            shop = XSM.shop and XSM.shop.name or 'Mechanic',
            plate = catalogue.plate,
            rows = rows,
        },
    })
end

-- Health moves while the car is being worked on, so the HUD is refreshed on a
-- slow tick rather than only when something is clicked.
CreateThread(function()
    while true do
        Wait(2000)

        if XSM.vehicle and DoesEntityExist(XSM.vehicle) and not XSM.open then
            Hud.Update()
        end
    end
end)
