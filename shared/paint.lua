Paint = {}

--[[ The game's paint table, as the game defines it.

     Every colour here is an index into carcols, which is what
     SetVehicleColours takes. The FAMILY is not guessed from the name — it is
     the shader the game itself uses, so "Util Garnet Red" sits with the
     metallics because that is what it renders as, and "Worn Olive Army Green"
     sits with the mattes for the same reason.

     hex is what the colour LOOKS like on a car, not the value in the game
     files. Those two are a long way apart: Metallic Red is #690000 on disk and
     renders near #c00e1a, and Chrome is #000000 on disk because chrome is all
     reflection and no colour. A picker built from the file values is a grid of
     black squares.

     shaded marks the six finishes where no flat colour can be right. The hex
     on those is a stand-in for the swatch and nothing more.

     Two indices are deliberately absent. 156 is DEFAULT ALLOY COLOR, the
     fallback wheel tint rather than a body paint, and 160 is the unnamed
     highlight variant of the gold pair. Neither is sold in game. ]]

Paint.Families = {
    { id = 'metallic', label = 'Metallic' },
    { id = 'matte', label = 'Matte' },
    { id = 'metals', label = 'Metals & Chrome' },
    { id = 'utility', label = 'Utility' },
    { id = 'worn', label = 'Worn' },
}

