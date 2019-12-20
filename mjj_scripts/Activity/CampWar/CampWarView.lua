local json = require("json")
local LuaUIUtil = require "LuaUIUtil"
local LuaNetManager = require "LuaNetManager"
local ActivityItemTemplate = require "p2dtemplate_lua/activityitem"
local ActivityPoolTemplate = require "p2dtemplate_lua/luapool"
local LuaTemplate = require "p2dtemplate_lua/lua"
local LuaDailyTaskTemplate = require "p2dtemplate_lua/luadaily"
local LuaMainTaskTemplate = require "p2dtemplate_lua/luamain"
local LuaZhenYingZhanTemplate = require "p2dtemplate_lua/luazhenyingzhan";
local LuaZhenYingTemplate = require "p2dtemplate_lua/luazhenying";
local LuaGiftRewardTemplate = require "p2dtemplate_lua/luareward";

local itemDic = {};
local mLuaInfo = nil;
local mLuaCampWarInfo = nil;
local mLuaCampInfo = nil;

local mCampIconNormalCircleList = nil;
local mCampRankNormalCircleList = nil;
local mPlayerRankNormalCircleList = nil;
local mGiftRewardNormalCircleList = nil;
local mTaskNormalCircleList = nil;

local selectCampIndex = 0;
local campActivityInfoACK = {}
local isCampRankToggleShow = false
local giftCycle = 5
local campCount = 4
local campIdProcessed = {}
local CampBgItems = {}
local mLuaGiftRewardData = {}



function Awake( ... )
end

function Init(... )
	itemDic = LuaUIUtil.GetAllItems(self.gameObject);
	activityId = CampWar:GetActivityId()
	
	for k,v in pairs(LuaTemplate) do
        if v.lua_LUA_filename == "Activity/CampWar/CampWar" and v.lua_id == activityId then
            mLuaInfo = v;
        end
    end
	--TestData()
	InitData()
	InitUI()
	RegisterCampMsg()
	GetCampActivityInfo()
	RefreshUI()
end

function TestData()
	campActivityInfoACK.camp = {}
	campActivityInfoACK.camp.campId = 137324
	--campActivityInfoACK.camp.campId = 0
	campActivityInfoACK.camp.campRank = {
		[1] = {
				campId = 137323, 							--阵容ID
				popular = 1111, 						--贡献值
			},
		[2] = {
			campId = 137324, 							--阵容ID
			popular = 2222, 						--贡献值
		},
		[3] = {
				campId = 137325, 							--阵容ID
				popular = 3333, 						--贡献值
			},
		[4] = {
				campId = 137326, 							--阵容ID
				popular = 4444, 						--贡献值
			},
	}
	campActivityInfoACK.camp.userRank = {
		[1] = {
				name = 1, 								--名字
				icon = 29544, 								--头像
				frame  = 3,      						--头像框
				popular = 1111, 						--贡献值
			},
		[2] = {
				name = 2, 								--名字
				icon = 29547, 								--头像
				frame  = 4,      						--头像框
				popular = 2222, 						--贡献值
			},
		[3] = {
				name = 3, 								--名字
				icon = 29550, 								--头像
				frame  = 5,      						--头像框
				popular = 3333, 						--贡献值
			},
	}
	campActivityInfoACK.camp.myRank = 2
	campActivityInfoACK.camp.popular = 2222
	campActivityInfoACK.camp.days = 9
	campActivityInfoACK.camp.rewardDays = {
		1,2,3,4,5,6,8
	}
	
	campActivityInfoACK.taskArray = {
		[1] = {
					id = 120828,									-- 任务ID
					completed = false,			-- 是否已完成
					reward = false,				-- 是否已领取奖励
					times = 1,								-- 任务的进度
			},
		[2] = {
					id = 120974,									-- 任务ID
					completed = true,			-- 是否已完成
					reward = false,				-- 是否已领取奖励
					times = 1,								-- 任务的进度
			},
		[3] = {
					id = 120975,									-- 任务ID
					completed = true,			-- 是否已完成
					reward = true,				-- 是否已领取奖励
					times = 1,								-- 任务的进度
			},
	}
	
end

function Update( ... )
end

function InitData()
	if(LuaZhenYingZhanTemplate[mLuaInfo.lua_associated_ID] ~= nil) then
		mLuaCampWarInfo = LuaZhenYingZhanTemplate[mLuaInfo.lua_associated_ID]
		local tmpLuaGiftRewardData = {}
		local index  = 1
		for key, value in pairs(LuaGiftRewardTemplate) do
			table.insert(mLuaGiftRewardData,value)
			index = index +1
		end

		table.sort(mLuaGiftRewardData,SortGiftRewardTemplate)
	end
end

