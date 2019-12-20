--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/27
-- Time: 10:00
-- Attack Card common AI.
--

local Attack = AIManager.new()

function Attack:GetAIBehavior(uid)
    LOG_INFO("GetAIBehavior uid %s.", uid)
    local positions = self:getPlayerAccessiblePositions(uid) -- 玩家可达区域
    if self:isCanReleaseSkill(uid) == false then -- 普攻
        return self:doCommonAttack(uid, positions)
    end

    local skillId = self:getActiveSkill(uid)
    local attackInfos = self:getSkillAttackInfoByPosition(uid, skillId, positions)
    local alertMap = self:getAlertMap()
	LOG_INFO("Attack:GetAIBehavior attackInfos[%s] ", ptable(attackInfos))
    -- 无可攻击目标
    if not next(attackInfos) then
        return self:doStandby(uid, alertMap)
    end

    -- 选择攻击或者逃跑
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
	LOG_INFO("Attack:GetAIBehavior ok attackInfos[%s] ", ok,ptable(attackInfos))
    if ok == true then
        attackInfos = ret
    else
        return self:doAlertRunaway(uid, alertMap, ret)
    end
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
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
	LOG_INFO("Attack:GetAIBehavior2 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理属性克制
    attackInfos = self:handleProperty(uid, attackInfos)
	LOG_INFO("Attack:GetAIBehavior3 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理路径BUFF
	if isHandleBuff == false then
		attackInfos = self:handleBuff(attackInfos)
		LOG_INFO("Attack:GetAIBehavior3 attackInfos[%s] ", ptable(attackInfos))
		if #attackInfos == 1 then
			return self:buildAttack(uid, skillId, attackInfos[1])
		end
	end
    

    -- 优先靠近目标
    attackInfos = self:handleSurround(uid, attackInfos)
	LOG_INFO("Attack:GetAIBehavior4 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
	LOG_INFO("Attack:GetAIBehavior5 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos)
	LOG_INFO("Attack:GetAIBehavior6 attackInfos[%s] ", ptable(attackInfos))
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    return self:buildAttack(uid, skillId, attackInfos[index])
end

return Attack

