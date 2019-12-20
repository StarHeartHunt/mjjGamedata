LuaUIManager = {}

LuaUIManager.dialogs = {}

function LuaUIManager.RegisterDialog(name, dialog)
	LuaUIManager.dialogs[name] = dialog
end

function LuaUIManager.RemoveDialog(name)
	LuaUIManager.dialogs[name] = nil
end

function LuaUIManager.GetDialog(name)
	return LuaUIManager.dialogs[name]
end

return LuaUIManager