function InitUI()
	local camp1 = CS.client.Global.GetGameObject(itemDic.Camp_1, "ButtonJoin");
    CS.client.Global.RegisterButtonClick(camp1, function( ... )
        JoinCamp1();
    end,2);
	local camp2 = CS.client.Global.GetGameObject(itemDic.Camp_2, "ButtonJoin");
    CS.client.Global.RegisterButtonClick(camp2, function( ... )
        JoinCamp2();
    end,2);
	local camp3 = CS.client.Global.GetGameObject(itemDic.Camp_3, "ButtonJoin");
    CS.client.Global.RegisterButtonClick(camp3, function( ... )
        JoinCamp3();
    end,2);
	local camp4= CS.client.Global.GetGameObject(itemDic.Camp_4, "ButtonJoin");
    CS.client.Global.RegisterButtonClick(camp4, function( ... )
        JoinCamp4();
    end,2);
	local campInfoBack= CS.client.Global.GetGameObject(itemDic.CampInfo, "ButtonCancle");
    CS.client.Global.RegisterButtonClick(campInfoBack, function( ... )
        CampInfoBack();
    end);
	
	local campInfoJoin= CS.client.Global.GetGameObject(itemDic.CampInfo, "ButtonJoin");
    CS.client.Global.RegisterButtonClick(campInfoJoin, function( ... )
        OnJoinCamp();
    end);
	
	local joinMsgBoxOk= CS.client.Global.GetGameObject(itemDic.Join_MsgBox, "ButtonYes");
    CS.client.Global.RegisterButtonClick(joinMsgBoxOk, function( ... )
        OnJoinMsgBoxOk();
    end);
	
	local joinMsgBoxCancel= CS.client.Global.GetGameObject(itemDic.Join_MsgBox, "ButtonNo");
    CS.client.Global.RegisterButtonClick(joinMsgBoxCancel, function( ... )
        OnJoinMsgBoxCancel();
    end);
	
	CS.client.Global.RegisterToggleValueChanged(itemDic.Toogle_1,OnCampRankToogle)
	CS.client.Global.RegisterToggleValueChanged(itemDic.Toogle_2,OnPlayerRankToogle)
	
	local campRankRewardBtn= CS.client.Global.GetGameObject(itemDic.RankListNode_Camp, "Reward_Btn_Camp");
	CS.client.Global.RegisterButtonClick(campRankRewardBtn, function( ... )
        OnShowCampRankReward();
    end);
	
	local playerRankRewardBtn= CS.client.Global.GetGameObject(itemDic.RankListNode_Player, "Reward_Btn_Player")
	CS.client.Global.RegisterButtonClick(playerRankRewardBtn, function( ... )
        OnShowPlayerRankReward();
    end);
	
	local campRankRewardImageBlackGo= CS.client.Global.GetGameObject(itemDic.Reward_detail_Camp, "image_black")
	CS.client.Global.RegisterButtonClick(campRankRewardImageBlackGo, function( ... )
        OnHideCampRankRewardImageBlack()
    end);
	
	local playerRankRewardImageBlackGo= CS.client.Global.GetGameObject(itemDic.Reward_detail_Player, "image_black")
	CS.client.Global.RegisterButtonClick(playerRankRewardImageBlackGo, function( ... )
        OnHidePlayerRankRewardImageBlack()
    end);
	

	mCampIconNormalCircleList = itemDic.scrollview_icon:GetComponent(typeof(CS.client.NormalCircleList));
	mCampIconNormalCircleList:RegisterCellRefresh(OnCampIconCircleListCallback);
	
	mCampRankNormalCircleList = itemDic.ScrollView_CampRank:GetComponent(typeof(CS.client.NormalCircleList));
	mCampRankNormalCircleList:RegisterCellRefresh(OnCampRankCircleListCallback);
	
	mPlayerRankNormalCircleList = itemDic.ScrollView_PlayerRank:GetComponent(typeof(CS.client.NormalCircleList));
	mPlayerRankNormalCircleList:RegisterCellRefresh(OnPlayerRankCircleListCallback);
	
	mGiftRewardNormalCircleList = itemDic.ScrollView_Bonus:GetComponent(typeof(CS.client.NormalCircleList));
	mGiftRewardNormalCircleList:RegisterCellRefresh(OnGiftRewardCircleListCallback);

	mTaskNormalCircleList = itemDic.TaskList:GetComponent(typeof(CS.client.NormalCircleList));
	mTaskNormalCircleList:RegisterCellRefresh(OnTaskCircleListCallback);
	
	local nameNode = CS.client.Global.GetGameObject(itemDic.Top, "text_title");
    local name = CS.TextManager.GetInstance():GetLocalizationString(mLuaInfo.lua_LUA_name);
    CS.client.Global.SetItemText(nameNode, name);
	
	CS.client.Global.RegisterButtonClick(itemDic.button_gift, function( ... )
        OnShowGiftReward();
    end);
	
	local giftRewardAutoCloseGo= CS.client.Global.GetGameObject(itemDic.RankBonus, "image_mask")
	CS.client.Global.RegisterButtonClick(giftRewardAutoCloseGo, function( ... )
        AutoCloseGiftReward()
    end);
	
	for i=1,giftCycle do
		local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Can_Reward")
		CS.client.Global.RegisterButtonClick(boxCanReward, function( ... )
			GetCampDailyReward(i)
		end);
	end
	for i=1,campCount do
		CampBgItems["CampBg"..i] = CS.client.Global.GetGameObject(itemDic["Camp_"..i], "CampBg");
		CampBgItems["CampBg"..i]:SetActive(false)
	end

	CS.client.Global.RegisterButtonClick(itemDic.ButtonJoinCamp, function( ... )
		ShowCampInfo()
	end);
	selectCampIndex = 0;
end

function GetCampActivityInfo()
	--print("~~~~~GetCampActivityInfo")
	local CSGetCampActivityInfo = {
        name = "CSGetCampActivityInfo"
    }
    LuaNetManager.SendMsg(CSGetCampActivityInfo);
end

