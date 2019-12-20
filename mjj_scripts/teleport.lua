local Teleport = AIManager.new()

function Teleport:GetAIBehavior(uid)
	local skillId = self:getActiveSkill(uid)
	LOG_INFO("Teleport uid %s.", uid)
	LOG_INFO("Teleport skillId  %s.", skillId)
	local selfPos = self:getPosition(uid)
	
	local skillPositions = self:getAllSkillAttackResult(uid,selfPos[1],skillId)
	local positions = {}
	for k, v in pairs(skillPositions) do
		table.insert(positions,k)
	end
	
	local monsters = self:getMonsters() --怪物uids
	--local nearItemPositions = self:getNearItemPosByUids(monsters)
	LOG_INFO("++++++++Teleport monsters:%s.", ptable(monsters))
	local nearItemPositions = {}
	local tempPostions = {}
	for i=1,#monsters do
		local mon_postions = self:getPosition(monsters[i])
		LOG_INFO("++++++++Teleport mon_postions:%s.", ptable(mon_postions))
		for j=1,#mon_postions do
			local mon_around_postions = aroundPositions(mon_postions[j])
			for _, v in pairs(mon_around_postions) do
				table.insert(tempPostions,v)
			end
			
		end
	end
	for i=1,#tempPostions do
		local isFind = self:IsFind(nearItemPositions,tempPostions[i])
		if(isFind == false) then
			table.insert(nearItemPositions,tempPostions[i])
		end
	end
	LOG_INFO("Teleport positions:%s.", ptable(positions))
	LOG_INFO("++++++++Teleport nearItemPositions:%s.", ptable(nearItemPositions))
	LOG_INFO("Teleport self:isCanReleaseSkill %s.", self:isCanReleaseSkill(uid))
    if self:isCanReleaseSkill(uid) == false or not next(positions) or not next(nearItemPositions)then -- 普攻
		LOG_INFO("**********************doCommonAttack")
        return self:doCommonAttack(uid)
    end
	
	local canTeleportPositions = {}
	
	for _, v in pairs(nearItemPositions) do
		for _, m in pairs(positions) do
			LOG_INFO("++++++++Teleport nearItemPositions:v %s m %s", v,m)
			if v == m then
				table.insert(canTeleportPositions,v)
			end
		end
	end
	LOG_INFO("++++++++Teleport canTeleportPositions:%s.", ptable(canTeleportPositions))
	if not next(canTeleportPositions) then
		LOG_INFO("**********************doCommonAttack")
		return self:doCommonAttack(uid)
	end
	
	local skillId = self:getActiveSkill(uid)
	local alertMap = self:getAlertMap()
	
	local safePositions = {}
	for _, v in pairs(canTeleportPositions) do
		if alertMap[v] == nil then -- 所在位置安全
			table.insert(safePositions,v)
		end
	end
	local skillPos = canTeleportPositions[1]
	
	
	if not next(safePositions) then
		local index = 1
		if #canTeleportPositions >= 1 then
			index = math.random(1, #canTeleportPositions)
		end
		skillPos = canTeleportPositions[index]
	else
		local index = 1
		if #safePositions >= 1 then
			index = math.random(1, #safePositions)
		end
		skillPos = safePositions[index]
	end

	local data = {
        skillId = skillId,
        skillPos = skillPos,
        isStandby = false,
    }
	LOG_INFO("++++++++Teleport data:%s.", ptable(data))
	return { aiBehaviorData = data }
end

function Teleport:IsFind(list,value)
	if list == nil then
		return false
	end
	for _, v in pairs(list) do
		if(value == v) then
			return true
		end
	end
	return false
end

return Teleport