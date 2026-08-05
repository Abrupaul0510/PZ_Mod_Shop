ProjectShopeeJson = { _version = "1.0.0" }

local function encode_string(str)
    local escape_map = {
        ['\\'] = '\\\\',
        ['"'] = '\\"',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }
    return '"' .. str:gsub('[%z\1-\31\\"]', function(c)
        return escape_map[c] or string.format('\u%04x', c:byte())
    end) .. '"'
end

function ProjectShopeeJson.encode(val)
    local t = type(val)
    if t == "string" then
        return encode_string(val)
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "table" then
        local isArray = true
        local maxIdx = 0
        local count = 0
        
        for k, v in pairs(val) do
            if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                isArray = false
            end
            if type(k) == "number" and k > 0 then
                maxIdx = math.max(maxIdx, k)
            end
            count = count + 1
        end
        
        if count == 0 then
            return "{}"
        end
        
        if isArray and maxIdx == count then
            local parts = {}
            for i = 1, maxIdx do
                table.insert(parts, ProjectShopeeJson.encode(val[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(val) do
                table.insert(parts, encode_string(tostring(k)) .. ":" .. ProjectShopeeJson.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return encode_string(tostring(val))
    end
end

local function skip_whitespace(str, idx)
    while idx <= #str do
        local c = str:sub(idx, idx)
        if c == ' ' or c == '\t' or c == '\r' or c == '\n' then
            idx = idx + 1
        else
            break
        end
    end
    return idx
end

local function decode_string(str, idx)
    local res = ""
    idx = idx + 1
    while idx <= #str do
        local c = str:sub(idx, idx)
        if c == '"' then
            return res, idx + 1
        elseif c == '\\' then
            idx = idx + 1
            local esc = str:sub(idx, idx)
            if esc == '"' or esc == '\\' or esc == '/' then
                res = res .. esc
            elseif esc == 'b' then res = res .. '\b'
            elseif esc == 'f' then res = res .. '\f'
            elseif esc == 'n' then res = res .. '\n'
            elseif esc == 'r' then res = res .. '\r'
            elseif esc == 't' then res = res .. '\t'
            end
        else
            res = res .. c
        end
        idx = idx + 1
    end
    return res, idx
end

local function decode_value(str, idx)
    idx = skip_whitespace(str, idx)
    local c = str:sub(idx, idx)
    
    if c == '"' then
        return decode_string(str, idx)
    elseif c == '{' then
        local res = {}
        idx = skip_whitespace(str, idx + 1)
        if str:sub(idx, idx) == '}' then return res, idx + 1 end
        while idx <= #str do
            local key
            key, idx = decode_string(str, idx)
            idx = skip_whitespace(str, idx)
            if str:sub(idx, idx) == ':' then idx = idx + 1 end
            local val
            val, idx = decode_value(str, idx)
            res[key] = val
            idx = skip_whitespace(str, idx)
            if str:sub(idx, idx) == '}' then return res, idx + 1 end
            if str:sub(idx, idx) == ',' then idx = skip_whitespace(str, idx + 1) end
        end
        return res, idx
    elseif c == '[' then
        local res = {}
        idx = skip_whitespace(str, idx + 1)
        if str:sub(idx, idx) == ']' then return res, idx + 1 end
        local i = 1
        while idx <= #str do
            local val
            val, idx = decode_value(str, idx)
            res[i] = val
            i = i + 1
            idx = skip_whitespace(str, idx)
            if str:sub(idx, idx) == ']' then return res, idx + 1 end
            if str:sub(idx, idx) == ',' then idx = skip_whitespace(str, idx + 1) end
        end
        return res, idx
    elseif c:match('[%-%d]') then
        local s = idx
        while idx <= #str and str:sub(idx, idx):match('[%-%d%.eE%+]*') do
            if not str:sub(idx, idx):match('[%-%d%.eE%+]') then break end
            idx = idx + 1
        end
        return tonumber(str:sub(s, idx - 1)), idx
    elseif str:sub(idx, idx+3) == "true" then
        return true, idx + 4
    elseif str:sub(idx, idx+4) == "false" then
        return false, idx + 5
    elseif str:sub(idx, idx+3) == "null" then
        return nil, idx + 4
    end
    return nil, idx + 1
end

function ProjectShopeeJson.decode(str)
    local val, _ = decode_value(str, 1)
    return val
end
