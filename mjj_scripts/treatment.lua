--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/27
-- Time: 16:32
-- Treatment Card common AI.
--

local Treatment = AIManager.new()

function Treatment:GetAIBehavior(uid)
    LOG_INFO("Buffer GetAIBehavior uid %s.", uid)
    local positions = self:getPlayerAccessiblePositions(uid)

    -- 普攻策略
    if self:isCanReleaseSkill(uid) == false then
        return self:doCommonAttack(uid, positions)
    end

    -- 初始化数据
    local skillId = self:getActiveSkill(uid)
    local attackInfos = self:getSkillAttackInfoByPosition(uid, skillId, positions)
    local alertMap = self:getAlertMap()

    -- 普攻
    if not next(attackInfos) then
        return self:doCommonAttack(uid, positions)
    end

    -- 处理队友血量, 队友血量多时普攻
    attackInfos = self:handleHpByPercent(attackInfos, 50)
    if not next(attackInfos) then
        return self:doCommonAttack(uid, positions)
    end

    -- 处理预警技
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
    if ok == true then
        attackInfos = ret
        if #attackInfos == 1 then
            return self:Attack(uid, skillId, attackInfos[1])
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
        return self:Attack(uid, skillId, attackInfos[1])
    end

    -- 处理路径BUFF
	if isHandleBuff == false then
		attackInfos = self:handleBuff(attackInfos)
		if #attackInfos == 1 then
			return self:Attack(uid, skillId, attackInfos[1])
		end
	end
    

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
    if #attackInfos == 1 then
        return self:Attack(uid, skillId, attackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos, TargetType.Player)
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    return self:Attack(uid, skillId, attackInfos[index])
end

function Treatment:Attack(uid,skillId,attackInfo)
	--LOG_ERROR("*********Attack uid[%s] skillId[%s] info:%s",uid,skillId,ptable(attackInfo))
	if(#attackInfo.targetUids == 1) then
		if(attackInfo.step > 0) then
			if(attackInfo.targetUids[1] == uid) then
				attackInfo.skillPos = attackInfo.path[attackInfo.step]
			end
		end
	end
	return self:buildAttack(uid, skillId, attackInfo)
end
--[[
-- 治疗处理目标血量
--]]
function Treatment:handleHpByPercent(attackInfos, hpPercent)
    if type(attackInfos) ~= "table" or #attackInfos == 0 then
        LOG_ERROR("handleHpByPercent parameter invalid, attackInfos type[%s].", type(attackInfos))
        return nil
    end

    LOG_INFO("Before handleHpByPercent current number[%s] and info:%s.", #attackInfos, ptable(attackInfos))

    local choice = {}
    local properties = self:getProperties(self:getPlayers())
    for _, attackInfo in pairs(attackInfos) do
        for _, uid in pairs(attackInfo.targetUids) do
            local data = properties[uid]
            if not data then
                LOG_ERROR("handleHpByPercent without uid[%s] property.", uid)
            else
                local percent = data.hp / data.totalHP * 100
                if percent <= hpPercent then
                    table.insert(choice, attackInfo)
                    break
                end
            end
        end
    end

    LOG_INFO("Before handleHpByPercent current number[%s] and info:%s.", #choice, ptable(choice))
    return choice
end

return Treatment

