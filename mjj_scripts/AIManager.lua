--
-- Created by IntelliJ IDEA.
-- User: Aresu
-- Date: 2017/5/25
-- Time: 20:04
-- AI Interface Manager.
--

AIManager = {}

function AIManager.new()
    local self = {}
    return setmetatable(self, { __index = AIManager })
end

--[[
-- 返回给Client的消息结构
-- {
--      aiBehaviorData = {
--          isStandby,       -- 是否待机(必选项)
--          skillId,         -- 使用的技能ID(可选项)
--          skillPos,        -- 技能释放点(方向)(可选项)
--          movePath,        -- 移动路径(可选项)
--          releaskUltimateUid,     -- 释放大招的角色UID(可选项)
--      }
-- }
--]]

--[[
-- 构造待机返回结果
-- @param uid 角色uid
-- @param targetUid 移动的目标(可选项)
-- @param path 移动路径(可选项)
--]]
function AIManager:buildStandby(uid, targetUid, path)
    local path = path
    if not path and not targetUid then
        path = {}
    else
        path = path or self:getPath2Target(uid, targetUid, true)
    end
    self:PathFilter(uid, path)
    local data = {
        isStandby = true,
        movePath = path
    }
    LOG_INFO("uid[%s] buildStandby info:%s.", uid, ptable(data))
    return { aiBehaviorData = data }
end

--[[
-- 构造攻击返回结果
-- @param uid 角色uid
-- @skillId 使用的技能
-- @param info 攻击信息
-- @path 路径(可选项, path为nil时根据info中的位置计算)
--]]
function AIManager:buildAttack(uid, skillId, info)
    local data = {
        skillId = skillId,
        skillPos = info.skillPos,
        isStandby = false,
        movePath = info.path or self:getPath2Position(uid, info.position, true)
    }
    LOG_INFO("uid[%s] buildAttack info:%s.", uid, ptable(data))
    return { aiBehaviorData = data }
end

--[[
-- 构造大招消息
-- @param uid 施放大招的角色UID, 参数为nil是不释放大招
--]]
function AIManager:buildUltimate(uid)
    LOG_INFO("uid[%s] build ultimate message.", uid)
    if type(uid) ~= "number" then
        LOG_ERROR("uid[%s] build ultimate message, uid invalid.", uid)
        uid = nil
    end
    local aiData = {
        isStandby = true
    }

    if uid then
        aiData.isStandby = false
        aiData.releaskUltimateUid = uid
    end
    LOG_INFO("uid[%s] build ultimate info:%s.", uid, ptable(aiData))
    return { aiBehaviorData = aiData }
end

--[[
-- 获取玩家位置
-- @return 角色位置(目前角色只占一格, 返回值为数字)
--]]
function AIManager:getPlayerPosition(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetPlayerItemPos(uid)
end

--[[
--获取棋子所在位置
--返回值为数组, 存在多格BOSS
--]]
function AIManager:getPosition(uid)
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetItemPos(uid))
end

--[[
-- 获取玩家uid列表
--]]
function AIManager:getPlayers()
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetWarChessPiecesPlayerItemUidList())
end

--[[
-- 获取怪物uid列表
--]]
function AIManager:getMonsters()
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetWarChessPiecesOpponentItemUidList())
end

--[[
-- 获取 buff uid列表
--]]
function AIManager:getBuffsList()
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetWarChessBuffUidList())
end

--[[
-- 获取BUFF map
-- 无参为获取所有buff列表
-- buff 基本信息
-- {
-- 		uid,
--		position, -- 位置
--		type,	  -- 1 有害, 0 有益
-- }
-- map key为buff做在位置
--]]
function AIManager:getBuffsMap()
    local uids = AiLogic.aiLuaCallCSharpInterface:GetWarChessBuffUidList()
    local map = {}
    for i = 0, uids.Count - 1 do
        local uid = uids[i]
        local positions = self:GetItemPos(uid)
        local position = positions[1]
        local type = self:GetBuffEffectType(uid)
        map[position] = {
            uid = uid,
            position = position,
            type = type
        }
    end
    LOG_DEBUG("getBuffsMap info:%s", ptable(map))
    return map
end

--[[
-- 判断指定 uid 是否是BOSS
--]]
function AIManager:isBoss(uid)
    return AiLogic.aiLuaCallCSharpInterface:IsBoss(uid)
end

--[[
-- 判断指定目标是否是玩家
--]]
function AIManager:isPlayer(uid)
    local uids = self:getPlayers()
    for _, v in pairs(uids) do
        if v == uid then
            return true
        end
    end
    return false
end

--[[
-- 判断指定目标是否是怪物
--]]
function AIManager:isMonster(uid)
    local uids = self:getMonsters()
    for _, v in pairs(uids) do
        if v == uid then
            return true
        end
    end
    return false
end

--[[
-- 是否可以释放主动技能
-- 普攻没有CD
--]]
function AIManager:isCanReleaseSkill(uid)
    return AiLogic.aiLuaCallCSharpInterface:IsCanReleaseSkill(uid)
end

--[[
-- 存在BOSS
--]]
function AIManager:haveBoss()
    for _, uid in pairs(self:getMonsters()) do
        if self:isBoss(uid) == true then
            return true
        end
    end
    return false
end