Paint.Colours = {

    -- Metallic
    { id = 0,    family = 'metallic', label = 'Black',                 hex = '#0d1116' },
    { id = 1,    family = 'metallic', label = 'Graphite Black',        hex = '#1c1d21' },
    { id = 2,    family = 'metallic', label = 'Black Steel',           hex = '#32383d' },
    { id = 3,    family = 'metallic', label = 'Dark Silver',           hex = '#454b4f' },
    { id = 4,    family = 'metallic', label = 'Silver',                hex = '#999da0' },
    { id = 5,    family = 'metallic', label = 'Blue Silver',           hex = '#c2c4c6' },
    { id = 6,    family = 'metallic', label = 'Steel Gray',            hex = '#979a97' },
    { id = 7,    family = 'metallic', label = 'Shadow Silver',         hex = '#637380' },
    { id = 8,    family = 'metallic', label = 'Stone Silver',          hex = '#63625c' },
    { id = 9,    family = 'metallic', label = 'Midnight Silver',       hex = '#3c3f47' },
    { id = 10,   family = 'metallic', label = 'Gun Metal',             hex = '#444e54' },
    { id = 11,   family = 'metallic', label = 'Anthracite Grey',       hex = '#1d2129' },
    { id = 27,   family = 'metallic', label = 'Red',                   hex = '#c00e1a' },
    { id = 28,   family = 'metallic', label = 'Torino Red',            hex = '#da1918' },
    { id = 29,   family = 'metallic', label = 'Formula Red',           hex = '#b6111b' },
    { id = 30,   family = 'metallic', label = 'Blaze Red',             hex = '#a51e23' },
    { id = 31,   family = 'metallic', label = 'Graceful Red',          hex = '#7b1a22' },
    { id = 32,   family = 'metallic', label = 'Garnet Red',            hex = '#8e1b1f' },
    { id = 33,   family = 'metallic', label = 'Desert Red',            hex = '#6f1818' },
    { id = 34,   family = 'metallic', label = 'Cabernet Red',          hex = '#49111d' },
    { id = 35,   family = 'metallic', label = 'Candy Red',             hex = '#b60f25' },
    { id = 36,   family = 'metallic', label = 'Sunrise Orange',        hex = '#d44a17' },
    { id = 37,   family = 'metallic', label = 'Classic Gold',          hex = '#c2944f' },
    { id = 38,   family = 'metallic', label = 'Orange',                hex = '#f78616' },
    { id = 45,   family = 'metallic', label = 'Deep Garnet',           hex = '#8f1e17' },
    { id = 49,   family = 'metallic', label = 'Dark Green',            hex = '#132428' },
    { id = 50,   family = 'metallic', label = 'Racing Green',          hex = '#122e2b' },
    { id = 51,   family = 'metallic', label = 'Sea Green',             hex = '#12383c' },
    { id = 52,   family = 'metallic', label = 'Olive Green',           hex = '#31423f' },
    { id = 53,   family = 'metallic', label = 'Green',                 hex = '#155c2d' },
    { id = 54,   family = 'metallic', label = 'Gasoline Blue Green',   hex = '#1b6770' },
    { id = 61,   family = 'metallic', label = 'Midnight Blue',         hex = '#222e46' },
    { id = 62,   family = 'metallic', label = 'Dark Blue',             hex = '#233155' },
    { id = 63,   family = 'metallic', label = 'Saxony Blue',           hex = '#304c7e' },
    { id = 64,   family = 'metallic', label = 'Blue',                  hex = '#47578f' },
    { id = 65,   family = 'metallic', label = 'Mariner Blue',          hex = '#637ba7' },
    { id = 66,   family = 'metallic', label = 'Harbor Blue',           hex = '#394762' },
    { id = 67,   family = 'metallic', label = 'Diamond Blue',          hex = '#d6e7f1' },
    { id = 68,   family = 'metallic', label = 'Surf Blue',             hex = '#76afbe' },
    { id = 69,   family = 'metallic', label = 'Nautical Blue',         hex = '#345e72' },
    { id = 70,   family = 'metallic', label = 'Bright Blue',           hex = '#0b9cf1' },
    { id = 71,   family = 'metallic', label = 'Purple Blue',           hex = '#2f2d52' },
    { id = 72,   family = 'metallic', label = 'Spinnaker Blue',        hex = '#282c4d' },
    { id = 73,   family = 'metallic', label = 'Ultra Blue',            hex = '#2354a1' },
    { id = 74,   family = 'metallic', label = 'Light Blue',            hex = '#6ea3c6' },
    { id = 88,   family = 'metallic', label = 'Taxi Yellow',           hex = '#ffcf20' },
    { id = 89,   family = 'metallic', label = 'Race Yellow',           hex = '#fbe212' },
    { id = 90,   family = 'metallic', label = 'Bronze',                hex = '#916532' },
    { id = 91,   family = 'metallic', label = 'Yellow Bird',           hex = '#e0e13d' },
    { id = 92,   family = 'metallic', label = 'Lime',                  hex = '#98d223' },
    { id = 93,   family = 'metallic', label = 'Champagne',             hex = '#9b8c78' },
    { id = 94,   family = 'metallic', label = 'Pueblo Beige',          hex = '#503218' },
    { id = 95,   family = 'metallic', label = 'Dark Ivory',            hex = '#473f2b' },
    { id = 96,   family = 'metallic', label = 'Choco Brown',           hex = '#221b19' },
    { id = 97,   family = 'metallic', label = 'Golden Brown',          hex = '#653f23' },
    { id = 98,   family = 'metallic', label = 'Light Brown',           hex = '#775c3e' },
    { id = 99,   family = 'metallic', label = 'Straw Beige',           hex = '#ac9975' },
    { id = 100,  family = 'metallic', label = 'Moss Brown',            hex = '#6c6b4b' },
    { id = 101,  family = 'metallic', label = 'Bison Brown',           hex = '#402e2b' },
    { id = 102,  family = 'metallic', label = 'Beechwood',             hex = '#a4965f' },
    { id = 103,  family = 'metallic', label = 'Dark Beechwood',        hex = '#46231a' },
    { id = 104,  family = 'metallic', label = 'Choco Orange',          hex = '#752b19' },
    { id = 105,  family = 'metallic', label = 'Beach Sand',            hex = '#bfae7b' },
    { id = 106,  family = 'metallic', label = 'Sun Bleached Sand',     hex = '#dfd5b2' },
    { id = 107,  family = 'metallic', label = 'Cream',                 hex = '#f7edd5' },
    { id = 111,  family = 'metallic', label = 'White',                 hex = '#fffff6' },
    { id = 112,  family = 'metallic', label = 'Frost White',           hex = '#eaeaea' },
    { id = 125,  family = 'metallic', label = 'Securicor Green',       hex = '#83c566' },
    { id = 127,  family = 'metallic', label = 'Police Car Blue',       hex = '#4cc3da', restricted = true },
    { id = 134,  family = 'metallic', label = 'Pure White',            hex = '#ffffff' },
    { id = 135,  family = 'metallic', label = 'Hot Pink',              hex = '#f21f99' },
    { id = 136,  family = 'metallic', label = 'Salmon Pink',           hex = '#fdd6cd' },
    { id = 137,  family = 'metallic', label = 'Vermillion Pink',       hex = '#df5891' },
    { id = 138,  family = 'metallic', label = 'Amber',                 hex = '#f6ae20' },
    { id = 139,  family = 'metallic', label = 'Bright Green',          hex = '#b0ee6e' },
    { id = 140,  family = 'metallic', label = 'Cyan',                  hex = '#08e9fa' },
    { id = 141,  family = 'metallic', label = 'Black Blue',            hex = '#0a0c17' },
    { id = 142,  family = 'metallic', label = 'Black Purple',          hex = '#0c0d18' },
    { id = 143,  family = 'metallic', label = 'Black Red',             hex = '#0e0d14' },
    { id = 144,  family = 'metallic', label = 'Hunter Green',          hex = '#9f9e8a' },
    { id = 145,  family = 'metallic', label = 'Purple',                hex = '#621276' },
    { id = 146,  family = 'metallic', label = 'Very Dark Blue',        hex = '#0b1421' },
    { id = 147,  family = 'metallic', label = 'Carbon Black',          hex = '#11141a' },
    { id = 150,  family = 'metallic', label = 'Lava Red',              hex = '#bc1917' },
    { id = 157,  family = 'metallic', label = 'Epsilon Blue',          hex = '#afd6e4' },

    -- Matte
    { id = 12,   family = 'matte',    label = 'Black',                 hex = '#13181f' },
    { id = 13,   family = 'matte',    label = 'Gray',                  hex = '#26282a' },
    { id = 14,   family = 'matte',    label = 'Light Grey',            hex = '#515554' },
    { id = 39,   family = 'matte',    label = 'Red',                   hex = '#cf1f21' },
    { id = 40,   family = 'matte',    label = 'Dark Red',              hex = '#732021' },
    { id = 41,   family = 'matte',    label = 'Orange',                hex = '#f27d20' },
    { id = 42,   family = 'matte',    label = 'Yellow',                hex = '#ffc91f' },
    { id = 55,   family = 'matte',    label = 'Lime Green',            hex = '#66b81f' },
    { id = 82,   family = 'matte',    label = 'Dark Blue',             hex = '#1f2852' },
    { id = 83,   family = 'matte',    label = 'Blue',                  hex = '#253aa7' },
    { id = 84,   family = 'matte',    label = 'Midnight Blue',         hex = '#1c3551' },
    { id = 128,  family = 'matte',    label = 'Green',                 hex = '#4e6443' },
    { id = 129,  family = 'matte',    label = 'Brown',                 hex = '#bcac8f' },
    { id = 131,  family = 'matte',    label = 'White',                 hex = '#fcf9f1' },
    { id = 133,  family = 'matte',    label = 'Olive Army Green',      hex = '#81844c' },
    { id = 148,  family = 'matte',    label = 'Purple',                hex = '#6b1f7b' },
    { id = 149,  family = 'matte',    label = 'Dark Purple',           hex = '#1e1d22' },
    { id = 151,  family = 'matte',    label = 'Forest Green',          hex = '#2d362a' },
    { id = 152,  family = 'matte',    label = 'Olive Drab',            hex = '#696748' },
    { id = 153,  family = 'matte',    label = 'Desert Brown',          hex = '#7a6c55' },
    { id = 154,  family = 'matte',    label = 'Desert Tan',            hex = '#c3b492' },
    { id = 155,  family = 'matte',    label = 'Foliage Green',         hex = '#5a6352' },

    -- Metals & Chrome
    { id = 117,  family = 'metals',   label = 'Brushed Steel',         hex = '#6a747c', shaded = true },
    { id = 118,  family = 'metals',   label = 'Brushed Black Steel',   hex = '#354158', shaded = true },
    { id = 119,  family = 'metals',   label = 'Brushed Aluminium',     hex = '#9ba0a8', shaded = true },
    { id = 120,  family = 'metals',   label = 'Chrome',                hex = '#5870a1', shaded = true },
    { id = 158,  family = 'metals',   label = 'Pure Gold',             hex = '#c9a227', shaded = true },
    { id = 159,  family = 'metals',   label = 'Brushed Gold',          hex = '#a08a55', shaded = true },

    -- Utility
    { id = 15,   family = 'utility',  label = 'Black',                 hex = '#151921' },
    { id = 16,   family = 'utility',  label = 'Black Poly',            hex = '#1e2429' },
    { id = 17,   family = 'utility',  label = 'Dark Silver',           hex = '#333a3c' },
    { id = 18,   family = 'utility',  label = 'Silver',                hex = '#8c9095' },
    { id = 19,   family = 'utility',  label = 'Gun Metal',             hex = '#39434d' },
    { id = 20,   family = 'utility',  label = 'Shadow Silver',         hex = '#506272' },
    { id = 43,   family = 'utility',  label = 'Red',                   hex = '#9c1016' },
    { id = 44,   family = 'utility',  label = 'Bright Red',            hex = '#de0f18' },
    { id = 56,   family = 'utility',  label = 'Dark Green',            hex = '#22383e' },
    { id = 57,   family = 'utility',  label = 'Green',                 hex = '#1d5a3f' },
    { id = 75,   family = 'utility',  label = 'Dark Blue',             hex = '#112552' },
    { id = 76,   family = 'utility',  label = 'Midnight Blue',         hex = '#1b203e' },
    { id = 77,   family = 'utility',  label = 'Blue',                  hex = '#275190' },
    { id = 78,   family = 'utility',  label = 'Sea Foam Blue',         hex = '#608592' },
    { id = 79,   family = 'utility',  label = 'Lightning Blue',        hex = '#2446a8' },
    { id = 80,   family = 'utility',  label = 'Maui Blue Poly',        hex = '#4271e1' },
    { id = 81,   family = 'utility',  label = 'Bright Blue',           hex = '#3b39e0' },
    { id = 108,  family = 'utility',  label = 'Brown',                 hex = '#3a2a1b' },
    { id = 109,  family = 'utility',  label = 'Medium Brown',          hex = '#785f33' },
    { id = 110,  family = 'utility',  label = 'Light Brown',           hex = '#b5a079' },
    { id = 122,  family = 'utility',  label = 'Off White',             hex = '#dfddd0' },

    -- Worn
    { id = 21,   family = 'worn',     label = 'Black',                 hex = '#1e232f' },
    { id = 22,   family = 'worn',     label = 'Graphite',              hex = '#363a3f' },
    { id = 23,   family = 'worn',     label = 'Silver Grey',           hex = '#a0a199' },
    { id = 24,   family = 'worn',     label = 'Silver',                hex = '#d3d3d3' },
    { id = 25,   family = 'worn',     label = 'Blue Silver',           hex = '#b7bfca' },
    { id = 26,   family = 'worn',     label = 'Shadow Silver',         hex = '#778794' },
    { id = 46,   family = 'worn',     label = 'Red',                   hex = '#a94744' },
    { id = 47,   family = 'worn',     label = 'Golden Red',            hex = '#b16c51' },
    { id = 48,   family = 'worn',     label = 'Dark Red',              hex = '#371c25' },
    { id = 58,   family = 'worn',     label = 'Dark Green',            hex = '#2d423f' },
    { id = 59,   family = 'worn',     label = 'Green',                 hex = '#45594b' },
    { id = 60,   family = 'worn',     label = 'Sea Wash',              hex = '#65867f' },
    { id = 85,   family = 'worn',     label = 'Dark Blue',             hex = '#4c5f81' },
    { id = 86,   family = 'worn',     label = 'Blue',                  hex = '#58688e' },
    { id = 87,   family = 'worn',     label = 'Light Blue',            hex = '#74b5d8' },
    { id = 113,  family = 'worn',     label = 'Honey Beige',           hex = '#b0ab94' },
    { id = 114,  family = 'worn',     label = 'Brown',                 hex = '#453831' },
    { id = 115,  family = 'worn',     label = 'Dark Brown',            hex = '#2a282b' },
    { id = 116,  family = 'worn',     label = 'Straw Beige',           hex = '#726c57' },
    { id = 121,  family = 'worn',     label = 'Off White',             hex = '#eae6de' },
    { id = 123,  family = 'worn',     label = 'Orange',                hex = '#f2ad2e' },
    { id = 124,  family = 'worn',     label = 'Light Orange',          hex = '#f9a458' },
    { id = 126,  family = 'worn',     label = 'Taxi Yellow',           hex = '#f1cc40' },
    { id = 130,  family = 'worn',     label = 'Pale Orange',           hex = '#f8b658' },
    { id = 132,  family = 'worn',     label = 'White',                 hex = '#fffffb' },
}

