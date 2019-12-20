CampWar = {}

local self
local activityId

function CampWar.Init(activityId,useSelf, ... )
	self = useSelf
	CampWar.activityId = activityId
	if self.transform.childCount > 1 then
		return;
	end

	CS.client.ResourceManager.GetInstance():LoadAssetAsync(30349, function( bundleID, operation, param )
		if not operation then
			return
		end
		local asset = operation:GetAsset()
		if not asset then
			return
		end
		local page = CS.UnityEngine.GameObject.Instantiate(asset)
        page.transform:SetParent(self.transform, false)

		local behaviour = page:AddComponent(typeof(CS.client.LuaBehaviour));
		behaviour.luaFilePath = "Activity/CampWar/CampWarView"
		behaviour:Init();
        
		local btnBack = CS.client.Global.GetGameObject(self.gameObject, "button_back");
        CS.client.Global.RegisterButtonClick(btnBack, function( ... )
			CS.client.UIManager.GetInstance():Close(CS.client.UIPaths.UI_LuaDialog);
        end)
	end)

	require("LuaUIManager").RegisterDialog("Activity/CampWar/CampWar", self)
end

function CampWar.OnDestroy( ... )
	require("LuaUIManager").RemoveDialog("Activity/CampWar/CampWar");
end

function CampWar:GetActivityId()
	return CampWar.activityId
end
return CampWar