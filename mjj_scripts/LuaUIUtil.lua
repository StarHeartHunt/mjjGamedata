local LuaUIUtil = {}

function LuaUIUtil.GetAllItems(gameObject)
	local itemTable = {}
	local trans = gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Transform), true);
	print(trans.Length)
	for i = 0, trans.Length - 1 do
		itemTable[trans[i].name] = trans[i].gameObject
	end
	return itemTable;
end

function LuaUIUtil.SetButtonInteractable(btn, interactable)
	local button = btn:GetComponent(typeof(CS.UnityEngine.UI.Button));
	button.interactable = interactable;
end

return LuaUIUtil