function RegisterCampMsg()
	CS.client.NetManager.GetInstance():RegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK), function(obj, delayed, param)
        local ack = json.decode(obj.json);
		--print("~~~~~RegisterCampMsg ",ack["name"])
		--ack = TestTask()
		LOG_DEBUG("!!!!!!!RegisterCampMsg info:%s", ptable(ack))
        if ack["name"] == "SCGetCampActivityInfo" then  -- 活动信息
            OnGetCampActivityInfoACK(ack);
        end
		if ack["name"] == "SCCampTaskReward" then  -- 任务奖励回应
            OnCampTaskRewardACK(ack);
        end
		if ack["name"] == "SCTaskModify" then  -- 任务改变回应
            OnTaskModifyACK(ack);
        end
		if ack["name"] == "SCCampDailyReward" then  -- 领奖宝箱回应
            OnCampDailyRewardACK(ack);
        end
		if ack["name"] == "SCCampID" then  -- 加入阵营回应
            OnJoinCampACK(ack);
        end
    end);
end

function GetCampTaskReward(taskId)
	--print("~~~~~GetCampTaskReward taskId ",taskId)
	local CSCampTaskReward = {
        name = "CSCampTaskReward",
		id = taskId
    }
    LuaNetManager.SendMsg(CSCampTaskReward);
end

function GetCampDailyReward(index)
	--print("~~~~~CSCampDailyReward index ",index)
	local day = campActivityInfoACK.camp.days + 1;
	--print("~~~~~CSCampDailyReward day ",day)
	local CSCampDailyReward = {
        name = "CSCampDailyReward",
		days = day
    }
	LuaNetManager.SendMsg(CSCampDailyReward);
end

function OnCampTaskRewardACK(info)
	if(info ~= nil and info.award ~= nil) then
		local items =  CS.System.Collections.Generic["List`1[p2dprotocol.ItemDis]"]()
		local item = CS.p2dprotocol.ItemDis()
		item.category = info.award.category;
		item.id = info.award.id;
		item.num = info.award.num;
		items:Add(item);
		CS.client.CommonRewardView.Show(items);
	end
	
end

function OnTaskModifyACK(info)
	--[[if(campActivityInfoACK ~= nil and campActivityInfoACK.taskArray ~=nil) then
		local existTask = false
		if(info ~= nil and info.modifyArray ~= nil) then
			for i=1,#info.modifyArray  do
				for j=1,#campActivityInfoACK.taskArray do
					existTask = false
					if(campActivityInfoACK.taskArray[j].id == info.modifyArray[i].id) then
						existTask = true
						campActivityInfoACK.taskArray[j].completed = info.modifyArray[i].completed
						campActivityInfoACK.taskArray[j].reward = info.modifyArray[i].reward
						campActivityInfoACK.taskArray[j].times = info.modifyArray[i].times
						break
					end
				end
				if(existTask == false) then
					local index = #campActivityInfoACK.taskArray + 1
					campActivityInfoACK.taskArray[index] = {}
					campActivityInfoACK.taskArray[index].id = info.modifyArray[i].id
					campActivityInfoACK.taskArray[index].completed = info.modifyArray[i].completed
					campActivityInfoACK.taskArray[index].reward = info.modifyArray[i].reward
					campActivityInfoACK.taskArray[index].times = info.modifyArray[i].times
				end
			end
		end
	end
	RefreshUI()]]
	GetCampActivityInfo();
end

function OnGetCampActivityInfoACK(info)
	campActivityInfoACK = info
	RefreshUI()
end

function OnCampDailyRewardACK(info)
	if(info ~= nil) then
		if(info.awardArray ~= nil) then
			local items =  CS.System.Collections.Generic["List`1[p2dprotocol.ItemDis]"]()
			for i=1,#info.awardArray do
				local item = CS.p2dprotocol.ItemDis()
				item.category = info.awardArray[i].category;
				item.id = info.awardArray[i].id;
				item.num = info.awardArray[i].num;
				items:Add(item);
			end
			CS.client.CommonRewardView.Show(items);
		end
	end
	
	GetCampActivityInfo();
end

function OnJoinCampACK(info)
	if(info ~= nil) then
		if(info.awardArray ~= nil) then
			local items =  CS.System.Collections.Generic["List`1[p2dprotocol.ItemDis]"]()
			for i=1,#info.awardArray do
				local item = CS.p2dprotocol.ItemDis()
				item.category = info.awardArray[i].category;
				item.id = info.awardArray[i].id;
				item.num = info.awardArray[i].num;
				items:Add(item);
			end
			CS.client.CommonRewardView.Show(items);
		end
		if(info.ret == 0) then
			GetCampActivityInfo()
		end
	end
end

function RefreshUI()
	if(campActivityInfoACK~= nil) then
		if(campActivityInfoACK.camp ~= nil) then
			if(campActivityInfoACK.camp.campId == 0) then
				ShowCampJoin()
			elseif(campActivityInfoACK.camp.campId > 0) then
				ShowCampJoined()
			end
		end
	end
end

function ShowCampJoin()
	itemDic.Animator_Join:SetActive(true)
	itemDic.Animator_Joined:SetActive(false)
	for i=1,campCount do
		local campId = mLuaCampWarInfo.lua_camp_list[i]
		if(LuaZhenYingTemplate[campId] ~= nil) then
			local assetid = LuaZhenYingTemplate[campId].lua_entry_pic
			if(itemDic["Camp_"..tostring(i)] ~= nil) then
				local campBgGo = CS.client.Global.GetGameObject(itemDic["Camp_"..tostring(i)], "CampBg");
				--CS.client.UIAssetSpecify.LoadAndSetSprite(campBgGo, assetid)
			end
		end
	end
	local campWarDesGo = CS.client.Global.GetGameObject(itemDic.IntroduceNode, "Content");
	local campDes = CS.TextManager.GetInstance():GetLocalizationString(mLuaCampWarInfo.lua_event_info);
	CS.client.Global.SetItemText(campWarDesGo, campDes);
end

