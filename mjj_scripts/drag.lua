--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/27
-- Time: 14:10
-- Drag Card common AI.
--

local Drag = AIManager.new()

function Drag:GetAIBehavior(uid)
    LOG_INFO("Drag GetAIBehavior uid %s.", uid)
    local positions = self:getPlayerAccessiblePositions(uid)

    -- 普攻策略
    if self:isCanReleaseSkill(uid) == false then
        return self:doCommonAttack(uid, positions)
    end

    -- 初始化数据
    local skillId = self:getActiveSkill(uid)
    local attackInfos = self:getSkillAttackInfoByPosition(uid, skillId, positions)
    local alertMap = self:getAlertMap()

    -- 待机策略
    if not next(attackInfos) then
        return self:doStandby(uid, alertMap)
    end

    -- 处理预警技
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
    if ok == true then
        attackInfos = ret
        if #attackInfos == 1 then
            return self:build(uid, skillId, attackInfos[1])
        end
    else
        return self:doAlertRunaway(uid, alertMap, ret)
    end
	--如果场上有血量低于50%的 优先去踩有益BUFF
	local isHandleBuff = false
	local playerUids = self:getPlayers()
	local hpData = self:getHpLessPercent(playerUids, 50)
	LOG_INFO("!!!!!!!!!!!!!!!!!!!!!!!!Attack:GetAIBehavior hpData[%s] ", ptable(hpData))
    if next(hpData) then
        attackInfos = self:handleBuff(attackInfos)
		isHandleBuff = true
		LOG_INFO("Attack:GetAIBehavior attackInfos[%s] ", ptable(attackInfos))
		if #attackInfos == 1 then
			return self:buildAttack(uid, skillId, attackInfos[1])
		end
    end
	
    -- 处理目标数量
    attackInfos = self:handleAmount(attackInfos)
    if #attackInfos == 1 then
        return self:build(uid, skillId, attackInfos[1])
    end

    -- 处理属性克制
    attackInfos = self:handleProperty(uid, attackInfos)
    if #attackInfos == 1 then
        return self:build(uid, skillId, attackInfos[1])
    end

    -- 处理路径BUFF
	if isHandleBuff == false then
		attackInfos = self:handleBuff(attackInfos)
		if #attackInfos == 1 then
			return self:build(uid, skillId, attackInfos[1])
		end
	end

    -- 优先靠近目标
    attackInfos = self:handleSurround(uid, attackInfos)
    if #attackInfos == 1 then
        return self:build(uid, skillId, attackInfos[1])
    end

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
    if #attackInfos == 1 then
        return self:build(uid, skillId, attackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos)
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    return self:build(uid, skillId, attackInfos[index])
end

--[[
-- 拖拽构建攻击消息
-- 拖拽时优先拖拽最远目标
--]]
function Drag:build(uid, skillId, attackInfo)
    local single = {} -- 单格怪物
    local multiple = {} -- 多个怪物

    for _, uid in pairs(attackInfo.targetUids) do
        local ret = self:getPosition(uid)
        if #ret == 1 then
            table.insert(single, ret[1])
        else
            for _, v in pairs(ret) do
                table.insert(multiple, v)
            end
        end
    end

    -- 选择技能释放点
    local pos
    if not next(single) then
        pos = multiple[math.random(1, #multiple)]
    else
        local playerPos = self:getPlayerPosition(uid)
        local maxPos = single[1]
        local dis = distance(maxPos, playerPos)
        for i = 2, #single do
            local tempPos = single[i]
            local tempDis = distance(tempPos, playerPos)
            if tempDis > dis then
                dis = tempDis
                maxPos = tempPos
            end
        end
        pos = maxPos
    end

    attackInfo.skillPos = pos
    return self:buildAttack(uid, skillId, attackInfo)
end

return Drag

