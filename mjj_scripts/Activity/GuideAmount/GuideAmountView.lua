
local json = require("json")
local LuaUIUtil = require "LuaUIUtil"
local LuaNetManager = require "LuaNetManager"
local ActivityItemTemplate = require "p2dtemplate_lua/activityitem"
local ActivityPoolTemplate = require "p2dtemplate_lua/luapool"
local LuaTemplate = require "p2dtemplate_lua/lua"
local LuaDailyTaskTemplate = require "p2dtemplate_lua/luadaily"
local LuaMainTaskTemplate = require "p2dtemplate_lua/luamain"

local itemDic = {};
local mLuaInfo = nil;
local isRewardToggleShow = false
local activityInfoACK = {}
local mNormalCircleList = nil;
local challengeInitData = {};
local rewardInitData = {};
local mRewardMsgBox = nil;
local mRewardMsgBoxObj = nil;

function Awake( ... )
end

function Init(... )
	itemDic = LuaUIUtil.GetAllItems(self.gameObject);
	activityId = GuideAmount:GetActivityId()
	
	for k,v in pairs(LuaTemplate) do
        if v.lua_LUA_filename == "Activity/GuideAmount/GuideAmount" and v.lua_id == activityId then
            mLuaInfo = v;
        end
    end
	InitData()
	InitUI()
	RegisterGuideAmountMsg()
	GetGuideAmountActivityInfo()
	--activityInfoACK = TestTask()
	RefreshUI()
end
function Update( ... )
end

function InitData()
	if(mLuaInfo == nil) then
		return;
	end
	challengeInitData = {}
	rewardInitData = {}
	for k,v in pairs(mLuaInfo.lua_LUA_miantast) do
        if LuaMainTaskTemplate[v] ~= nil then
			local info = {}
			info.id = v
			info.completed = false;
			info.reward = false;
			info.times = 0;
			info.isMainTask = true
            if(LuaMainTaskTemplate[v].lua_mainlua_task_tapy == 0) then
				table.insert(challengeInitData,info);
			else
				table.insert(rewardInitData,info);
			end
        end
    end
	
	for k,v in pairs(mLuaInfo.lua_LUA_dailytast) do
        if LuaDailyTaskTemplate[v] ~= nil then
			local info = {}
			info.id = v
			info.completed = false;
			info.reward = false;
			info.times = 0;
			info.isMainTask = false
            if(LuaDailyTaskTemplate[v].lua_dailylua_task_tapy == 0) then
				table.insert(challengeInitData,v)
			else
				table.insert(rewardInitData,v)
			end
        end
    end
end

function InitUI()
	CS.client.Global.RegisterToggleValueChanged(itemDic.Toogle_1,OnRewardToggle)
	CS.client.Global.RegisterToggleValueChanged(itemDic.Toogle_2,OnChallengeToggle)
	mNormalCircleList = itemDic.TaskList:GetComponent(typeof(CS.client.NormalCircleList));
	mNormalCircleList:RegisterCellRefresh(OnCircleListCallback);
	
	CS.client.Global.RegisterButtonClick(itemDic.ImageFresh, function( ... )
		GetGuideAmountActivityInfo();
    end)
	
	itemDic.Toogle_1:GetComponent(typeof(CS.UnityEngine.UI.Toggle)).isOn = true
	isRewardToggleShow = true
	
	itemDic.text_nobind:SetActive(false)
	itemDic.Character:SetActive(false)
	
	mRewardMsgBox = itemDic.RewardBox.transform:Find("Award").gameObject;
    --mRewardMsgBox:SetActive(false);
    mRewardMsgBoxObj = mRewardMsgBox.transform:Find("Award").gameObject;
    mRewardMsgBoxObj:SetActive(false);

    local btnBack2 = CS.client.Global.GetGameObject(itemDic.RewardBox, "image_mask");
    CS.client.Global.RegisterButtonClick(btnBack2, function( ... )
        ResetAwards();
    end);

    local btnOK = CS.client.Global.GetGameObject(itemDic.RewardBox, "ButtonYes");
    CS.client.Global.RegisterButtonClick(btnOK, function( ... )
        ResetAwards();
    end);
	
	SetActivityInfo()
end

function OnCircleListCallback(obj, index)
	SetRewardCellInfo(obj,index)
end

