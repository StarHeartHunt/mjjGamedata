--[[
-- 大招AI逻辑
--]]

UltimateSkillAttackAi = AIManager.new()
--local self = UltimateSkillAi

--[[
-- 大招选择排序器
-- userdata 必须包含的数据
-- {
--      uid, -- 角色UID
--      restrainNum, -- 克制数量
--      level, -- 角色等级
--      maxStar, -- 最高星级
--      ultimateLevel -- 大招等级
-- }
-- 排序规则:克制 > 角色等级 > 角色星级 > 技能等级 > 编队位置(唯一, 不会相等)
--]]
local function comparator(info1, info2)
    if info1.restrainNum ~= info2.restrainNum then
        return info1.restrainNum > info2.restrainNum
    elseif info1.level ~= info2.level then
        return info1.level > info2.level
    elseif info1.maxStar ~= info2.maxStar then
        return info1.maxStar > info2.maxStar
    elseif info1.ultimateLevel ~= info2.ultimateLevel then
        return info1.ultimateLevel > info2.ultimateLevel
    else
        return info1.uid < info2.uid
    end
end

--[[
-- 构造大招消息
-- @param uid 施放大招的角色UID, 参数为nil是不释放大招
--]]
function UltimateSkillAttackAi:buildUltimate(uid)
    LOG_INFO("uid[%s] build ultimate message.", uid)
    if type(uid) ~= "number" then
        LOG_ERROR("uid[%s] build ultimate message, uid invalid.", uid)
        uid = nil
    end
    local aiData = {
        isStandby = true
    }

    if type(uid) == "number" and uid > 0 then
        aiData.isStandby = false
        aiData.releaskUltimateUid = uid
    end
    LOG_INFO("uid[%s] build ultimate info:%s.", uid, ptable(aiData))
    return { aiBehaviorData = aiData }
end

--[[
-- 根据类型优先级对大招进行筛选
-- @param uids 角色UID集合
--]]
function UltimateSkillAttackAi:handleUltimatePriority(ultimateInfos, uids)
    -- 对大招进行分类
    local treatment -- 1类 治疗类
    local decreasePlayerHarm -- 2类 减少我方伤害
    local addPlayerHarm -- 3类 增加我方伤害
    local attackDecreasePlayerHarm -- 4类 攻击 + 减少我方伤害
    local attackAddPlayerHarm -- 5类 攻击 + 增加我方伤害
    local common -- 4, 5, 6 类
    for _, ultimateInfo in pairs(ultimateInfos) do
        if (ultimateInfo.ultimateType == 1) then
            treatment = treatment or {}
            table.insert(treatment, ultimateInfo)
        elseif (ultimateInfo.ultimateType == 2 ) then
            decreasePlayerHarm = decreasePlayerHarm or {}
            table.insert(decreasePlayerHarm, ultimateInfo)
        elseif (ultimateInfo.ultimateType == 3 ) then
            addPlayerHarm = addPlayerHarm or {}
            table.insert(addPlayerHarm, ultimateInfo)
        elseif (ultimateInfo.ultimateType == 4 ) then
            common = common or {}
            table.insert(common, ultimateInfo)
            attackDecreasePlayerHarm = attackDecreasePlayerHarm or {}
            table.insert(attackDecreasePlayerHarm, ultimateInfo)
        elseif (ultimateInfo.ultimateType == 5 ) then
            common = common or {}
            table.insert(common, ultimateInfo)
            attackAddPlayerHarm = attackAddPlayerHarm or {}
            table.insert(attackAddPlayerHarm, ultimateInfo)
        elseif (ultimateInfo.ultimateType == 6) then -- 6类 攻击
            common = common or {}
            table.insert(common, ultimateInfo)
        end
    end

-- 选择友方血量低于40%的数量
    local targets = self:getHpLessPercent(uids, 40)
	
	if common ~= nil and #common > 0 then
		return common
	elseif addPlayerHarm ~= nil and #addPlayerHarm > 0 then
		return addPlayerHarm
	elseif targets ~= nil and #targets> 0 and  treatment ~= nil and #treatment > 0 then -- 选择治疗系
		return treatment
	elseif decreasePlayerHarm ~= nil and #decreasePlayerHarm > 0 then
		return decreasePlayerHarm
	else
		return {}
	end
    
end

--[[
--  大招策略
--]]
function UltimateSkillAttackAi:getUltimateSkillAIBehavior(uid, banAiList)
    -- 初始化数据
    local banTypeMap = parseMap(banAiList or {}) -- 禁用的大招类型map
    LOG_INFO("uid[%s] GetUltimateSkillAIBehavior ban list:%s.", uid, ptable(banTypeMap))
    local playerUids = self:getPlayers()
    local opponentUids = self:getMonsters()
    local ultimateData = self:getUltimateData(playerUids) -- 大招数据
    LOG_INFO("uid[%s] GetUltimateSkillAIBehavior ultimate list:%s.", uid, ptable(ultimateData))

    -- 初始化大招数据
    local ultimateInfos = {}
    for _, data in pairs(ultimateData) do
        if data.isCd == true then -- 不处与CD中
            local ultimateInfo = {}
            local restrainOpponentUids = self:getRestrainOpponentUids(data.uid, opponentUids) -- 角色克制的敌人
            ultimateInfo.uid = data.uid -- 角色UID
            ultimateInfo.ultimateType = data.ultimateType    -- 大招类型
            ultimateInfo.ultimateLevel = data.ultimateLevel  -- 大招等级
            ultimateInfo.level = self:getItemLevel(data.uid) -- 角色等级
            ultimateInfo.maxStar = self:getMaxStar(data.uid) -- 最高星级
            ultimateInfo.restrainNum = #restrainOpponentUids -- 克制敌人数量
            ultimateInfo.isEffectInScene = self:isEffectInScene(data.ultimateId) -- 场上是否有相同效果
            table.insert(ultimateInfos, ultimateInfo)
        end
    end
    LOG_INFO("uid[%s] GetUltimateSkillAIBehavior build data, current number[%s] and info:%s.", uid, #ultimateInfos, ptable(ultimateInfos))
    if #ultimateInfos == 0 then -- 没有可以释放的大招
        return self:buildUltimate(0)
    end

    -- 处理大招释放的优先级
    ultimateInfos = self:handleUltimatePriority(ultimateInfos, playerUids)
    LOG_INFO("uid[%s] GetUltimateSkillAIBehavior after handleUltimatePriority, current number[%s] and info:%s.", uid, #ultimateInfos, ptable(ultimateInfos))
    if #ultimateInfos == 0 then -- 没有可以释放的大招
        return self:buildUltimate(0)
    elseif #ultimateInfos == 1 then -- 只有一个大招可以选择
        return self:buildUltimate(ultimateInfos[1].uid)
    end

    -- 对筛选的大招进行排序
    table.sort(ultimateInfos, comparator)
    LOG_INFO("uid[%s] GetUltimateSkillAIBehavior after sort, current number[%s] and info:%s.", uid, #ultimateInfos, ptable(ultimateInfos))
    return self:buildUltimate(ultimateInfos[1].uid)
end

return UltimateSkillAttackAi