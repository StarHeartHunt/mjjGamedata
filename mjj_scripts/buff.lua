--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/27
-- Time: 13:52
-- Buffer Card common AI.
--

local Buffer = AIManager.new()

function Buffer:GetAIBehavior(uid)
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

    -- 待机策略
    if not next(attackInfos) then
        return self:doStandby(uid, alertMap)
    end

    -- 处理预警技
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
    if ok == true then
        attackInfos = ret
        if #attackInfos == 1 then
            return self:buildAttack(uid, skillId, attackInfos[1])
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
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理路径BUFF
	if isHandleBuff == false then
		attackInfos = self:handleBuff(attackInfos)
		if #attackInfos == 1 then
			return self:buildAttack(uid, skillId, attackInfos[1])
		end
	end

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
    if #attackInfos == 1 then
        return self:buildAttack(uid, skillId, attackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos, TargetType.Player)
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    return self:buildAttack(uid, skillId, attackInfos[index])
end

return Buffer

