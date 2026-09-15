Discord = {}

local urlByCategory = {
    tuning = Config.Discord.tuningWebhook,
    money = Config.Discord.moneyWebhook,
    admin = Config.Discord.adminWebhook,
    service = Config.Discord.serviceWebhook,
}

Discord.Colour = {
    info = 0x5865F2,
    good = 0x37D399,
    warn = 0xFFA629,
    bad = 0xFF5F56,
}

-- Fire and forget. A Discord outage must never be able to break a repair.
function Discord.Send(category, title, description, colour, fields)
    local url = urlByCategory[category]
    if not url or url == '' then return end

    PerformHttpRequest(url, function() end, 'POST', json.encode({
        username = Config.Discord.botName,
        embeds = { {
            title = title,
            description = description,
            color = colour or Discord.Colour.info,
            fields = fields,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        } },
    }), { ['Content-Type'] = 'application/json' })
end