function ShowCampJoined()
	itemDic.Animator_Join:SetActive(false)
	itemDic.Animator_Joined:SetActive(true)
	--itemDic.Toogle_1:GetComponent(typeof(CS.UnityEngine.UI.Toggle)).isOn = true
	if(itemDic.Toogle_2:GetComponent(typeof(CS.UnityEngine.UI.Toggle)).isOn) then
		OnPlayerRankToogle(true)
	else
		OnCampRankToogle(true)
	end
	
	RefreshTask()
	RefreshGift()
end

function JoinCamp1()
	ClickCamp(1)
end
function JoinCamp2()
	ClickCamp(2)
end
function JoinCamp3()
	ClickCamp(3)
end
function JoinCamp4()
	ClickCamp(4)
end

function CampInfoBack()
	CancelSelectCamp()
	itemDic.CampListNode:SetActive(true)
	itemDic.CampInfo:SetActive(false)
end

function CancelSelectCamp()
	selectCampIndex = 0
	for i=1,campCount do
		CampBgItems["CampBg"..i]:SetActive(false)
	end
end

function ClickCamp(campIndex)
	selectCampIndex = campIndex;
	for i=1,campCount do
		CampBgItems["CampBg"..i]:SetActive(false)
	end
	CampBgItems["CampBg"..campIndex]:SetActive(true)
end

