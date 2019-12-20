ActivityLogicManager = {}

local LuaTemplate = require "p2dtemplate_lua/lua"
ActivityLogicManager.activityLogic = nil
 

function ActivityLogicManager.RunActivity(id,useSelf)
	print("ActivityLogicManager RunActivity id useSelf ",id,useSelf)
	activityLogic = {} 
	
	if(LuaTemplate[id] ==nil) then
		return
	else 
		activityLogic = GetActivityName(LuaTemplate[id].lua_LUA_filename) 
	end
	if(activityLogic ~= nil) then
		print("activityLogic ",activityLogic)
		activityLogic.Init(id,useSelf)
	end
end

function ActivityLogicManager.Start()
	if(activityLogic ~= nil and activityLogic.Start ~= nil) then
		activityLogic.Start()
	end
end

function ActivityLogicManager.Update()
	if(activityLogic ~= nil and activityLogic.Update ~= nil) then
		activityLogic.Update()
	end
end

function ActivityLogicManager.OnEnable()
	if(activityLogic ~= nil and activityLogic.OnEnable ~= nil) then
		activityLogic.OnEnable()
	end
end

function ActivityLogicManager.OnDisable()
	if(activityLogic ~= nil and activityLogic.OnDisable ~= nil) then
		activityLogic.OnDisable()
	end
end


function ActivityLogicManager.OnDestroy()
	if(activityLogic ~= nil and activityLogic.OnDestroy ~= nil) then
		activityLogic.OnDestroy()
	end
end

return ActivityLogicManager