function SetRewardCellInfo(obj, index)
	--LOG_INFO("**********[%s] ", ptable(activityInfoACK))
	--LOG_INFO("rewardInitData**********[%s] ", ptable(rewardInitData))
	--LOG_INFO("challengeInitData**********[%s] ", ptable(challengeInitData))
	local taskInfo = nil;
	if isRewardToggleShow then
		if(index >= #rewardInitData) then
			return
		end
		taskInfo = rewardInitData[index + 1]
	else
		if(index >= #challengeInitData) then
			return
		end
		taskInfo = challengeInitData[index + 1]
	end
	
	local taskTemplateInfo = {}
	if (taskInfo.isMainTask) then
		taskTemplateInfo = LuaMainTaskTemplate[taskInfo.id]
	else
		taskTemplateInfo = LuaDailyTaskTemplate[taskInfo.id]
	end
	print("~~~~SetRewardCellInfo taskInfo.id ",taskInfo.id)
	local taskDisableGo = CS.client.Global.GetGameObject(obj, "image_bg_disable");
	
	local button_get = CS.client.Global.GetGameObject(obj, "button_get")
	local button_tips = CS.client.Global.GetGameObject(obj, "button_tips")
	local button_gain = CS.client.Global.GetGameObject(obj, "button_gain");
	local button_undo = CS.client.Global.GetGameObject(obj, "button_undo");
	local button_completed = CS.client.Global.GetGameObject(obj, "button_completed");

	button_get:SetActive(false)
	button_tips:SetActive(false)
	button_gain:SetActive(false)
	button_undo:SetActive(false)
	button_completed:SetActive(false)
	
	local imageIconGo = CS.client.Global.GetGameObject(obj, "image_icon");
	local taskNumGo = CS.client.Global.GetGameObject(obj, "text_task_num");
	
	local itemEx = nil;
	
	if(activityInfoACK ~= nil and activityInfoACK.ret == 0) then
		taskDisableGo:SetActive(false)
		if(isRewardToggleShow) then
			if(taskInfo.completed == false ) then
				local havePath =CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):HasPathDropFrom(taskTemplateInfo.lua_path)
				if (havePath) then
					button_tips:SetActive(true)
					CS.client.Global.RegisterButtonClick(button_tips, function( ... )
						CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):TryShowInnerLinkView(taskTemplateInfo.lua_path);
					end)
				else 
					button_undo:SetActive(true)
				end

			elseif(taskInfo.completed == true and taskInfo.reward == false) then
				button_get:SetActive(true)
				CS.client.Global.RegisterButtonClick(button_get, function( ... )
					print("~~~~SetRewardCellInfo taskInfo.id ",taskInfo.id)
					GetReward(taskInfo.id)
				end)
			elseif(taskInfo.completed == true and taskInfo.reward == true) then
				button_gain:SetActive(true)
			end
		else
			if(taskInfo.completed == false) then
				local havePath =CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):HasPathDropFrom(taskTemplateInfo.lua_path)
				if (havePath) then
					button_tips:SetActive(true)
					CS.client.Global.RegisterButtonClick(button_tips, function( ... )
						CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):TryShowInnerLinkView(taskTemplateInfo.lua_path);
					end)
				else 
					button_undo:SetActive(true)
				end

			elseif(taskInfo.completed == true) then
				button_completed:SetActive(true)
				
			end
		end
		
	else
		taskDisableGo:SetActive(true)
	end
	
	itemEx = CS.client.ItemEx.CreateItemEx(taskTemplateInfo.lua_award_1_type, taskTemplateInfo.lua_award_1_par1,taskTemplateInfo.lua_award_1_par2);
	if taskInfo.isMainTask then 
		CS.client.Global.SetItemText(taskNumGo, taskInfo.times.."/"..taskTemplateInfo.lua_require_times);
		
	else 
		CS.client.Global.SetItemText(taskNumGo, taskInfo.times.."/"..taskTemplateInfo.lua_require_time);

	end
		
	if itemEx ~= nil then
		--奖励图标
		CS.client.UIAssetSpecify.LoadAndSetSprite(imageIconGo, itemEx.AssistId);

		--奖励描述
		local taskRewardDesGo = CS.client.Global.GetGameObject(obj, "text_reward");
		CS.client.Global.SetItemText(taskRewardDesGo, itemEx.Name.."x"..itemEx.Count);
	end
	
	--任务描述
	local taskDesGo = CS.client.Global.GetGameObject(obj, "text_task");
	local name = CS.TextManager.GetInstance():GetLocalizationString(taskTemplateInfo.lua_TASK_DES);
	CS.client.Global.SetItemText(taskDesGo, name);
end

function GetReward(taskId)
	print("~~~~~GetReward taskId ",taskId)
	local CrgnusTaskReward = {
        name = "CrgnusTaskReward",
		id = taskId
    }
    LuaNetManager.SendMsg(CrgnusTaskReward);
