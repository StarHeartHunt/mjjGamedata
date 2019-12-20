local json = require("json")

local LuaNetManager = {}

function LuaNetManager.SendMsg(proto)
	local pb = CS.p2dprotocol.LuaJson();
	local jsonStr = json.encode(proto);
	pb.json = jsonStr;
	CS.client.NetManager.GetInstance():SendMsg(pb);
end

return LuaNetManager