function ShowCampInfo()
	if(selectCampIndex == 0 or selectCampIndex > 4) then
		local title = CS.TextManager.GetInstance():GetLocalizationString(142286);
		CS.client.MsgBoxOkView.Show(title);
		return
	end
	itemDic.CampListNode:SetActive(false)
	itemDic.CampInfo:SetActive(true)
	
	local campId = mLuaCampWarInfo.lua_camp_list[selectCampIndex]
	if(LuaZhenYingTemplate[campId] ~= nil) then
		mLuaCampInfo = LuaZhenYingTemplate[campId]
		mCampIconNormalCircleList:InitListByCellCount(#mLuaCampInfo.lua_camp_char)
	end

	local campDes = CS.TextManager.GetInstance():GetLocalizationString(mLuaCampInfo.lua_camp_discribe);
	CS.client.Global.SetItemText(itemDic.Text_Introduce, campDes);
end

function OnJoinCamp()
	itemDic.Join_MsgBox:SetActive(true)
end

function OnJoinMsgBoxOk()
	--print("~~~~~CSCampID")
	local CSGetCampActivityInfo = {
        name = "CSCampID",
		campId = mLuaCampInfo.lua_id
    }
    LuaNetManager.SendMsg(CSGetCampActivityInfo);
end
function OnJoinMsgBoxCancel()
	selectCampIndex = 0
	itemDic.Join_MsgBox:SetActive(false)
	CampInfoBack()
end

function OnCampIconCircleListCallback(obj, index)
	SetCampIconCellInfo(obj,index)
end

function SetCampIconCellInfo(obj, index)
	if(index < #mLuaCampInfo.lua_camp_char) then
		local id = mLuaCampInfo.lua_camp_char[index+1]
		local assetid = CS.client.CardUtility.GetIconAssetId(id,true)
		local imageIconGo = CS.client.Global.GetGameObject(obj, "image_role_icon")
		CS.client.UIAssetSpecify.LoadAndSetSprite(imageIconGo, assetid)
		
		local character = CS.TemplateManager.GetInstance():GetCharacter(id)
		assetid = CS.client.CardUtility.GetRoundCardFrameAssetIdByFrameId(character.frame)
		local imageFrameGo = CS.client.Global.GetGameObject(obj, "image_role_default_frame")
		CS.client.UIAssetSpecify.LoadAndSetSprite(imageFrameGo, assetid)
		
		local nameGo = CS.client.Global.GetGameObject(obj, "text_name");
		local name = CS.TextManager.GetInstance():GetLocalizationString(character.NAME);
		CS.client.Global.SetItemText(nameGo, name);
	end
	
end

function OnCampRankCircleListCallback(obj, index)
	SetCampRankCellInfo(obj,index)
end

function SetCampRankCellInfo(obj, index)
	if(index < #campActivityInfoACK.camp.campRank) then
		local info = campActivityInfoACK.camp.campRank[index+1]
		local rankGo = CS.client.Global.GetGameObject(obj, "text_rank")
		local noneGo = CS.client.Global.GetGameObject(obj, "text_none")
		rankGo:SetActive(true)
		noneGo:SetActive(false)
		
		CS.client.Global.SetItemText(rankGo, tostring(index+1));
		
		local popularNumGo = CS.client.Global.GetGameObject(obj, "text_popularity_num")
		CS.client.Global.SetItemText(popularNumGo, tostring(info.popular));
		
		local campId = tonumber(info.campId)
		if(LuaZhenYingTemplate[campId] ~= nil) then
			local campInfo = LuaZhenYingTemplate[campId]
			if(campInfo ~= nil) then
				local campIconGo = CS.client.Global.GetGameObject(obj, "image_icon");
				CS.client.UIAssetSpecify.LoadAndSetSprite(campIconGo, campInfo.lua_rank_pic)
				local campDes = CS.TextManager.GetInstance():GetLocalizationString(campInfo.lua_camp_name);
				local campNameGo = CS.client.Global.GetGameObject(obj, "text_camp_name");
				CS.client.Global.SetItemText(campNameGo, campDes);
			end
		end
		campIdProcessed[campId] = campId;
	elseif(index < campCount) then
		local rankGo = CS.client.Global.GetGameObject(obj, "text_rank")
		local noneGo = CS.client.Global.GetGameObject(obj, "text_none")
		rankGo:SetActive(false)
		noneGo:SetActive(true)
		local popularNumGo = CS.client.Global.GetGameObject(obj, "text_popularity_num")
		CS.client.Global.SetItemText(popularNumGo, "0");
		
		local campId = 0;
		for i=1,#mLuaCampWarInfo.lua_camp_list do
			local id = tonumber(mLuaCampWarInfo.lua_camp_list[i])
			if(campIdProcessed[id] == nil) then
				campId = id
				campIdProcessed[campId] = campId;
				if(LuaZhenYingTemplate[campId] ~= nil) then
					local campInfo = LuaZhenYingTemplate[campId]
					if(campInfo ~= nil) then
						local campIconGo = CS.client.Global.GetGameObject(obj, "image_icon");
						CS.client.UIAssetSpecify.LoadAndSetSprite(campIconGo, campInfo.lua_rank_pic)
						local campDes = CS.TextManager.GetInstance():GetLocalizationString(campInfo.lua_camp_name);
						local campNameGo = CS.client.Global.GetGameObject(obj, "text_camp_name");
						CS.client.Global.SetItemText(campNameGo, campDes);
						break;
					end
				end
			end
		end
	end
end

function OnPlayerRankCircleListCallback(obj, index)
	SetPlayerRankCellInfo(obj,index)
end

function SetPlayerRankCellInfo(obj, index)
	if(index < #campActivityInfoACK.camp.userRank) then
		local info = campActivityInfoACK.camp.userRank[index+1]

		local nameGo = CS.client.Global.GetGameObject(obj, "text_player_name");
		CS.client.Global.SetItemText(nameGo, info.name);
		
		local popularNumGo = CS.client.Global.GetGameObject(obj, "text_Score_num")
		CS.client.Global.SetItemText(popularNumGo, tostring(info.popular));
		
		local rankGo = CS.client.Global.GetGameObject(obj, "text_rank")
		CS.client.Global.SetItemText(rankGo, tostring(index+1));
		
		local frameBg =  CS.client.Global.GetGameObject(obj,"Image_frame_bg");
		local frame =  CS.client.Global.GetGameObject(obj,"image_frame");
		local icon =  CS.client.Global.GetGameObject(obj,"image_icon");
		local frameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel));
		local  frameTemp = CS.TemplateManager.GetInstance():GetFrameById(info.frame);
		if frameTemp ~= nil then
			if frameModel:IsFrameLimit(frameTemp) and not frameModel:IsFrameCanOpen(frameTemp) then
				local id = frameModel:GetLucentFrameId();
				frameTemp = CS.TemplateManager.GetInstance():GetFrameById(id);
			end
		end
		--头像背景框
		CS.client.UIAssetSpecify.LoadAndSetSprite(frameBg, frameTemp.bkg_id);
		--头像框
		CS.client.UIAssetSpecify.LoadAndSetSprite(frame, frameTemp.pic_id);
		--头像
		local  profileTemp = CS.TemplateManager.GetInstance():GetProfileById(info.icon);
		  CS.client.UIAssetSpecify.LoadAndSetSprite(icon,profileTemp.pic_id);
	end
end

function OnGiftRewardCircleListCallback(obj, index)
	SetGiftRewardCellInfo(obj,index)
end

function SetGiftRewardCellInfo(obj,index)
	local tmpIndex = index +1
	local giftStr = CS.TextManager.GetInstance():GetLocalizationString(142801);
	local giftRewardDayGo = CS.client.Global.GetGameObject(obj, "text_info_name");
	CS.client.Global.SetItemText(giftRewardDayGo, string.format(giftStr,tostring(tmpIndex)));
	local giftData = mLuaGiftRewardData[tmpIndex]
	local ItemObj = {}
	ItemObj[1] = CS.client.Global.GetGameObject(obj, "ItemObj1");
	ItemObj[2] = CS.client.Global.GetGameObject(obj, "ItemObj2");
	ItemObj[3] = CS.client.Global.GetGameObject(obj, "ItemObj3");
	for i=1,3 do
		ItemObj[i]:SetActive(false)
	end
	for i=1,#giftData.lua_item_type do
		ItemObj[i]:SetActive(true)
		local UIItem = CS.client.UIItem(ItemObj[i]);
		local ItemEx = CS.client.ItemEx.CreateItemEx(giftData.lua_item_type[i], giftData.lua_item_id[i], giftData.lua_item_amount[i], true);
		UIItem:SetItem(ItemEx);
	end
	
end

function SetMyRankInfo()
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp ~= nil) then
		local rankGo = CS.client.Global.GetGameObject(itemDic.MyRank, "text_rank_num")
		local rankNoneGo = CS.client.Global.GetGameObject(itemDic.MyRank, "text_none")
		
		local myRank = 0;
		local myPopular = 0;
		if(campActivityInfoACK.camp.myRank >= 0) then
			myRank = campActivityInfoACK.camp.myRank + 1
			
			rankGo:SetActive(true)
			rankNoneGo:SetActive(false)
			
			CS.client.Global.SetItemText(rankGo, tostring(myRank))
		else
			rankGo:SetActive(false)
			rankNoneGo:SetActive(true)
		end
		if(campActivityInfoACK.camp.popular ~= nil) then
			myPopular = campActivityInfoACK.camp.popular
		end
		
		
		local popularNumGo = CS.client.Global.GetGameObject(itemDic.MyRank, "text_Score_num")
		CS.client.Global.SetItemText(popularNumGo, tostring(myPopular));
		local roleIconFrameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel))
		if(roleIconFrameModel ~= nil) then
			if(roleIconFrameModel.CurIcon ~= nil and roleIconFrameModel.CurIcon.AssetId ~= nil) then
				local imageIconGo = CS.client.Global.GetGameObject(itemDic.MyRank, "image_icon")
				CS.client.UIAssetSpecify.LoadAndSetSprite(imageIconGo, roleIconFrameModel.CurIcon.AssetId)
			end
			if(roleIconFrameModel.CurFrame ~= nil and roleIconFrameModel.CurFrame.FlowerAssetId ~= nil) then
				local imageFrameGo = CS.client.Global.GetGameObject(itemDic.MyRank, "image_frame")
				CS.client.UIAssetSpecify.LoadAndSetSprite(imageFrameGo, roleIconFrameModel.CurFrame.FlowerAssetId)	
				
				local imageFrameBgGo = CS.client.Global.GetGameObject(itemDic.MyRank, "Image_frame_bg")
				CS.client.UIAssetSpecify.LoadAndSetSprite(imageFrameBgGo, roleIconFrameModel.CurFrame.BGAssetId)
			end
		end
		
	end
