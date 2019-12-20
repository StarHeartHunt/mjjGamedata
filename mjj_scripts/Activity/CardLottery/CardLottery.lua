CardLottery = {}

local self
local activityId

function CardLottery.Init(activityId,useSelf, ... )
	self = useSelf
	CardLottery.activityId = activityId
	if self.transform.childCount > 1 then
		return;
	end

	CS.client.ResourceManager.GetInstance():LoadAssetAsync(28715, function( bundleID, operation, param )
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
		behaviour.luaFilePath = "Activity/CardLottery/CardLotteryView"
		behaviour:Init();
        
		local btnBack = CS.client.Global.GetGameObject(self.gameObject, "button_back");
        CS.client.Global.RegisterButtonClick(btnBack, function( ... )
			CS.client.UIManager.GetInstance():Close(CS.client.UIPaths.UI_LuaDialog);
        end)
	end)

	require("LuaUIManager").RegisterDialog("Activity/CardLottery/CardLottery", self)
end

function CardLottery.OnDestroy( ... )
	require("LuaUIManager").RemoveDialog("Activity/CardLottery/CardLottery");
end

function CardLottery:GetActivityId()
	return CardLottery.activityId
end

return CardLottery