end

function OnRewardToggle(isOn)
	print("OnReward isOn ",isOn)
	isRewardToggleShow = true
	if(isOn) then
		OnReward();
	end
end
function OnChallengeToggle(isOn)
	print("OnChallenge isOn ",isOn)
	isRewardToggleShow = false
	if(isOn) then
		OnChallenge();
	end
end

function GetGuideAmountActivityInfo()
	print("~~~~~GetGuideAmountActivityInfo")
	local GetExportActivityInfo = {
        name = "GetExportActivityInfo"
    }
    LuaNetManager.SendMsg(GetExportActivityInfo);
end


function RegisterGuideAmountMsg()
	CS.client.NetManager.GetInstance():RegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK), function(obj, delayed, param)
        local ack = json.decode(obj.json);
		print("~~~~~RegisterGuideAmountMsg ",ack["name"])
		--ack = TestTask()
        if ack["name"] == "GetExportActivityInfoACK" then  -- 活动信息
            OnGuideAmountACK(ack);
        elseif ack["name"] == "ExportTaskModify" then -- 任务更改消息
            ChangeChallengeTaskACK(ack);
        elseif ack["name"] == "CrgnusTaskRewardACK" then -- 领取天鹅座任务奖励回应
            OnRewardACK(ack);
        end
    end);
end

function OnGuideAmountACK(info)
	activityInfoACK = info
 	LOG_INFO("jdd**********[%s] ", ptable(activityInfoACK))

	if(activityInfoACK == nil) then
		return
	end
	SetTaskDataByServer();
	SetCharacterInfo()
	if(activityInfoACK.ret == 0 or activityInfoACK.ret == 522 or activityInfoACK.ret == 523 or activityInfoACK.ret == 230) then --天鹅座已经绑定其他角色
		RefreshUI();
	else
		CS.client.Global.CheckServerMsgRet(activityInfoACK.ret)
	end
end

function SetTaskDataByServer()
	if(activityInfoACK ~= nil and activityInfoACK.ret == 0 and activityInfoACK.taskArray ~= nil) then
		for k,v in pairs(activityInfoACK.taskArray) do
			for tk,tv in pairs(challengeInitData) do
				if(v.id == tv.id) then
					tv.times = v.times
					if(v.reward) then
						tv.reward = v.reward
					end
					
					tv.completed = v.completed
				end
			end
		end
	end
	
	if(activityInfoACK ~= nil and activityInfoACK.ret == 0 and activityInfoACK.crgnusMsg ~= nil and activityInfoACK.crgnusMsg.tasks ~= nil) then
		for k,v in pairs(activityInfoACK.crgnusMsg.tasks) do
			for tk,tv in pairs(rewardInitData) do
				if(v.id == tv.id) then
					tv.times = v.times
					if(v.reward) then
						tv.reward = v.reward
					end
					tv.completed = v.completed
				end
			end
		end
	end
end

function SetCharacterInfo()
	itemDic.text_nobind:SetActive(false)
	itemDic.Character:SetActive(false)
	
	if activityInfoACK == nil then
		return
	end
	local hint = ""
	if(activityInfoACK.ret == 522)  then --天鹅座已经绑定其他角色
		hint = CS.TextManager.GetInstance():GetLocalizationString(124920);
	elseif(activityInfoACK.ret == 523) then --天鹅座还没有绑定
		hint = CS.TextManager.GetInstance():GetLocalizationString(124922);
	elseif(activityInfoACK.ret == 230) then --用户等级不够
		hint = CS.TextManager.GetInstance():GetLocalizationString(124921);
	end
	if(activityInfoACK.ret == 0) then
		itemDic.Character:SetActive(true)

		local serverNameGo = CS.client.Global.GetGameObject(itemDic.Character, "TextServer");
		CS.client.Global.SetItemText(serverNameGo, activityInfoACK.crgnusMsg.playerServerName);

		local playerNameGo = CS.client.Global.GetGameObject(itemDic.Character, "TextName");
		CS.client.Global.SetItemText(playerNameGo, activityInfoACK.crgnusMsg.playerName);

		local playerLevelGo = CS.client.Global.GetGameObject(itemDic.Character, "TextLV");
		CS.client.Global.SetItemText(playerLevelGo,tostring(activityInfoACK.crgnusMsg.playerLevel));
	else
		itemDic.text_nobind:SetActive(true)
		CS.client.Global.SetItemText(itemDic.text_nobind, hint);
	end
	