end

function RefreshTask()
	if(campActivityInfoACK ~= nil and campActivityInfoACK.taskArray~= nil ) then
		--print("RefreshTask "..#campActivityInfoACK.taskArray);
		table.sort(campActivityInfoACK.taskArray,SortTask)
		mTaskNormalCircleList:InitListByCellCount(#campActivityInfoACK.taskArray);
	end
end

function SortTask(a,b)
	local aTaskType = 0;
	local bTaskType = 0;
	if(LuaMainTaskTemplate[a.id] == nil) then
		aTaskType = 1;
	end
	if(LuaMainTaskTemplate[a.id] == nil) then
		bTaskType = 1;
	end
	
	local aRewardState = 0;
	local bRewardState = 0;
	
	if(a.reward == true) then
		aRewardState = 1;
	end
	if(b.reward == true) then
		bRewardState = 1;
	end
	
	local aCompletedState = 0;
	local bCompletedState = 0;
	
	if(a.completed == true) then
		aCompletedState = 1;
	end
	if(b.completed == true) then
		bCompletedState = 1;
	end

	local aOrder = 0;
	local bOrder = 0;
	if(LuaMainTaskTemplate[a.id] ~= nil) then
		aOrder = LuaMainTaskTemplate[a.id].lua_maintask_order
	elseif(LuaDailyTaskTemplate[a.id] ~= nil) then
		aOrder = LuaDailyTaskTemplate[a.id].lua_dailytask_order
	end
	
	if(LuaMainTaskTemplate[a.id] ~= nil) then
		bOrder = LuaMainTaskTemplate[b.id].lua_maintask_order
	elseif(LuaDailyTaskTemplate[a.id] ~= nil) then
		bOrder = LuaDailyTaskTemplate[b.id].lua_dailytask_order
	end
	
	if(aRewardState ~= bRewardState) then
		return aRewardState < bRewardState
	elseif(aCompletedState ~=bCompletedState) then
		return aCompletedState > bCompletedState
	elseif(aTaskType ~= bTaskType) then
		return aTaskType > bTaskType
	else 
		return aOrder > bOrder
	end

	
	--[[if(aCompletedState > bCompletedState) then
		return false
	elseif(aCompletedState < bCompletedState) then
		return true
	elseif(aCompletedState == bCompletedState) then
		if(aTaskType > bTaskType) then
			return true;
		elseif(aTaskType < bTaskType) then
			return false;
		elseif(aTaskType == bTaskType) then
			return aOrder > bOrder
		end
	end]]
end

function GetRewardBoxMinMaxDay()
	local minDay = 1
	local maxDay = giftCycle
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp ~= nil ) then
			if(campActivityInfoACK.camp.days  > 0) then
				local canGetRewardMinDay = 1
				--先寻找到可以领取奖励但还没领取的最小day
				
				if(campActivityInfoACK.camp.rewardDays ~= nil) then
					local getReward = false
					for i=1,campActivityInfoACK.camp.days do
						getReward = IsGetReward(i)
						if(getReward == false) then
							canGetRewardMinDay = i
							break;
						end
					end
				end
				
				maxDay = (math.modf( canGetRewardMinDay / giftCycle ) + 1) * giftCycle 
				minDay = maxDay - giftCycle +1 
		end
	end
	
	if(minDay<=0) then
		minDay = 1
	end
	if(maxDay > minDay + giftCycle - 1)then
		maxDay = minDay + giftCycle - 1
	end
	return minDay,maxDay
end
function RefreshGift()
	local giftStr = CS.TextManager.GetInstance():GetLocalizationString(142801);
	for i=1,giftCycle do
		local boxNormal = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Normal")
		local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Can_Reward")
		local boxOpen = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Open")
		
		boxNormal:SetActive(true)
		boxCanReward:SetActive(false)
		boxOpen:SetActive(false)
		itemDic.Progress_All:GetComponent(typeof(CS.UnityEngine.UI.Slider)).value = 0
		
		local textDayGo = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Text_Day");
		CS.client.Global.SetItemText(textDayGo, string.format(giftStr,tostring(i)));
	end
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp ~= nil ) then
		if(campActivityInfoACK.camp.days > 20) then
			campActivityInfoACK.camp.days = 20
		end
		local index = 0;
		if(campActivityInfoACK.camp.days  > 0) then
			local rewardBoxDays = math.fmod( campActivityInfoACK.camp.days, giftCycle)    -- 取余数
			local integerDay = math.modf( campActivityInfoACK.camp.days / giftCycle) --取整数
			--print("*******rewardBoxDays ",rewardBoxDays)
			--print("*******integerDay ",integerDay)
			index = rewardBoxDays
			for i=1,rewardBoxDays do
				local boxNormal = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Normal")
				local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Can_Reward")
				local boxOpen = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Open")
				
				boxNormal:SetActive(false)
				boxCanReward:SetActive(false) 
				boxOpen:SetActive(true)
				
				local textDayGo = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Text_Day");
				local rday = integerDay * giftCycle + i;
				CS.client.Global.SetItemText(textDayGo, string.format(giftStr,tostring(rday)));
			end

			if(campActivityInfoACK.camp.completed == true) then
				if(campActivityInfoACK.camp.todayReward == false) then
					local boxNormal = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(rewardBoxDays + 1)],"Box_Normal")
					local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(rewardBoxDays + 1)],"Box_Can_Reward")
					local boxOpen = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(rewardBoxDays + 1)],"Box_Open")
				
					boxNormal:SetActive(false)
					boxCanReward:SetActive(true)
					boxOpen:SetActive(false)
					index = index + 1
					local textDayGo = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(rewardBoxDays + 1)],"Text_Day");
					local rday = integerDay * giftCycle + (rewardBoxDays + 1);
					CS.client.Global.SetItemText(textDayGo, string.format(giftStr,tostring(rday)));
				end
				
			end
			if(index < giftCycle) then
				local cycleValue = integerDay
				if(cycleValue > 3) then
					cycleValue = 3
				end
				for i=index+1,giftCycle do
					local textDayGo = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Text_Day");
					local rday = cycleValue * giftCycle + i;
					CS.client.Global.SetItemText(textDayGo, string.format(giftStr,tostring(rday)));
					
					local boxNormal = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Normal")
					local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Can_Reward")
					local boxOpen = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(i)],"Box_Open")
					
					if(rday <= campActivityInfoACK.camp.days) then
						boxNormal:SetActive(false)
						boxCanReward:SetActive(false) 
						boxOpen:SetActive(true)
					end
				end
				
			end
		else
			if(campActivityInfoACK.camp.completed == true) then
				local boxNormal = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(1)],"Box_Normal")
				local boxCanReward = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(1)],"Box_Can_Reward")
				local boxOpen = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(1)],"Box_Open")
				if(campActivityInfoACK.camp.todayReward) then
					boxNormal:SetActive(false)
					boxCanReward:SetActive(false)
					boxOpen:SetActive(true)
				else
					boxNormal:SetActive(false)
					boxCanReward:SetActive(true)
					boxOpen:SetActive(false)
				end
				index = 1
				local textDayGo = CS.client.Global.GetGameObject(itemDic["Box_"..tostring(1)],"Text_Day");
				CS.client.Global.SetItemText(textDayGo, string.format(giftStr,"1"));
			end
		end
		local sliderValue = index * 0.25
		if(sliderValue > 1) then
			sliderValue = 1;
		end
		--print("*******index ",index)
		itemDic.Progress_All:GetComponent(typeof(CS.UnityEngine.UI.Slider)).value = sliderValue
	end
