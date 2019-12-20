--[[
-- AI入口
--]]

AiLogic = {}
local AILuaCallCSharpInterface = CS.client.AILuaCallCSharpInterface
AiLogic.aiLuaCallCSharpInterface = nil

function AiLogic.InitAIBehavior()
	AiLogic.aiLuaCallCSharpInterface = AILuaCallCSharpInterface()
end

function AiLogic.DestoryAIBehavior()
    AiLogic.aiLuaCallCSharpInterface:Clear()
    AiLogic.aiLuaCallCSharpInterface = nil
end

--[[
-- 普通AI
--]]
function AiLogic.GetAIBehavior(uid, aiName)
    local aiLogicTable = GetAIByName(aiName)
    if (aiLogicTable == nil) then
        return nil
    else
        return aiLogicTable:GetAIBehavior(uid)
    end
end

--[[
-- 大招AI
--]]
function AiLogic.GetUltimateSkillAIBehavior(uid, banAiList,ultimateType)
	print("!!!!!!!!!!!!!!!!!!!!!! ultimateType ",ultimateType)

	local a = {}
	print("******* ",next(a))
	if ultimateType == AiEnum.AiType.Default then
		return UltimateSkillAi:getUltimateSkillAIBehavior(uid, banAiList)
	else
		return UltimateSkillAttackAi:getUltimateSkillAIBehavior(uid, banAiList)
	end
end

return AiLogic