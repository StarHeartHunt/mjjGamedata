OldUserReturn = {}

local self
local activityId

function OldUserReturn.Init(activityId,useSelf, ... )
	self = useSelf
	OldUserReturn.activityId = activityId
	--print("OldUserReturn.Init useSelf ",self)
	if self.transform.childCount > 1 then
		return;
	end

	CS.client.ResourceManager.GetInstance():LoadAssetAsync(30347, function( bundleID, operation, param )
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
		behaviour.luaFilePath = "Activity/OldUserReturn/OldUserReturnView"
		behaviour:Init();
        
		local btnBack = CS.client.Global.GetGameObject(self.gameObject, "button_back");
        CS.client.Global.RegisterButtonClick(btnBack, function( ... )
			CS.client.UIManager.GetInstance():Close(CS.client.UIPaths.UI_LuaDialog);
        end)
	end)

	require("LuaUIManager").RegisterDialog("Activity/OldUserReturn/OldUserReturn", self)
end

function OldUserReturn.OnDestroy( ... )
	require("LuaUIManager").RemoveDialog("Activity/OldUserReturn/OldUserReturn");
end

function OldUserReturn:GetActivityId()
	return OldUserReturn.activityId
end

return OldUserReturn