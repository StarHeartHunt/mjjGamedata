--[[
-- Lua AI manager
--]]

logLevel = 0

-- load global parameter
require("util")
require("AiEnum")

require("enum")
require("AIManager")
require("ultimate_skill_ai")
require("ultimate_skill_attack_ai")
--require("TestHotfix")

-- register ai script
map = {
    ["treatment_ai"] = require("treatment"),
    ["buff_ai"] = require("buff"),
    ["attack_ai"] = require("attack"),
    ["drag_ai"] = require("drag"),
	["teleport_ai"] = require("teleport"),
}
activityMap = {
	["Activity/CardLottery/CardLottery"] = require("Activity/CardLottery/CardLottery"),
	["Activity/GuideAmount/GuideAmount"] = require("Activity/GuideAmount/GuideAmount"),
	["Activity/CardLotteryTwo/CardLotteryTwo"] = require("Activity/CardLotteryTwo/CardLotteryTwo"),
	["Activity/OldUserReturn/OldUserReturn"] = require("Activity/OldUserReturn/OldUserReturn"),
	["Activity/CampWar/CampWar"] = require("Activity/CampWar/CampWar"),
}

function GetAIByName(aiName)
    if not aiName then
        LOG_ERROR("GetAIByName param error, aiName is %s.", aiName)
        return nil
    end

    if not map[aiName] then
        LOG_ERROR("GetAIByName script is nil, aiName is %s.", aiName)
        return nil
    end

    return map[aiName]
end

function GetActivityName(activityName)
	if not activityName then
        LOG_ERROR("GetActivityName param error, activityName is %s.", activityName)
        return nil
    end
	
	if not activityMap[activityName] then
        LOG_ERROR("GetActivityName script is nil, activityName is %s.", activityName)
        return nil
    end
	
	return activityMap[activityName]
end

require("AiLogic")
require("ActivityLogicManager")