end

function IsGetReward(day)
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp ~= nil and campActivityInfoACK.camp.rewardDays ~= nil) then
		for i=1,#campActivityInfoACK.camp.rewardDays do
			if(campActivityInfoACK.camp.rewardDays[i] == day) then
				return true
			end
		end
		return false
	end
	return false
end

function OnTaskCircleListCallback(obj, index)
	SetTaskCellInfo(obj,index)
end

function SetTaskCellInfo(obj, index)
	if(campActivityInfoACK ~= nil and campActivityInfoACK.taskArray ~= nil) then
		if(index < #campActivityInfoACK.taskArray ) then
			local taskInfo = campActivityInfoACK.taskArray[index+1]
			if(LuaDailyTaskTemplate[taskInfo.id] ~= nil) then
				local taskTemplateInfo = LuaDailyTaskTemplate[taskInfo.id]
				
				local taskNumGo = CS.client.Global.GetGameObject(obj, "text_task_num");
				CS.client.Global.SetItemText(taskNumGo, taskInfo.times.."/"..taskTemplateInfo.lua_require_time);
				
				local itemEx = CS.client.ItemEx.CreateItemEx(taskTemplateInfo.lua_award_1_type, taskTemplateInfo.lua_award_1_par1,taskTemplateInfo.lua_award_1_par2);
				if itemEx ~= nil then
					--奖励图标
					local imageIconGo = CS.client.Global.GetGameObject(obj, "image_icon");
					CS.client.UIAssetSpecify.LoadAndSetSprite(imageIconGo, itemEx.AssistId);

					--奖励描述
					local taskRewardDesGo = CS.client.Global.GetGameObject(obj, "text_reward");
					CS.client.Global.SetItemText(taskRewardDesGo, itemEx.Name.."x"..itemEx.Count);
				end
				
				--任务描述
				local taskDesGo = CS.client.Global.GetGameObject(obj, "text_task");
				local name = CS.TextManager.GetInstance():GetLocalizationString(taskTemplateInfo.lua_TASK_DES);
				CS.client.Global.SetItemText(taskDesGo, name);
				
				local button_get = CS.client.Global.GetGameObject(obj, "button_get")
				local button_tips = CS.client.Global.GetGameObject(obj, "button_tips")
				local button_gain = CS.client.Global.GetGameObject(obj, "button_gain");

				button_get:SetActive(false)
				button_tips:SetActive(false)
				button_gain:SetActive(false)
				
				if(taskInfo.completed == false ) then
					local havePath =CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):HasPathDropFrom(taskTemplateInfo.lua_path)
					if (havePath) then
						button_tips:SetActive(true)
						CS.client.Global.RegisterButtonClick(button_tips, function( ... )
							CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):TryShowInnerLinkView(taskTemplateInfo.lua_path);
						end)
					else 
						
					end

				elseif(taskInfo.completed == true and not taskInfo.reward ) then
					button_get:SetActive(true)
					CS.client.Global.RegisterButtonClick(button_get, function( ... )
						--print("~~~~SetTaskCellInfo taskInfo.id ",taskInfo.id)
						GetCampTaskReward(taskInfo.id)
					end)
				elseif(taskInfo.completed == true and taskInfo.reward == true) then
					button_gain:SetActive(true)
				end
			end
		end
	end