--[[
-- 获取指定点周围的目标
-- @param position
-- @param 参考TargetType, 其他值默认全部目标
-- return uid 集合
--]]
function AIManager:getAroundTargetByPosition(position, targetType)
    LOG_INFO("getAroundTargetByPosition position[%s] and targetType[%s].", position, targetType)
    local positions = aroundPositions(position)
    local ret = {}
    for _, v in pairs(positions) do
        local uid = AiLogic.aiLuaCallCSharpInterface:GetUidByPos(v)
        if uid then
            LOG_DEBUG("GetTargetsAroundByPosition position[%s] uid[%s].", v, uid)
            if (targetType == TargetType.Player and self:isPlayer(uid) == true)
                    or (targetType == TargetType.Monster and self:isMonster(uid) == true)
                    or (targetType ~= TargetType.Player and targetType ~= TargetType.Monster) then
                table.insert(ret, uid)
            end
        else
            LOG_ERROR("getAroundTargetByPosition, position[%s], nearby[%s] traget is %s.", position, v, uid)
        end
    end
    LOG_INFO("getAroundTargetByPosition position[%s], targetType[%s] and info:%s", position, targetType, ptable(ret))
    return ret
end

--[[
-- 获取场上是否有与技能相同的持续回合effect
--]]
function AIManager:isEffectInScene(skillId)
    return AiLogic.aiLuaCallCSharpInterface:GetIsEffectInScene(skillId)
end

