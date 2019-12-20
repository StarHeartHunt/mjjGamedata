--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/21
-- Time: 13:11
-- 工具类
--

-- 日志打印级别
-- 3(ALL), 2(INFO, ERROR), 1(ERROR), 0(NONE)
local logLevel = logLevel

function space(n)
    local n = n or 1
    local ret = ""

    for i = 1, n - 1 do
        ret = ret .. "    "
    end

    return ret
end

function ptable(tb, n)
    if logLevel <= 1 then
        return ""
    end
    local n = n or 1
    if not tb or type(tb) ~= "table" then
        error("Argument not table.")
        return nil
    end

    local ret = "{"
    for k, v in pairs(tb) do
        ret = ret .."\n" .. space(n + 1) .. tostring(k) .. " = "
        if type(v) == "table" then
            ret = ret .. ptable(v, n + 2)
        else
            ret = ret .. tostring(v)
        end
        ret = ret .. ","
    end
    ret = ret .. "\n" .. space(n) .. "}"
    return ret
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--[[
-- 错误信息
--]]
function LOG_ERROR(fmt, ...)
    if logLevel < 1 then
        return nil
    end
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("ERROR[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    print(msg)
end

--[[
-- 重要信息
--]]
function LOG_INFO(fmt, ...)
    if logLevel < 2 then
        return nil
    end
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("INFO[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    print(msg)
end

--[[
-- 测试消息
--]]
function LOG_DEBUG(fmt, ...)
    if logLevel < 3 then
        return nil
    end
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("DEBUG[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    print(msg)
end

local epsilon = 0.00001
--[[
-- 保留整数部分
--]]
function int_part(d)
    if d <= 0 then
        return math.ceil(d)
    end
    if math.ceil(d) - d < epsilon then
        return math.ceil(d)
    else
        return math.ceil(d) - 1
    end
end

--[[
-- 两点之间的距离, 点为 x * 100 + y
--]]
function distance(a, b)
    if type(a) ~= "number" or type(b) ~= "number" then
        LOG_ERROR("distance parameter illegal, a %s and b %s.", a, b)
    end
    return int_part(math.abs(a / 100 - b / 100) + math.abs(a % 100 - b % 100))
end

local min = 1
local x_max = 9
local y_max = 6
function buildPosition(x, y)
    if x < min or y < min or x > x_max or y > y_max then
        return nil
    else
        return x * 100 + y
    end
end


local tb = {
    { -1, 0 },
    { 1, 0 },
    { 0, -1 },
    { 0, 1 }
}
--[[
-- 获取目标点周围的4个格子位置
--]]
function aroundPositions(position)
    if type(position) ~= "number" then
        LOG_ERROR("aroundPositions parameter illegal, position is %s.", position)
    end
    local x = int_part(position / 100)
    local y = int_part(position % 100)
    local ret = {}
    for _, v in pairs(tb) do
        local newPos = buildPosition(x + v[1], y + v[2])
        if newPos ~= nil then
            table.insert(ret, newPos)
        end
    end
    LOG_INFO("aroundPositions position[%s] and ret:%s", position, ptable(ret))
    return ret
end
--[[
--把list转换成table
--]]
function parseList(list)
    local data = {}
    if not list or not list.Count then
        LOG_ERROR("parseList argument illegal, list nil is %s.", list == nil)
        return data
    end
    if list.Count == 0 then
        LOG_INFO("parseList received data is empty.")
        return data
    end
    for index = 0, list.Count - 1 do
        table.insert(data, list[index])
    end
    LOG_INFO("parseList list count[%s] and data info:%s.", list.Count, ptable(data))
    return data
end
--[[
-- 把list转换为map
-- @param list
-- @param key key为nil时本身作为key, value
--]]
function parseMap(list, key)
    local map = {}
    if not list or not list.Count then
        LOG_ERROR("parseMap argument illegal, list nil is %s.", list == nil)
        return map
    end
    if list.Count == 0 then
        LOG_INFO("parseMap received data is empty.")
        return map
    end
    for index = 0, list.Count - 1 do
        local v = list[index]
        if key == nil then
            map[v] = v
        else
            local k = v[key]
            if not k then
                LOG_ERROR("parseMap key[%s] data[%s] without this field.", key, type(v) == "table" and ptable(v) or v)
            else
                map[k] = v
            end
        end
    end
    LOG_INFO("parseMap list count[%s], key[%s] and map info:%s.", list.Count, key, ptable(map))
    return map
end