end

function OnCampRankToogle(isOn)
	--print("OnCampRank isOn ",isOn)
	if(isOn) then
		itemDic.RankListNode_Camp:SetActive(true)
		itemDic.RankListNode_Player:SetActive(false)
		isCampRankToggleShow = true
		OnCampRank()
		SetMyCampInfo()
	end
end

function OnPlayerRankToogle(isOn)
	--print("OnPlayRank isOn ",isOn)
	if(isOn) then
		itemDic.RankListNode_Camp:SetActive(false)
		itemDic.RankListNode_Player:SetActive(true)
		isCampRankToggleShow = false
		OnPlayerRank()
		SetMyRankInfo()
	end
end

function OnCampRank()
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp~= nil and campActivityInfoACK.camp.campRank~= nil) then
		--print("OnCampRank "..#campActivityInfoACK.camp.campRank);
		--table.sort(campActivityInfoACK.camp.campRank,SortCampRank)
		campIdProcessed = {}
		mCampRankNormalCircleList:InitListByCellCount(campCount);
	end
end

function SetMyCampInfo()
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp~= nil and campActivityInfoACK.camp.campRank~= nil) then
		local rank = 0
		local popular = 0
		for i=1,#campActivityInfoACK.camp.campRank do
			if(tonumber(campActivityInfoACK.camp.campId) == tonumber(campActivityInfoACK.camp.campRank[i].campId)) then
				rank = i
				popular = campActivityInfoACK.camp.campRank[i].popular
				break;
			end
		end
		if(LuaZhenYingTemplate[campActivityInfoACK.camp.campId] ~= nil) then
			local text_none = CS.client.Global.GetGameObject(itemDic.CampRank, "text_none")
			local text_rank_num = CS.client.Global.GetGameObject(itemDic.CampRank, "text_rank_num")
			local text_Score_num = CS.client.Global.GetGameObject(itemDic.CampRank, "text_Score_num")
			local image_icon = CS.client.Global.GetGameObject(itemDic.CampRank, "image_icon")
			CS.client.UIAssetSpecify.LoadAndSetSprite(image_icon, LuaZhenYingTemplate[campActivityInfoACK.camp.campId].lua_rank_pic)
			
			local text_campname = CS.client.Global.GetGameObject(itemDic.CampRank, "text_campname")
			local myCampName = CS.TextManager.GetInstance():GetLocalizationString(LuaZhenYingTemplate[campActivityInfoACK.camp.campId].lua_camp_name);
			CS.client.Global.SetItemText(text_campname, myCampName);
			
			if(rank > 0) then
				text_none:SetActive(false)
				text_rank_num:SetActive(true)
				CS.client.Global.SetItemText(text_rank_num, tostring(rank));
				CS.client.Global.SetItemText(text_Score_num, tostring(popular));
			else
				text_none:SetActive(true)
				text_rank_num:SetActive(false)
				CS.client.Global.SetItemText(text_Score_num, "0");
			end
		end
	end
end

function OnPlayerRank()
	itemDic.nobody:SetActive(true)
	if(campActivityInfoACK ~= nil and campActivityInfoACK.camp~= nil and campActivityInfoACK.camp.userRank~= nil) then
		--print("OnCampRank "..#campActivityInfoACK.camp.userRank);
		--table.sort(campActivityInfoACK.camp.campRank,SortCampRank)
		if(#campActivityInfoACK.camp.userRank > 0) then
			mPlayerRankNormalCircleList:InitListByCellCount(#campActivityInfoACK.camp.userRank);
			itemDic.nobody:SetActive(false)
		end
		
	end
end

function OnShowPlayerRankReward()
	if(itemDic.Reward_detail_Player.activeInHierarchy) then
		itemDic.Reward_detail_Player:SetActive(false)
	else
		itemDic.Reward_detail_Player:SetActive(true)
	end
	
end

function OnShowCampRankReward()
	--print("OnShowCampRankReward")
	if(itemDic.Reward_detail_Camp.activeInHierarchy) then
		itemDic.Reward_detail_Camp:SetActive(false)
	else
		itemDic.Reward_detail_Camp:SetActive(true)
	end
	
end

function OnHideCampRankRewardImageBlack()
	itemDic.Reward_detail_Camp:SetActive(false)
end

function OnHidePlayerRankRewardImageBlack()
	itemDic.Reward_detail_Player:SetActive(false)
end

function OnShowGiftReward()
	itemDic.RankBonus:SetActive(true)
	mGiftRewardNormalCircleList:InitListByCellCount(#mLuaGiftRewardData);
end

function AutoCloseGiftReward()
	itemDic.RankBonus:SetActive(false)
end

function SortGiftRewardTemplate(a,b)
	return a.lua_id < b.lua_id
end

function OnDestroy( ... )
	CS.client.NetManager.GetInstance():UnRegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK));
end