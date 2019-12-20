--
-- Created by IntelliJ IDEA.
-- User: Admin
-- Date: 2017/5/27
-- Time: 10:00
-- Yuzhenqi Card common AI.
--

local Yuzhenqi = AIManager.new()

function Yuzhenqi:GetAIBehavior(uid)
	local positions = self:getPlayerAccessiblePositions(uid) -- 玩家可达区域
    if self:isCanReleaseSkill(uid) == false then -- 普攻
        return self:doCommonAttack(uid, positions)
    end

	local activeSkillId = self:getActiveSkill(uid)
    local activeAttackInfos = self:getSkillAttackInfoByPosition(uid, activeSkillId, positions)
	LOG_INFO("Yuzhenqi:GetAIBehavior activeAttackInfos[%s] ", ptable(activeAttackInfos))

    local skillId = self:getCommonSkill(uid)
    local attackInfos = self:getSkillAttackInfoByPosition(uid, skillId, positions)
    local alertMap = self:getAlertMap()
	LOG_INFO("Yuzhenqi:GetAIBehavior attackInfos[%s] ", ptable(attackInfos))
    -- 无可攻击目标
    if not next(attackInfos) then
        return self:doStandby(uid, alertMap)
    end
	--这个是个容错，yuzhenqi的主动技能无cd，对自己释放，所以activeAttackInfos不可能为nil 
	if not next(activeAttackInfos) then
        return self:doStandby(uid, alertMap)
    end

    -- 选择攻击或者逃跑
    local ok, ret = self:attackAndRunawayChoice(uid, attackInfos, alertMap, positions)
	LOG_INFO("Yuzhenqi:GetAIBehavior ok attackInfos[%s] ", ok,ptable(attackInfos))
    if ok == true then
        attackInfos = ret
    else
        return self:doAlertRunaway(uid, alertMap, ret)
    end
	
	
    if #attackInfos == 1 then
		self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
    end
	  
	--如果场上有血量低于50%的 优先去踩有益BUFF
	local isHandleBuff = false
	local playerUids = self:getPlayers()
	local hpData = self:getHpLessPercent(playerUids, 50)
	LOG_INFO("!!!!!!!!!!!!!!!!!!!!!!!!Yuzhenqi:GetAIBehavior hpData[%s] ", ptable(hpData))
    if next(hpData) then
        attackInfos = self:handleBuff(attackInfos)
		isHandleBuff = true
		LOG_INFO("Yuzhenqi:GetAIBehavior attackInfos[%s] ", ptable(attackInfos))
		if #attackInfos == 1 then
			self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
		end
    end
	
    -- 处理目标数量
    attackInfos = self:handleAmount(attackInfos)
	LOG_INFO("Yuzhenqi:GetAIBehavior2 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
    end

    -- 处理属性克制
    attackInfos = self:handleProperty(uid, attackInfos)
	LOG_INFO("Yuzhenqi:GetAIBehavior3 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
    end

    -- 处理路径BUFF
	if isHandleBuff == false then
		attackInfos = self:handleBuff(attackInfos)
		LOG_INFO("Yuzhenqi:GetAIBehavior3 attackInfos[%s] ", ptable(attackInfos))
		if #attackInfos == 1 then
			self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
		end
	end
    

    -- 优先靠近目标
    attackInfos = self:handleSurround(uid, attackInfos)
	LOG_INFO("Yuzhenqi:GetAIBehavior4 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
    end

    -- 处理距离
    attackInfos = self:handleDistance(attackInfos)
	LOG_INFO("Yuzhenqi:GetAIBehavior5 attackInfos[%s] ", ptable(attackInfos))
    if #attackInfos == 1 then
        self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
    end

    -- 处理血值
    attackInfos = self:handleHp(attackInfos)
	LOG_INFO("Yuzhenqi:GetAIBehavior6 attackInfos[%s] ", ptable(attackInfos))
    local index = 1
    if #attackInfos > 1 then
        -- random
        index = math.random(1, #attackInfos)
    end
    self:buildYuzhenqiAttack(uid, skillId, attackInfos[1], activeAttackInfos[1])
end


function Yuzhenqi:buildYuzhenqiAttack(uid, skillId, commonAttackinfo,activeAttackinfo)
	LOG_INFO("Yuzhenqi:buildYuzhenqiAttack commonAttackinfo[%s] ", ptable(commonAttackinfo))
	LOG_INFO("Yuzhenqi:buildYuzhenqiAttack activeAttackinfo[%s] ", ptable(activeAttackinfo))
    commonAttackinfo = self:inhibitProperty(uid,commonAttackinfo)
	LOG_INFO("Yuzhenqi:buildYuzhenqiAttack22 commonAttackinfo[%s] ", ptable(commonAttackinfo))
	if not next(commonAttackinfo) then
		return self:buildAttack(uid, skillId, activeAttackinfo[1])
	else
		return self:buildAttack(uid, skillId, commonAttackinfo[1])
	end
end

return Yuzhenqi

