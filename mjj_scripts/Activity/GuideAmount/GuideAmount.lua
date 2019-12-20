GuideAmount = {}

local self
local activityId

function GuideAmount.Init(activityId,useSelf, ... )
	self = useSelf
	GuideAmount.activityId = activityId
	if self.transform.childCount > 1 then
		return;
	end

	CS.client.ResourceManager.GetInstance():LoadAssetAsync(29086, function( bundleID, operation, param )
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
		behaviour.luaFilePath = "Activity/GuideAmount/GuideAmountView"
		behaviour:Init();
        
		local btnBack = CS.client.Global.GetGameObject(self.gameObject, "button_back");
        CS.client.Global.RegisterButtonClick(btnBack, function( ... )
			CS.client.UIManager.GetInstance():Close(CS.client.UIPaths.UI_LuaDialog);
        end)
	end)

	require("LuaUIManager").RegisterDialog("Activity/GuideAmount/GuideAmount", self)
end

function GuideAmount.OnDestroy( ... )
	require("LuaUIManager").RemoveDialog("Activity/GuideAmount/GuideAmount");
end

function GuideAmount:GetActivityId()
	return GuideAmount.activityId
end
return GuideAmount