end

function RefreshUI()
	if(isRewardToggleShow) then
		OnReward()
	else
		OnChallenge()
	end
end

function ChangeChallengeTaskACK(intfo)
	LOG_INFO("11111111challengeInitData**********[%s] ", ptable(challengeInitData))
	for k,v in pairs(challengeInitData ) do
		for tk,tv in pairs(intfo.modifyArray ) do
			if(v.id == tv.id) then
				v.completed = tv.completed
				if(v.reward) then
					v.reward = tv.reward
				end
				v.times = tv.times
			end
		end
	end
	LOG_INFO("2222222challengeInitData**********[%s] ", ptable(challengeInitData))
	OnChallenge();
end

--挑战页签
function OnChallenge() 
	print("OnChallenge "..#challengeInitData);
	table.sort(challengeInitData,SortChallenge)
	mNormalCircleList:InitListByCellCount(#challengeInitData)
end
function SortChallenge(a, b)
	local sort1 = 0;
	local sort2 = 0;
	if(a.completed) then
		sort1 = 1;
	end
	if(b.completed) then
		sort2 = 1;
	end
	return sort1 < sort2;
end

--奖励页签
function OnReward()
	print("OnReward "..#rewardInitData);
	table.sort(rewardInitData,SortReward)
	mNormalCircleList:InitListByCellCount(#rewardInitData);
end
function SortReward(a, b)
	local sort1 = 0;
	local sort2 = 0;
	if(a.reward) then
		sort1 = 1;
	end
	if(b.reward) then
		sort2 = 1;
	end
	return sort1 < sort2;
end

function OnRewardACK(info)
	LOG_INFO("33333333rewardInitData**********[%s] ", ptable(rewardInitData))
	GetGuideAmountActivityInfo();
	for k,v in pairs(rewardInitData) do
		if(v.id == info.id ) then
			v.reward = true;
		end
	end
	LOG_INFO("444444444rewardInitData**********[%s] ", ptable(rewardInitData))
	ShowAwards(info);
	RefreshUI();
end

function OnDestroy( ... )
	CS.client.NetManager.GetInstance():UnRegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK));
end


function SetActivityInfo()
	--设置活动名字
	local nameGo = CS.client.Global.GetGameObject(itemDic.Top, "text_title");
    local name = CS.TextManager.GetInstance():GetLocalizationString(mLuaInfo.lua_LUA_name);
    CS.client.Global.SetItemText(nameGo, name);
	--设置活动背景图
	local imgNode = itemDic.RewardsBanner;
    CS.client.UIAssetSpecify.LoadAndSetSprite(imgNode, mLuaInfo.lua_LUA_picture);
	
end
--[[
function SetActivityRule()
    CS.client.Global.RegisterButtonClick(itemDic.ButtonTips, function( ... )
		local id = CS.System.UInt32.Parse("122600")
		CS.client.UIManager.GetInstance():Show("uihelp",122600,CS.client.LOADING_TYPE.NONE);
		
    end)
end]]

function ShowAwards(info)
	LOG_INFO("55555555ShowAwards**********[%s] ", ptable(info))
    itemDic.RewardBox:SetActive(true);
    
    --[[for i = 1, #info do
        local itemGo = CS.UnityEngine.GameObject.Instantiate(mRewardMsgBoxObj);
        itemGo:SetActive(true);
        itemGo.transform:SetParent(mRewardMsgBoxObj.transform.parent, false);
        itemGo.name = mRewardMsgBoxObj.name..tostring(i);
        local UIItem = CS.client.UIItem(itemGo);
        local ItemEx = CS.client.ItemEx.CreateItemEx(info[i].category, info[i].id, info[i].num);
        UIItem:SetItem(ItemEx);
    end]]
	
	local itemGo = CS.UnityEngine.GameObject.Instantiate(mRewardMsgBoxObj);
	itemGo:SetActive(true);
	itemGo.transform:SetParent(mRewardMsgBoxObj.transform.parent, false);
	itemGo.name = mRewardMsgBoxObj.name..tostring(i);
	local UIItem = CS.client.UIItem(itemGo);
	local ItemEx = CS.client.ItemEx.CreateItemEx(info.award.category, info.award.id, info.award.num);
	UIItem:SetItem(ItemEx);
end

function ResetAwards()
    itemDic.RewardBox:SetActive(false);
    for i = 1, mRewardMsgBox.transform.childCount - 1 do
        CS.UnityEngine.Object.Destroy(mRewardMsgBox.transform:GetChild(i).gameObject);
    end
end