--[[
-- 获取buff类型
-- @return 0(有益buff) 1(有害buff)
--]]
function AIManager:GetBuffEffectType(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetBuffEffectType(uid)
end

--[[
-- 获取距离最近的目标的位置position
--]]
function AIManager:getTargetPositionByDistance(uid, uids)
    return AiLogic.aiLuaCallCSharpInterface:GetTargetPositionByDistance(uid, uids)
end

--[[
-- 获取距离最近的目标的uid
--]]
function AIManager:getTargetUidByDistance(uid, uids)
    return AiLogic.aiLuaCallCSharpInterface:GetTargetUidByDistance(uid, uids)
end

--[[
-- 获取棋子移动步数
--]]
function AIManager:getStepNum(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetItemStepNum(uid)
end

--[[
-- 获取普攻技能ID
--]]
function AIManager:getCommonSkill(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetAttackSkillId(uid)
end

--[[
-- 获取主动技能ID
--]]
function AIManager:getActiveSkill(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetSingleSkillId(uid)
end

--[[
-- 获取角色可以到达的所有点
-- @return table
--]]
function AIManager:getPlayerAccessiblePositions(uid)
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetPlayerCanArraveAreaList(uid))
end

--[[
-- 获取角色可以到达的所有点的map
-- @return map key为点
--]]
function AIManager:getPlayerAccessibleMap(uid)
    return parseMap(AiLogic.aiLuaCallCSharpInterface:GetPlayerCanArraveAreaList(uid))
end

--[[
-- 获取预警技作用map
-- @return map key position
--]]
function AIManager:getAlertMap()
    return parseMap(AiLogic.aiLuaCallCSharpInterface:GetBossArertPosList())
end

--[[
-- 玩家或者怪物周围的格子索引map
-- @return map key position
--]]
function AIManager:getNearItemPosByUids(uids)
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetNearItemPosByUids(uids))
end

--[[
-- 获取怪物周围的玩家uid集合
-- @param uid 怪物uid
--]]
function AIManager:getMonsterAroundPlayer(uid)
    return parseList(AiLogic.aiLuaCallCSharpInterface:GetPlayerUidsRoundOpponent(uid))
end

--[[
-- 获取指定目标的属性
-- @param uids uid集合
-- @return map
-- key -> uid
-- value -> userdata
-- {
--      hp,     -- 血量
--      totalHP, -- 血上限
--      attribute, -- 属性
--      positions -- 位置数组, 多格目标占多格
-- }
--]]
function AIManager:getProperties(uids, ...)
    -- 初始化目标ID集合
    local total = {}
    local others = { ... }

    for _, id in pairs(uids or {}) do
        table.insert(total, id)
    end
    for _, id in pairs(others) do
        table.insert(total, id)
    end
    LOG_INFO("getProperties uids:%s", ptable(total))

    -- 获取属性
    local map = {}
    local list = AiLogic.aiLuaCallCSharpInterface:GetItemAttributeInfo(total)
    for i = 0, list.Count - 1 do
        local temp = list[i]
        local data = {
            hp = temp.hp,
            totalHP = temp.totalHP,
            attribute = temp.attribute,
            positions = parseList(temp.positions)
        }
        map[temp.uid] = data
    end
    LOG_INFO("getProperties map:%s.", ptable(map))
    return map
end

--[[
-- 源属性是否克制目标属性
-- @return true 克制 false 不克制
--]]
function AIManager:isAttributeInhibit(sourceAttribute, targetAttribute)
    -- 获取克制属性
    local attribute = AttributeInhibit[sourceAttribute]
    if not attribute then
        LOG_ERROR("isAttributeInhibit attribute %s data is nil.", sourceAttribute)
        return false
    end
    return attribute == targetAttribute
end

--[[
-- 源属性与目标属性的关系
-- @return 1 克制, -1 被克, 0 无光
--]]
function AIManager:attributeInterrelation(sourceAttribute, targetAttribute)
    if sourceAttribute == -1 or targetAttribute == -1 then
        LOG_ERROR("attributeInterrelation attribute[-1] invalid.")
    end
    if self:isAttributeInhibit(sourceAttribute, targetAttribute) == true then
        return 1
    elseif self:isAttributeInhibit(targetAttribute, sourceAttribute) == true then
        return -1
    else
        return 0
    end
end

--[[
-- 获取buff类型
-- @return 0 (有益), 1(有害)
--]]
function AIManager:getBuffType(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetBuffEffectType(uid)
end

--[[
-- 获取 BUFF map (目前无多格BUFF, buff位置作为key)
-- @param filterType 1(选择有害buff) 0(选择有益buff) nil(全部)
-- userdata
-- {
--      uid, -- buff uid
--      position, -- 位置
--      type	  -- 1 有害, 0 有益
-- }
--]]
function AIManager:getBuffs(filterType)
    local buffUids = AiLogic.aiLuaCallCSharpInterface:GetWarChessBuffUidList()
    local map = {}
    for i = 0, buffUids.Count - 1 do
        local uid = buffUids[i]
        local positions = self:getPosition(uid)
        if #positions ~= 1 then
            LOG_ERROR("getBuffs buff[%s] positions error, positions info:%s.", uid, ptable(positions))
        end
        local position = positions[1]
        local type = self:getBuffType(uid)
        if not filterType or filterType == type then
            map[position] = {
                uid = uid,
                position = position,
                type = type
            }
        end
    end
    LOG_INFO("getBuffs info:%s", ptable(map))
    return map
end

function AIManager:havePlayerInPos(pos)
	local uids = self:getPlayers()
    for _, v in pairs(uids) do
        local postions = self:getPosition(v)
		for _, k in pairs(postions) do
			if(k == pos) then
				return true
			end
		end
    end
	return false;
end

function AIManager:haveMonsterInPos(pos)
	local uids = self:getMonsters()
    for _, v in pairs(uids) do
        local postions = self:getPosition(v)
		for _, k in pairs(postions) do
			if(k == pos) then
				return true
			end
		end
    end
	return false;
end

--[[
-- 角色根据所选技能以及可到达区域获取每个位置可以攻击的目标信息
--
-- @param uid 角色uid
-- @param skillId 技能ID
-- @param positions 可达区域
-- @return table
-- userdata {
--      position,   -- 可达区域中的某个点
--      skillPos,   -- 技能释放参数(释放点)
--      targetNum,  -- 目标人数
--      targetUids, -- 目标uid集合
--      path,       -- 路径
--      step       -- 距离
-- }
--]]
function AIManager:getSkillAttackInfoByPosition(uid, skillId, positions)
    LOG_INFO("uid[%s] getSkillAttackInfoByPosition skill[%s] and positions:%s.", uid, skillId, ptable(positions))
    local list = AiLogic.aiLuaCallCSharpInterface:GetSkillAttackResultListByPositions(uid, positions, skillId)
    local attackInfos = {}
	
	

    -- C# 返回的结果从0可是, 且无法使用pairs遍历
    for i = 0, list.Count - 1 do
        local data = list[i]
		local playerPos = self:getPlayerPosition(uid)		
		local targetUids = parseList(data.skillAttackItemUidList)
		local path = self:getPath2Position(uid, data.position, true)
		LOG_INFO("jdd**playerPos[%s] path[%s] data.skillPos[%s] ", playerPos,ptable(path), data.skillPos)
		if(playerPos == data.skillPos) then
			if #targetUids > 0 then
				local tmpSkillPos = playerPos
				if(#path > 0) then
					tmpSkillPos = path[#path]
				end
				local attackInfo = {
					path = path,
					step = #path,
					position = data.position,
					skillPos = tmpSkillPos,
					targetNum = #targetUids,
					targetUids = targetUids
				}
				table.insert(attackInfos, attackInfo)
				
			else
				LOG_ERROR("uid[%s] getSkillAttackInfoByPosition skill[%s], position[%s] target is nil.", uid, skillId, data.position)
			end
			
		else
			if #targetUids > 0 then
				local attackInfo = {
					path = path,
					step = #path,
					position = data.position,
					skillPos = data.skillPos,
					targetNum = #targetUids,
					targetUids = targetUids
				}
				table.insert(attackInfos, attackInfo)
			else
				LOG_ERROR("uid[%s] getSkillAttackInfoByPosition skill[%s], position[%s] target is nil.", uid, skillId, data.position)
			end
		end
    end

    LOG_INFO("uid[%s] getSkillAttackInfoByPosition skill[%s] attack info:%s.", uid, skillId, ptable(attackInfos))
    return attackInfos
end
--这个函数会返回所有技能可以释放的点，即使打不到人
function AIManager:getAllSkillAttackResult(uid, pos, skillId)
    local list = AiLogic.aiLuaCallCSharpInterface:GetAllSkillAttackResult(uid, pos, skillId)
    local attackInfos = {}
	
    -- C# 返回的结果从0可是, 且无法使用pairs遍历
    for i = 0, list.Count - 1 do
        local data = list[i]
		LOG_INFO("getAllSkillAttackResult data:%s ", data)
		LOG_INFO("getAllSkillAttackResult data.skillAttackItemUidLis:%s ", data.skillAttackItemUidLis)
        local targetUids = {}
		
		if not data.skillAttackItemUidLis or not data.skillAttackItemUidLis.Count then
		else
			targetUids = parseList(data.skillAttackItemUidLis)
		end
		LOG_INFO("getAllSkillAttackResult targetUids:%s ", targetUids)
		attackInfos[data.skillPos] = targetUids or {}
    end
    LOG_INFO("getAllSkillAttackResult uid[%s] getSkillAttackInfoByPosition skill[%s] attack info:%s.", uid, skillId, ptable(attackInfos))
    return attackInfos
end

--[[
-- 获取角色可达的安全区域
-- @param uid 角色uid
-- @param positions 可达区域(可选项, uid为nil时必须提供改参数)
-- @param alertMap  预警技覆盖区域map(可选项)
--]]
function AIManager:getSafeArea(uid, positions, alertMap)
    if not uid and not positions then
        LOG_ERROR("getSafeArea uid and positions is nil.")
        return {}
    end

    local ret = {}
    local positions = positions or self:getPlayerAccessiblePositions(uid)
    local alertMap = alertMap or self:getAlertMap()
    for _, position in pairs(positions) do
        if alertMap[position] == nil then
            table.insert(ret, position)
        end
    end
    return ret
end

--[[
-- 获取源点到目标点的路径
-- @param ignoreDestination 是否忽略目标点
--]]
function AIManager:getPath(sourcePosition, targetPosition, ignoreDestination)
    LOG_INFO("getPath source[%s], target[%s] and ignore[%s].", sourcePosition, targetPosition, ignoreDestination)
    local path = parseList(AiLogic.aiLuaCallCSharpInterface:GetNormalPath(sourcePosition, targetPosition))
    if ignoreDestination == true and #path > 1 then
        table.remove(path, #path)
    end
    LOG_INFO("getPath source[%s], target[%s], ignore[%s] and path: %s.", sourcePosition, targetPosition, ignoreDestination, ptable(path))
    return path
end

--[[
-- 获取源目标到达目标集合的路径(主要用来计算距离)
-- @return map
-- key -> targetUid
-- value -> userdata
-- {
--      sourceUid, -- 源目标
--      targetUid,
--      path   -- 路径
-- }
--]]
function AIManager:getPath2Targets(uid, targetUids)
    LOG_INFO("getPath2Targets uid[%s] and targetUids info:%s.", uid, ptable(targetUids))
    local list = AiLogic.aiLuaCallCSharpInterface:GetItemPath(uid, targetUids)
    local map = {}
    for i = 0, list.Count - 1 do
        local temp = list[i]
        local path = parseList(temp.path) or {}
        local data = {
            sourceUid = temp.sourceUid,
            targetUid = temp.targetUid,
            path = path
        }
        map[temp.targetUid] = data
    end
    return map
end

--[[
-- 路径评分
--]]
function AIManager:pathEvaluate(buffs, path)
    local evaluate = 0
    for _, pos in pairs(path) do
        local buff = buffs[pos]
        if buff and buff.type == 0 then
            evaluate = evaluate + 1
        elseif buff and buff.type == 1 then
            evaluate = evaluate - 1
        end
    end
    return evaluate
end

--[[
-- 获取到指定目标的路径
-- @uid
-- @targetUid 指定目标
-- @optimization 路径优化
--]]
function AIManager:getPath2Target(uid, targetUid, optimization)
    LOG_INFO("getPath2Target uid[%s], targetUid[%s] and optimization[%s].", uid, targetUid, optimization)
    local ret = AiLogic.aiLuaCallCSharpInterface:GetItemPath(uid, { targetUid })
    local path
    if ret.Count ~= 1 then
        LOG_INFO("getPath2Target uid[%s] and target[%s] path error, ret count is %s..", uid, targetUid, ret.Count)
        path = {}
    else
        path = parseList(ret[ret.Count - 1].path)
    end
    LOG_INFO("getPath2Target uid[%s], targetUid[%s] and optimization[%s] and path info:%s.", uid, targetUid, optimization, ptable(path))

    -- 不优化
    if #path < 2 or optimization ~= true then
        return path
    end

    -- 有益BUFF
    local buffs = self:getBuffs(0)
    if not next(buffs) then
        return path
    end

    -- 所有BUFF
    local allBuffs = self:getBuffs()
    local minCost = #path   -- 保存路径数量
    local value = self:pathEvaluate(allBuffs, path) -- 计算luxian价值

    -- 遍历获取buff路线
    local arriveMap = self:getPlayerAccessibleMap(uid) -- 玩家可达的所有点
    for _, buff in pairs(buffs) do
        local buffPos = buff.position
        if arriveMap[buffPos] ~= nil then -- BUFF可达
            local buffUid = buff.uid
            local p1 = self:getPath2Target(uid, buffUid)
            LOG_INFO("p1 ~~~~~~~~~~~~~~~~ %s", ptable(p1))
            local p2 = self:getPath2Target(buffUid, targetUid)
            LOG_INFO("p1 ~~~~~~~~~~~~~~~~ %s", ptable(p2))
            if next(p1) and next(p2) and (#p1 + #p2 == minCost + 1) then -- BUFF可达, 并且两者距离相等才优化, BUFF路线不可能比最短路线短
                -- 合并线路
                for _, v in pairs(p2) do
                    table.insert(p1, v)
                end

                local newValue = self:pathEvaluate(buffs, p1)
                if newValue > value then
                    value = newValue
                    path = p1
                end
            end
        end
    end

    LOG_INFO("getPath2Target uid[%s], targetUid[%s] and optimization[%s] and path info:%s.", uid, targetUid, optimization, ptable(path))
    return path
end

--[[
-- 获取到指定点的路径
-- @uid
-- @position 目标点
-- @optimization 路径优化
--]]
function AIManager:getPath2Position(uid, position, optimization)
    LOG_INFO("getPath2Target uid[%s], position[%s] and optimization[%s].", uid, position, optimization)
    local pos = self:getPlayerPosition(uid)
    local path = parseList(AiLogic.aiLuaCallCSharpInterface:GetNormalPath(pos, position))
    LOG_INFO("getPath2Target uid[%s], position[%s] and optimization[%s] and path info:%s.", uid, position, optimization, ptable(path))

    -- 不优化
    if #path < 2 or optimization ~= true then
        return path
    end

    -- 有益BUFF
    --[[local buffs = self:getBuffs(0)
    if not next(buffs) then
        return path
    end

    -- 所有BUFF
    local allBuffs = self:getBuffs()
    local minCost = #path   -- 保存路径数量
    local value = self:pathEvaluate(allBuffs, path) -- 计算luxian价值

    -- 遍历获取buff路线
    local arriveMap = self:getPlayerAccessibleMap(uid) -- 玩家可达的所有点
    for _, buff in pairs(buffs) do
        local buffPos = buff.position
        if arriveMap[buffPos] ~= nil and distance(pos, buffPos) + distance(buffPos, position) <= minCost then -- 理论距离不大于最少步数才计算路径
            -- 目前只检测一个有益BUFF, 不递归检测所有BUFF连接线路
            local p1 = self:getPath(pos, buffPos)
            LOG_INFO("p1 ~~~~~~~~~~~~~~~~ %s", ptable(p1))
            local p2 = self:getPath(buffPos, position)
            LOG_INFO("p2 ~~~~~~~~~~~~~~~~ %s", ptable(p2))
            if next(p1) and next(p2) and (#p1 + #p2 == minCost) then -- BUFF可达, 并且两者距离相等才优化, BUFF路线不可能比最短路线短
                -- 合并线路
                for _, v in pairs(p2) do
                    table.insert(p1, v)
                end

                local newValue = self:pathEvaluate(buffs, p1)
                if newValue > value then
                    value = newValue
                    path = p1
                end
            end
        end
    end--]]

    LOG_INFO("getPath2Target uid[%s], position[%s] and optimization[%s] and path info:%s.", uid, position, optimization, ptable(path))
    return path
end

--[[
-- 攻击, 逃跑选择
-- @param uid
-- @param attackInfo {@see getSkillAttackInfoByPosition userdata}
-- @param alertMap 预警技区域(可选)
-- @param positions 角色可达区域(可选)
-- @return true, new attackInfos(attack) or false, safeArea(runaway)
--]]
function AIManager:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
    local alertMap = alertMap or self:getAlertMap()

    local safety = {}
    local danger = {}
    for _, attackInfo in pairs(attackInfos) do
        if alertMap[attackInfo.position] == nil then
            table.insert(safety, attackInfo)
        else
            table.insert(danger, attackInfo)
        end
    end

    -- 安全直接返回
    if next(safety) then
        return true, safety
    end

    -- 获取安全区域
    local safeArea = {}
    local positions = positions or self:getPlayerAccessiblePositions(uid)
    for _, position in pairs(positions) do
        if alertMap[position] == nil then
            table.insert(safeArea, position)
        end
    end

    -- 优先逃跑, 次级攻击
    if not next(safeArea) then
        return true, danger
    else
        return false, safeArea
    end
end

--[[
-- 普攻策略
-- @param uid 角色uid
-- @param positions 角色可到达的所有点(可选项)
--]]
function AIManager:doCommonAttack(uid, positions)
    local skillId = self:getCommonSkill(uid)
    local positions = positions or self:getPlayerAccessiblePositions(uid)
    local attackInfos = self:getSkillAttackInfoByPosition(uid, skillId, positions)

    local step = self:getStepNum(uid) -- 移动步数
    local alertMap = self:getAlertMap()
	LOG_INFO("AIManager:doCommonAttack attackInfos:%s.", ptable(attackInfos))
    if not next(attackInfos) then -- standby
        return self:doStandby(uid, alertMap)
    end

    -- 选择攻击或者逃跑
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
    if ok == true then
        attackInfos = ret
    else
        return self:doAlertRunaway(uid, alertMap, ret)
    end
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理目标相邻友方单位
    attackInfos = self:handleNearbyMember(attackInfos)
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理属性克制
    attackInfos = self:handleProperty(uid, attackInfos)
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理路径BUFF
    attackInfos = self:handleBuff(attackInfos)
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos)
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    return self:buildAttack(uid, skillId, attackInfos[index])
end

--[[
-- 待机策略
-- @param uid 角色 uid
-- @param alertMap 预警范围map(可选)
--]]
function AIManager:doStandby(uid, alertMap)
    local alertMap = alertMap or self:getAlertMap()
    local step = self:getStepNum(uid)
    -- 无法攻击到目标, 并且无预警时
    -- 移动步数大于2时执行靠近怪物策略
    -- 移动步数不大于2时随机(30%靠近怪物, %70原地待机)
    if not next(alertMap) and ((step > 2) or (math.random(1, 100000) > 70000)) then
        return self:doApproachMonster(uid, nil, step)
    end

    -- 逃离预警技
    return self:doAlertRunaway(uid, alertMap, nil)
end

--[[
-- 靠近怪物策略
-- @param uid 角色uid
-- @param monsters 怪物uid集合(可选项)
-- @param step 角色移动步数(可选项)
--]]
function AIManager:doApproachMonster(uid, monsters, step)
    if not uid then
        LOG_ERROR("doApproachMonster uid is invalid.")
        return nil
    end

    local monsters = monsters or self:getMonsters()
    if not next(monsters) then
        LOG_ERROR("uid[%s] doApproachMonster monsters invalid.",uid)
        return self:buildStandby(uid)
    elseif #monsters == 1 then
        return self:buildStandby(uid, monsters[1])
    end

    -- build move userdata
    local moveInfos = {}
    local step = step or self:getStepNum(uid)
    for _, targetUid in pairs(monsters) do
        local path = self:getPath2Target(uid, targetUid, true)
        if path and #path > 0 then -- 向怪物移动时, 无路径时不包含在选择范围内
            local totalStep = #path -- 总距离
            while #path > step do -- 清理多余步数, 计算路径BUFF是不考虑不走的格子
                table.remove(path, #path)
            end
            local moveInfo = {
                path = path,
                step = totalStep,
                targetUids = { targetUid }
            }
            table.insert(moveInfos, moveInfo)
        end
    end

    -- 构建待机返回
    local function build(moveInfo)
        LOG_INFO("doApproachMonster choice moveinfo:%s.", ptable(moveInfo))
        local path = moveInfo.path
        local targetUid = moveInfo.targetUids[1]
        return self:buildStandby(uid, targetUid, path)
    end

    if not next(moveInfos) then
        LOG_ERROR("uid[%s] doApproachMonster monsters invalid.",uid)
        return self:buildStandby(uid)
    elseif #moveInfos == 1 then
        return build(moveInfos[1])
    end

    -- 处理属性克制
    moveInfos = self:handleProperty(uid, moveInfos)
    if #moveInfos == 1 then
        return build(moveInfos[1])
    end

    -- 处理路径BUFF
    moveInfos = self:handleBuff(moveInfos)
    if #moveInfos == 1 then
        return build(moveInfos[1])
    end

    -- 处理距离
    moveInfos = self:handleDistance(moveInfos)
    if #moveInfos == 1 then
        return build(moveInfos[1])
    end

    -- 处理血量
    moveInfos = self:handleHp(moveInfos)
    local index = 1
    if #moveInfos ~= 1 then
        index = math.random(1, #moveInfos)
    end
    return build(moveInfos[index])
end

--[[
-- 逃离预警技策略
-- @param uid 角色uid
-- @alertMap 预警范围(可选项)
-- @positions 安全可达区域
--]]
function AIManager:doAlertRunaway(uid, alertMap, positions)
    if not uid then
        LOG_ERROR("doAlertRunaway uid invalid.")
        return nil
    end

    local alertMap = alertMap or self:getAlertMap() or {}
    local position = self:getPlayerPosition(uid)
    if alertMap[position] == nil then -- 所在位置安全
        return self:buildStandby(uid)
    end

    local positions = positions or self:getSafeArea(uid, nil, alertMap)
    if not next(positions) then -- 无法逃离
        return self:buildStandby(uid)
    end

    -- 初始化数据
    local runawayInfos = {}
    for _, pos in pairs(positions) do
        local path = self:getPath2Position(uid, pos, true) or {}
        local runawayInfo = {
            position = pos,
            path = path,
            step = #path
        }
        table.insert(runawayInfos, runawayInfo)
    end

    -- 返回结果
    local function build(runawayInfo)
        local path = runawayInfo.path
        return self:buildStandby(uid, nil, path)
    end

    if not next(runawayInfos) then
        LOG_ERROR("uid[%s] doAlertRunaway runawayInfos invalid.", uid)
        return self:buildStandby(uid)
    elseif #runawayInfos == 1 then
        return build(runawayInfos[1])
    end

    -- 处理路径BUFF
    runawayInfos = self:handleBuff(runawayInfos)
    if #runawayInfos == 1 then
        return build(runawayInfos[1])
    end

    -- 处理移动距离
    runawayInfos = self:handleDistance(runawayInfos)
    local index = 1
    if #runawayInfos ~= 1 then
        index = math.random(1, #runawayInfos)
    end
    return build(runawayInfos[index])
end

--[[
-- 处理攻击数量
--]]
function AIManager:handleAmount(attackInfos)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleAmount parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleNearbyMember attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 排序
    table.sort(attackInfos, function(info1, info2)
        return info1.targetNum > info2.targetNum
    end)

    local max = attackInfos[1].targetNum -- 最大值
    local choice = { attackInfos[1] } -- 最大值数组
    for i = 2, #attackInfos do
        if attackInfos[i].targetNum == max then
            table.insert(choice, attackInfos[i])
        end
    end

    LOG_INFO("After handleNearbyMember attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 选择怪物身边友方数量最多的攻击信息
--]]
function AIManager:handleNearbyMember(attackInfos)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleNearbyMember parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleNearbyMember attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 获取目标附近友方单位
    for _, attackInfo in pairs(attackInfos) do
        if #attackInfo.targetUids ~= 1 then -- 普攻有且只有一个目标
            LOG_ERROR("handleNearbyMember attackInfo error, info:%s", ptable(attackInfo))
        end
        local targetUid = attackInfo.targetUids[1] or 0
        attackInfo.nearbyUids = self:getMonsterAroundPlayer(targetUid) or {}
        attackInfo.nearbyNum = #attackInfo.nearbyUids
    end
    table.sort(attackInfos, function(info1, info2)
        return info1.nearbyNum > info2.nearbyNum
    end)

    local max = attackInfos[1].nearbyNum
    local choice = { attackInfos[1] }
    for i = 2, #attackInfos do
        if attackInfos[i].nearbyNum == max then
            table.insert(choice, attackInfos[i])
        end
    end

    LOG_INFO("After handleNearbyMember attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 处理属性克制
--]]
function AIManager:handleProperty(uid, attackInfos)
    if not uid or type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleProperty parameter invalid, uid[%s] and attackInfos type[%s].", uid, type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleProperty attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 获取怪物以及自己的属性数据
    local properties = self:getProperties(self:getMonsters(), uid)
    local palyerAttr = properties[uid]
    if not palyerAttr then
        LOG_ERROR("handleProperty uid[%s] property is nil.", uid)
        return attackInfos
    end

    -- 检测攻击目标与自己的属性关系
    local excellent -- 克制
    local ordinary  -- 无关
    local terrible  -- 被克制
    for _, attackInfo in pairs(attackInfos) do
        local state = 0
        for _, targetUid in pairs(attackInfo.targetUids) do
            local targetAttr = properties[targetUid]
            if not targetAttr then
                LOG_ERROR("handleProperty uid[%s] property is nil.", targetUid)
            else
                local ret = self:attributeInterrelation(palyerAttr.attribute or -1, targetAttr.attribute or -1)
                if ret == 1 then
                    state = 1
                    break
                elseif ret == -1 then
                    state = -1
                end
            end
        end
        if state == 1 then
            excellent = excellent or {}
            table.insert(excellent, attackInfo)
        elseif state == 0 then
            ordinary = ordinary or {}
            table.insert(ordinary, attackInfo)
        else
            terrible = terrible or {}
            table.insert(terrible, attackInfo)
        end
    end

    local choice = excellent or ordinary or terrible
    LOG_INFO("Before handleProperty attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 获取属性克制的攻击目标
--]]
function AIManager:inhibitProperty(uid, attackInfos)
    if not uid or type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("inhibitProperty parameter invalid, uid[%s] and attackInfos type[%s].", uid, type(attackInfos))
        return nil
    end
	local excellent = {} -- 克制

    -- 获取怪物以及自己的属性数据
    local properties = self:getProperties(self:getMonsters(), uid)
    local palyerAttr = properties[uid]
    if not palyerAttr then
        LOG_ERROR("inhibitProperty uid[%s] property is nil.", uid)
        return excellent
    end

    -- 检测攻击目标与自己的属性关系
    local excellent -- 克制
    for _, attackInfo in pairs(attackInfos) do
        local state = 0
        for _, targetUid in pairs(attackInfo.targetUids) do
            local targetAttr = properties[targetUid]
            if not targetAttr then
                LOG_ERROR("handleProperty uid[%s] property is nil.", targetUid)
            else
                local ret = self:attributeInterrelation(palyerAttr.attribute or -1, targetAttr.attribute or -1)
                if ret == 1 then
                    state = 1
                    break
                elseif ret == -1 then
                    state = -1
                end
            end
        end
        if state == 1 then
            excellent = excellent or {}
            table.insert(excellent, attackInfo)
        end
    end

    LOG_INFO("inhibitProperty attack info:%s.", ptable(excellent))
    return excellent
end

--[[
-- 处理围攻
--]]
function AIManager:handleSurround(uid, attackInfos)
    if not uid or type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleSurround parameter invalid, uid[%s] and attackInfos type[%s].", uid, type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleSurround attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 获取怪物以及释放技能者的属性
    local properties = self:getProperties(self:getMonsters(), uid)
    local palyerAttr = properties[uid]
    if not palyerAttr then
        LOG_ERROR("handleSurround uid[%s] property is nil.", uid)
        return attackInfos
    end

    -- 检测攻击信息中移动终点附近怪物信息
    local first -- 1 附近有自己克制的怪物
    local second -- 2 附近有怪物, 无克制与被克制关系
    local third -- 3 附近无怪物
    local last -- 4 附近有克制自己的怪物
    for _, attackInfo in pairs(attackInfos) do
        local state = 3
        if attackInfo.position then
            local targetUids = self:getAroundTargetByPosition(attackInfo.position, 2)
            for _, targetUid in pairs(targetUids) do
                local targetAttr = properties[targetUid]
                if not targetAttr then
                    LOG_ERROR("handleSurround uid[%s] property is nil.", targetUid)
                else
                    local ret = self:attributeInterrelation(palyerAttr.attribute or -1, targetAttr.attribute or -1)
                    if ret == 1 then
                        state = 1   -- 存在克制
                        break
                    elseif ret == -1 then
                        state = 4   -- 不考虑同时存在克制和被克制的情况, 所以不直接返回
                    elseif state ~= 4 then
                        state = 2
                    end
                end
            end
        else
            LOG_ERROR("handleSurround single skill data without position, data info:%s", ptable(attackInfo))
        end
        if state == 1 then
            first = first or {}
            table.insert(first, attackInfo)
        elseif state == 2 then
            second = second or {}
            table.insert(second, attackInfo)
        elseif state == 3 then
            third = third or {}
            table.insert(third, attackInfo)
        else
            last = last or {}
            table.insert(last, attackInfo)
        end
    end
    local choice = first or second or third or last
    LOG_INFO("After handleSurround attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 处理路径BUFF
--]]
function AIManager:handleBuff(attackInfos)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleBuff parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleBuff attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 获取所有BUFF
    local buffs = self:getBuffs()
    if not next(buffs) then -- 无BUFF
        return attackInfos
    end
	local choice = {}
	local goodBuff = {}
	local commonBuff = {}
	for _, attackInfo in pairs(attackInfos) do
		local position = attackInfo.path[#attackInfo.path]
		local buff = buffs[position]
		if buff and buff.type == 0 then
			table.insert(goodBuff,attackInfo)
		elseif buff and buff.type == 1 then
			table.insert(commonBuff,attackInfo)
		end
	end
	if #goodBuff > 0 then
		choice = goodBuff
	elseif #commonBuff > 0 then
		choice = commonBuff
	else
		choice = attackInfos
	end
    -- 根据路径BUFF积分, 有益(1), 有害(-1), 无(0)
    --[[for _, attackInfo in pairs(attackInfos) do
        attackInfo.priority = 0 -- 初始0
        for _, position in pairs(attackInfo.path) do
            local buff = buffs[position]
            if buff and buff.type == 0 then
                attackInfo.priority = attackInfo.priority + 1
            elseif buff and buff.type == 1 then
                attackInfo.priority = attackInfo.priority - 1
            end
        end
    end
    -- 排序
    table.sort(attackInfos, function(info1, info2)
        return info1.priority > info2.priority
    end)

    local max = attackInfos[1].priority -- 最大值
    choice = { attackInfos[1] } -- 最大值数组
    for i = 2, #attackInfos do
        if attackInfos[i].priority == max then
            table.insert(choice, attackInfos[i])
        end
    end--]]

    LOG_INFO("After handleBuff attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 处理距离
--]]
function AIManager:handleDistance(attackInfos)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleDistance parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleDistance attack info:%s.", ptable(attackInfos))
    if #attackInfos == 1 then
        return attackInfos
    end

    -- 排序
    table.sort(attackInfos, function(info1, info2)
        return info1.step < info2.step
    end)

    -- 选择最近集合
    local min = attackInfos[1].step -- 最短距离
    local choice = { attackInfos[1] } -- 最近数组
    for i = 2, #attackInfos do
        if attackInfos[i].step == min then
            table.insert(choice, attackInfos[i])
        end
    end

    LOG_INFO("After handleDistance attack info:%s.", ptable(choice))
    return choice
end

--[[
-- 处理血量
-- @param targetType
--]]
function AIManager:handleHp(attackInfos, targetType)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleHp parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleHp attack info:%s.", ptable(attackInfos))

    if #attackInfos == 1 then
        return attackInfos
    end

    -- 获取目标属性
    local properties
    if TargetType.Player == targetType then
        properties = self:getProperties(self:getPlayers())
    else
        properties = self:getProperties(self:getMonsters())
    end
    for _, attackInfo in pairs(attackInfos) do
        local minHp
        for _, targetUid in pairs(attackInfo.targetUids) do
            local data = properties[targetUid]
            if data then
                minHp = minHp or data.hp
                if minHp > data.hp then
                    minHp = data.hp
                end
            else
                LOG_ERROR("handleHp properties without target[%s] property.", targetUid)
            end
        end
        attackInfo.hp = minHp or 10000
    end
    table.sort(attackInfos, function(info1, info2)
        return info1.hp < info2.hp
    end)

    local min = attackInfos[1].hp
    local choice = { attackInfos[1] }
    for i = 2, #attackInfos do
        if attackInfos[i].hp == min then
            table.insert(choice, attackInfos[i])
        end
    end

    LOG_INFO("Before handleHp attack info:%s.", ptable(choice))
    return choice -- 更新列表
end

--[[
-- 过滤路径
--]]
function AIManager:PathFilter(uid, path)
    if not uid or type(path) ~= "table" then
        LOG_ERROR("PathFilter parameter invalid.")
        return nil
    end

    LOG_INFO("Before PathFilter path info:%s.", ptable(path))
    local step = self:getStepNum(uid)
    -- 处理多余步数
    while #path > step do
        table.remove(path, #path)
    end

    -- 处理不可停留点, 因为可以穿人, 不可以站到人上
    local map = self:getPlayerAccessibleMap(uid)
    while #path > 0 and map[path[#path]] == nil do
        table.remove(path, #path)
    end

    LOG_INFO("After PathFilter path info:%s.", ptable(path))
end

--[[
--获取大招的信息
--返回值
data = {
	uid --棋子uid
	ultimateId --大招id
	ultimateType --大招的类型
	ultimateLevel -- 大招等级
	isCd    -- CD true 可以使用, false 不可以使用
}
--]]
function AIManager:getUltimateData(uids)
    local dataList = AiLogic.aiLuaCallCSharpInterface:GetUltimateData(uids)
    local dataTable = {}
    for i = 0, dataList.Count - 1 do
        local data = {}
        data.uid = dataList[i].uid
        data.ultimateId = dataList[i].ultimateId
        data.ultimateType = dataList[i].ultimateType
        data.ultimateLevel = dataList[i].ultimateLevel
        data.isCd = dataList[i].isCd
        table.insert(dataTable, data)
    end
    return dataTable
end

--[[
-- 得到玩家属性
--]]
function AIManager:getAttributeByUid(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetAttributeByUid(uid)
end

--[[
-- 得到源属性是否克制目标属性
-- 参数
-- sourceAttribute 源属性
-- targetAttribute 目标属性
--]]
function AIManager:isRestrainAttribute(sourceAttribute, targetAttribute)
    local restrainAttribute = AiEnum.AiAttributeRestrain[sourceAttribute]
    if (restrainAttribute == targetAttribute) then
        return true
    else
        return false
    end
end

--[[
--得到玩家克制的敌人列表
--]]
function AIManager:getRestrainOpponentUids(uid, opponentUids)
    local uids = {}
    local playerAttribute = self:getAttributeByUid(uid)
    for i = 1, #opponentUids do
        local opponentUid = opponentUids[i]
        local opponentAttribute = self:getAttributeByUid(opponentUid)
        local restrainAttribute = self:isRestrainAttribute(playerAttribute, opponentAttribute)
        if (restrainAttribute) then
            table.insert(uids, opponentUid)
        end
    end
    return uids
end

--[[
--得到当前怒气值
--]]
function AIManager:getCurrentMp()
    return AiLogic.aiLuaCallCSharpInterface:GetCurrentMp()
end

--[[
--获取目标等级
--]]
function AIManager:getItemLevel(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetItemLevel(uid)
end

--[[
--获取最高星级
--]]
function AIManager:getMaxStar(uid)
    return AiLogic.aiLuaCallCSharpInterface:GetMaxStar(uid)
end

--[[
--  获取血量信息
--  返回值 {
--      uid,
--      totalHP,
--      hp
-- }
--]]
function AIManager:getItemHpInfo(uids)
    local itemHpInfoList = AiLogic.aiLuaCallCSharpInterface:GetItemAttributeInfo(uids)
    local itemHpInfoTable = {}
    for i = 0, itemHpInfoList.Count - 1 do
        local itemTable = {}
        itemTable.uid = itemHpInfoList[i].uid
        itemTable.totalHP = itemHpInfoList[i].totalHP
        itemTable.hp = itemHpInfoList[i].hp
        table.insert(itemHpInfoTable, itemTable)
    end

    return itemHpInfoTable
end

--[[
--选出血量少于指定值(相对于总血量的百分比)的目标
--targets 选取的范围
--hpPercent 相对于总血量的百分比
--]]
function AIManager:getHpLessPercent(targets, hpPercent)
    local hpPercent = hpPercent * 0.01
    local data = {}
    local hpInfos = self:getItemHpInfo(targets)
    for i = 1, #hpInfos do
        local percent = hpInfos[i].hp / hpInfos[i].totalHP
        if (percent < hpPercent) then
            table.insert(data, hpInfos[i].uid)
        end
    end
    return data
end


