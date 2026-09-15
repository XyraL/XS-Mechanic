Util = {}

function Util.Trim(s)
    if type(s) ~= 'string' then return '' end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- oxmysql follows the MySQL convention that TINYINT(1) IS a boolean, so a flag
-- column reads back as true/false, not 1/0. Every row decoder goes through
-- this, because `row.enabled == 1` is false for every row, forever, and the
-- in-memory copy hides it until the next restart.
function Util.Truthy(v)
    return v == true or v == 1 or v == '1'
end

function Util.Round(n, places)
    local mult = 10 ^ (places or 0)
    return math.floor((tonumber(n) or 0) * mult + 0.5) / mult
end

function Util.Clamp(n, low, high)
    n = tonumber(n) or low
    if n < low then return low end
    if n > high then return high end
    return n
end

function Util.Money(n)
    local whole = string.format('%d', math.floor(math.abs(tonumber(n) or 0)))
    local out = whole:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return ((tonumber(n) or 0) < 0 and '-$' or '$') .. out
end

function Util.Decode(raw, fallback)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return fallback end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or decoded == nil then return fallback end
    return decoded
end

-- A Lua vector3 serialises to null crossing into NUI, not {x,y,z}. Anything
-- heading for the panel goes through here first.
function Util.Plain(value, depth)
    depth = (depth or 0) + 1
    if depth > 12 then return nil end

    local kind = type(value)

    if kind == 'vector3' then
        return { x = value.x, y = value.y, z = value.z }
    elseif kind == 'vector4' then
        return { x = value.x, y = value.y, z = value.z, w = value.w }
    elseif kind ~= 'table' then
        return value
    end

    local out = {}
    for key, entry in pairs(value) do
        out[key] = Util.Plain(entry, depth)
    end
    return out
end

function Util.Distance(a, b)
    if not a or not b then return math.huge end
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

function Util.InList(list, value)
    for _, entry in ipairs(list or {}) do
        if entry == value then return true end
    end
    return false
end

function Util.Id(prefix)
    return ('%s_%s%s'):format(prefix or 'x', os.time(), math.random(1000, 9999))
end