Paint.ById = {}

for _, colour in ipairs(Paint.Colours) do
    Paint.ById[colour.id] = colour
end

function Paint.Get(id)
    return Paint.ById[tonumber(id) or -1]
end

--[[ The palette a shop offers.

     Config takes things out and puts things in: hidden drops an index,
     extra adds one. Extras are how an add-on paint pack, or the chameleon
     paints on a server that streams them, reach the picker without this file
     pretending to know indices that depend on the server's build. ]]
function Paint.Sheet()
    local hidden = {}

    for _, id in ipairs(Config.Paint and Config.Paint.hidden or {}) do
        hidden[tonumber(id) or -1] = true
    end

    local allowRestricted = Config.Paint and Config.Paint.allowRestricted == true

    local families, byId = {}, {}

    local function family(id, label)
        if byId[id] then return byId[id] end

        local entry = { id = id, label = label or id, colours = {} }

        families[#families + 1] = entry
        byId[id] = entry

        return entry
    end

    for _, entry in ipairs(Paint.Families) do family(entry.id, entry.label) end

    for _, colour in ipairs(Paint.Colours) do
        if not hidden[colour.id] and (allowRestricted or not colour.restricted) then
            local into = byId[colour.family]

            if into then
                into.colours[#into.colours + 1] = {
                    id = colour.id, label = colour.label, hex = colour.hex, shaded = colour.shaded,
                }
            end
        end
    end

    for _, colour in ipairs(Config.Paint and Config.Paint.extra or {}) do
        local id = tonumber(colour.id)

        if id and not hidden[id] then
            -- `group`, not `id`. Naming it id shadowed the paint index, so an
            -- add-on colour went into the table with its family name where
            -- its index should be and never reached the car.
            local group = colour.family or 'addon'

            local into = family(group, group == 'addon'
                and (Config.Paint.extraLabel or 'Add-ons')
                or (group:sub(1, 1):upper() .. group:sub(2)))

            into.colours[#into.colours + 1] = {
                id = id,
                label = tostring(colour.label or ('Colour %d'):format(id)),
                hex = tostring(colour.hex or '#808080'),
                shaded = colour.shaded == true,
            }
        end
    end

    local out = {}

    for _, entry in ipairs(families) do
        if #entry.colours > 0 then out[#out + 1] = entry end
    end

    return out
end

-- Whether a shop will actually paint a car this colour. Asked on the server,
-- because a colour index is a number the panel sends and the panel is not the
-- thing that decides what the shop sells.
function Paint.Allowed(id)
    id = tonumber(id)
    if not id then return false end

    for _, hide in ipairs(Config.Paint and Config.Paint.hidden or {}) do
        if tonumber(hide) == id then return false end
    end

    for _, colour in ipairs(Config.Paint and Config.Paint.extra or {}) do
        if tonumber(colour.id) == id then return true end
    end

    local colour = Paint.ById[id]
    if not colour then return false end

    if colour.restricted and not (Config.Paint and Config.Paint.allowRestricted == true) then
        return false
    end

    return true
end
