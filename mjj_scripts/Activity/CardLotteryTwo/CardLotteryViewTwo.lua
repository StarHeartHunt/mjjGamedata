local json = require("json")
local LuaUIUtil = require "LuaUIUtil"
local LuaNetManager = require "LuaNetManager"
local ActivityItemTemplate = require "p2dtemplate_lua/activityitem"
local ActivityPoolTemplate = require "p2dtemplate_lua/luapool"
local LuaTemplate = require "p2dtemplate_lua/lua"
local LuaDailyTaskTemplate = require "p2dtemplate_lua/luadaily"
local LuaMainTaskTemplate = require "p2dtemplate_lua/luamain"

local itemDic = {};
local mRewardGrid = nil;
local mTaskGrid = nil;
local mItemNode1 = nil;
local mItemNode2 = nil;
local mItemNode3 = nil;
local mRewardDic = {};
local mTaskDic = {};
local mRewardModel = {};
local mTaskModel = {};
local mTicketNum = 0;
local mTicketText = nil;
local mTotalRewardCount = 0;
local mRewardCount = 0;
local mRewardText1 = nil;
local mRewardText2 = nil;
local mTaskCount = 0;
local mLuaInfo = nil;
local mActivityPoolTemplate = {};
local mLuaTaskTemplate = {};
local mRewardMsg = nil;
local mRewardMsgBox = nil;
local mRewardMsgBoxObj = nil;

function Awake( ... )
end

function Init(... )
    itemDic = LuaUIUtil.GetAllItems(self.gameObject);
	activityId = CardLotteryTwo:GetActivityId()
	
    for k,v in pairs(LuaTemplate) do
        if v.lua_LUA_filename == "Activity/CardLotteryTwo/CardLotteryTwo" and v.lua_id == activityId then
            mLuaInfo = v;
        end
    end

    mRewardGrid = itemDic.RewardNode:GetComponent(typeof(CS.client.NormalCircleList));
    mRewardGrid:RegisterCellRefresh(OnCircleListRewardCallback);

    mTaskGrid = itemDic.TaskList:GetComponent(typeof(CS.client.NormalCircleList));
    mTaskGrid:RegisterCellRefresh(OnCircleListTaskCallback);

    local ticketNode = itemDic.OwnedNode;
    mTicketText = CS.client.Global.GetGameObject(ticketNode, "TextValue");

    local itemNode1 = CS.client.Global.GetGameObject(itemDic.RewardsPoolNode, "TotalNumberNode");
    mRewardText1 = CS.client.Global.GetGameObject(itemNode1, "Text");

    local itemNode2 = CS.client.Global.GetGameObject(itemDic.RewardsTips, "TotalNumberNode");
    mRewardText2 = CS.client.Global.GetGameObject(itemNode2, "Text");

    mItemNode1 = itemDic.Bonus_1;
    mItemNode2 = itemDic.Bonus_2;
    mItemNode3 = itemDic.Bonus_3;

    CS.client.NetManager.GetInstance():RegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK), function(obj, delayed, param)
        local ack = json.decode(obj.json);
        if ack["name"] == "SCGetActivityInfo" then
            RefreshContent(ack);
        elseif ack["name"] == "SCTaskReward" then
            OnGetTaskReward(ack);
        elseif ack["name"] == "SCLotteryDraw" then
            OnLotteryDraw(ack);
        elseif ack["name"] == "SCTaskModify" then
            OnTaskModify(ack);
        end
    end);

    local CSGetActivityInfo = {
        name = "CSGetActivityInfo"
    }
    LuaNetManager.SendMsg(CSGetActivityInfo);

    ShowContent();
end

function Update( ... )
end

function OnDestroy( ... )
	CS.client.NetManager.GetInstance():UnRegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK));
end

function ShowContent()
    local nameNode = CS.client.Global.GetGameObject(itemDic.Top, "text_title");
    local name = CS.TextManager.GetInstance():GetLocalizationString(mLuaInfo.lua_LUA_name);
    CS.client.Global.SetItemText(nameNode, name);

    local imgNode = itemDic.RewardsBanner;
    CS.client.UIAssetSpecify.LoadAndSetSprite(imgNode, mLuaInfo.lua_LUA_picture);

    local rewardBox = itemDic.RewardsTips;
    mRewardMsg = itemDic.Box;

    local btnInfo = itemDic.ButtonTips;
    CS.client.Global.RegisterButtonClick(btnInfo, function( ... )
        rewardBox:SetActive(true);
    end);

    local btnBack1 = CS.client.Global.GetGameObject(rewardBox, "image_mask");
    CS.client.Global.RegisterButtonClick(btnBack1, function( ... )
        rewardBox:SetActive(false);
    end);

    mRewardMsgBox = mRewardMsg.transform:Find("Award").gameObject;
    mRewardMsgBox:SetActive(true);
    mRewardMsgBoxObj = mRewardMsgBox.transform:Find("Award").gameObject;
    mRewardMsgBoxObj:SetActive(false);

    local btnBack2 = CS.client.Global.GetGameObject(mRewardMsg, "image_mask");
    CS.client.Global.RegisterButtonClick(btnBack2, function( ... )
        ResetAwards();
    end);

    local btnOK = CS.client.Global.GetGameObject(mRewardMsg, "ButtonYes");
    CS.client.Global.RegisterButtonClick(btnOK, function( ... )
        ResetAwards();
    end);

    local btnDraw1 = itemDic.ButtonOneTime;
    CS.client.Global.RegisterButtonClick(btnDraw1, function( ... )
        LotteryDraw(false);
    end)

    local btnDraw2 = itemDic.ButtonTenTimes;
    CS.client.Global.RegisterButtonClick(btnDraw2, function( ... )
        LotteryDraw(true);
    end)
end

function RefreshContent(info)
    UpdateTicket();
    RefreshPoolContent(info["poolArray"]);
    RefreshTaskContent(info["taskArray"]);
end

function RefreshPoolContent(info)
    mTotalRewardCount = 0;
    local RewardCount = 0;
    for k,v in pairs(info) do
        mRewardModel[v.id] = v;
        local rewardDic = {};
        local template = nil;
        if ActivityPoolTemplate[v.id] then
            template = ActivityPoolTemplate[v.id];
        end

        mTotalRewardCount = mTotalRewardCount + template.lua_Num;
        rewardDic["order"] = template.lua_order;
        rewardDic["itemInfo"] = template;
        mRewardDic[v.id] = rewardDic; 

        if template.lua_Emphasis_effect == 1 then
            ShowRewardCell(mItemNode1, template);
        elseif template.lua_Emphasis_effect == 2 then
            ShowRewardCell(mItemNode2, template);
        elseif template.lua_Emphasis_effect == 3 then
            ShowRewardCell(mItemNode3, template);
        end
        
        RewardCount = RewardCount + v.times;
    end

    mRewardCount = mTotalRewardCount - RewardCount;
    if mRewardCount < 0 then
        mRewardCount = 0;
    end

    CS.client.Global.SetItemText(mRewardText1, tostring(mRewardCount).."/"..tostring(mTotalRewardCount));
    CS.client.Global.SetItemText(mRewardText2, tostring(mRewardCount).."/"..tostring(mTotalRewardCount));

    mActivityPoolTemplate = {};
    for k,v in pairs(mRewardDic) do
        table.insert(mActivityPoolTemplate, v);
    end
    table.sort(mActivityPoolTemplate, function (k1, k2) return k1.order < k2.order end);

    mRewardGrid:InitListByCellCount(tablelength(mActivityPoolTemplate));
end

function RefreshTaskContent(info)
    for k,v in pairs(info) do
        mTaskModel[v.id] = v;
        local taskDic = {};
        local isRewarded = v.completed and v.reward;
        local canReward = v.completed and not v.reward;

        if info.lua_dailytask_order then
            taskDic["order"] = info.lua_dailytask_order;
        else
            taskDic["order"] = info.lua_maintask_order;
        end

        local template = nil;
        if LuaDailyTaskTemplate[v.id] then
            template = LuaDailyTaskTemplate[v.id];
        else
            template = LuaMainTaskTemplate[v.id];
        end

        if template.lua_dailytask_order then
            taskDic["order"] = template.lua_dailytask_order;
        else
            taskDic["order"] = template.lua_maintask_order;
        end

        if isRewarded then
            taskDic["order"] = taskDic.order + 200000;
        elseif canReward then
            taskDic["order"] = taskDic.order;
        else
            taskDic["order"] = taskDic.order + 100000;
        end

        taskDic["itemInfo"] = template;
        mTaskDic[v.id] = taskDic; 
    end

    SortTaskList();

    mTaskCount = tablelength(mLuaTaskTemplate);
    mTaskGrid:InitListByCellCount(mTaskCount);

end

function OnGetTaskReward(info)
    local awardList = {info.award};
    ShowAwards(awardList);

    UpdateTicket();

    local taskDic = mTaskDic[info.id];
    taskDic.order = taskDic.order + 200000;
    local data = mTaskModel[info.id];
    data.reward = true;
    SortTaskList();
    mTaskGrid:InitListByCellCount(mTaskCount);
end

function OnLotteryDraw(info)
    ShowAwards(info.awardArray);
    UpdateTicket();
    RefreshPoolContent(info.poolArray);
end

function OnTaskModify(info)
    RefreshTaskContent(info.modifyArray)
end

function OnCircleListRewardCallback(obj, index)
    index = index + 1;
    local info = mActivityPoolTemplate[index].itemInfo;
    ShowRewardCell(obj, info);
end

function ShowRewardCell(obj, info)
    local rewardDic = mRewardDic[info.lua_id];
    rewardDic["itemObj"] = obj;

    local numNode = CS.client.Global.GetGameObject(obj, "NumberNode");
    local numText = CS.client.Global.GetGameObject(numNode, "Text");
    CS.client.Global.SetItemText(numText, info.lua_Num.."/"..info.lua_Num);
    rewardDic["numTextObj"] = numText;
    local model = mTaskModel[info.lua_id];
    if model then
        CS.client.Global.SetItemText(rewardDic.numTextObj, rewardDic.itemInfo.lua_Num - model.times.."/"..rewardDic.itemInfo.lua_Num);
    end

    local UIItem = CS.client.UIItem(obj);
    local ItemEx = CS.client.ItemEx.CreateItemEx(info.lua_Item_type, info.lua_Item_id, info.lua_Item_num, true);
    UIItem:SetItem(ItemEx);

    local data = mRewardModel[info.lua_id];
    CS.client.Global.SetItemText(rewardDic.numTextObj, rewardDic.itemInfo.lua_Num - data.times.."/"..rewardDic.itemInfo.lua_Num);

    mRewardDic[info.lua_id] = rewardDic;
end

function OnCircleListTaskCallback(obj, index)
    index = index + 1;
    local info = nil;
    if index <= mTaskCount then
        info = mLuaTaskTemplate[index].itemInfo;
    end

    local taskDic = mTaskDic[info.lua_id];
    taskDic["itemObj"] = obj;

    local name = CS.TextManager.GetInstance():GetLocalizationString(info.lua_TASK_DES);
    local nameText = CS.client.Global.GetGameObject(obj, "text_task");
    CS.client.Global.SetItemText(nameText, name);

    local couponNode = CS.client.Global.GetGameObject(obj, "image_icon");
    local itemInfo = ActivityItemTemplate[info.lua_award_1_par1];
    if itemInfo then
        CS.client.UIAssetSpecify.LoadAndSetSprite(couponNode, itemInfo.lua_small_pic);
    end

    local numbeText = CS.client.Global.GetGameObject(obj, "text_task_num");
    taskDic["numTextObj"] = numbeText;

    local couponText = CS.client.Global.GetGameObject(obj, "text_reward");
    if itemInfo then
        local mText = CS.TextManager.GetInstance():GetLocalizationString(19766);
        local mNameText = CS.TextManager.GetInstance():GetLocalizationString(itemInfo.lua_NAME);
        local text = CS.System.String.Format(mText, mNameText, tostring(info.lua_award_1_par2));
        CS.client.Global.SetItemText(couponText, text);
    end

    local btnGetTaskReward = CS.client.Global.GetGameObject(obj, "button_get");
    CS.client.Global.RegisterButtonClick(btnGetTaskReward, function( ... )
        GetTaskReward(info.lua_id);
    end)
    btnGetTaskReward:SetActive(false);

    local btnTipTaskReward = CS.client.Global.GetGameObject(obj, "button_tips");
    CS.client.Global.RegisterButtonClick(btnTipTaskReward, function( ... )
        CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.InnerLinkModel)):TryShowInnerLinkView(info.lua_path);
    end)
    btnTipTaskReward:SetActive(true);

    local btnGainTaskReward = CS.client.Global.GetGameObject(obj, "button_gain");
    btnGainTaskReward:SetActive(false);

    taskDic["btnGetObj"] = btnGetTaskReward;
    taskDic["btnTipObj"] = btnTipTaskReward;
    taskDic["btnGainObj"] = btnGainTaskReward;
    
    local data = mTaskModel[info.lua_id];

    local progress = nil;
    if taskDic.itemInfo.lua_require_time then
        progress = data.times / taskDic.itemInfo.lua_require_time;
        CS.client.Global.SetItemText(taskDic.numTextObj, data.times.."/"..taskDic.itemInfo.lua_require_time);
    else
        progress = data.times / taskDic.itemInfo.lua_require_times;
        CS.client.Global.SetItemText(taskDic.numTextObj, data.times.."/"..taskDic.itemInfo.lua_require_times);
    end

    local isRewarded = data.completed and data.reward;
    local canReward = data.completed and not data.reward;

    if isRewarded then
        taskDic.btnGainObj:SetActive(true);
        taskDic.btnTipObj:SetActive(false);
        taskDic.btnGetObj:SetActive(false);
    elseif canReward then
        taskDic.btnGainObj:SetActive(false);
        taskDic.btnTipObj:SetActive(false);
        taskDic.btnGetObj:SetActive(true);
    else
        taskDic.btnGainObj:SetActive(false);
        taskDic.btnTipObj:SetActive(true);
        taskDic.btnGetObj:SetActive(false);
    end

    if taskDic.itemInfo.lua_path == "0" then
        taskDic.btnTipObj:SetActive(false);
    end

end

function GetTaskReward(id)
	local CSTaskReward = {
        name = "CSTaskReward",
        id = id
    }
    LuaNetManager.SendMsg(CSTaskReward);
end

function LotteryDraw(isMultiple)
    local canDraw = ((not isMultiple) and mRewardCount >= 1) or (isMultiple and (mRewardCount >= 10));
    if not canDraw then
        CS.client.BubbleTipsModel.Show("奖池剩余道具数量不足");
        return;
    end

    canDraw = ((not isMultiple) and mTicketNum >= 1) or (isMultiple and (mTicketNum >= 10));
    if not canDraw then
        CS.client.BubbleTipsModel.Show("您的宝签不足");
        return;
    end

    local CSLotteryDraw = {
        name = "CSLotteryDraw",
        multiple = isMultiple,
        sid = tonumber(mLuaInfo.lua_LUA_draw)
    }

    LuaNetManager.SendMsg(CSLotteryDraw);
end

function SortTaskList()
    mLuaTaskTemplate = {};
    table.sort(mTaskDic, function (k1, k2) return k1.order < k2.order end);
    for k,v in spairs(mTaskDic, function(t,a,b) return t[b].order > t[a].order end) do
        if has_value(mLuaInfo.lua_LUA_dailytast, k) or has_value(mLuaInfo.lua_LUA_miantast, k) then
            table.insert(mLuaTaskTemplate, v);
        end
    end
end

function ShowAwards(info)
    mRewardMsg:SetActive(true);
    
    for i = 1, #info do
        local itemGo = CS.UnityEngine.GameObject.Instantiate(mRewardMsgBoxObj);
        itemGo:SetActive(true);
        itemGo.transform:SetParent(mRewardMsgBoxObj.transform.parent, false);
        itemGo.name = mRewardMsgBoxObj.name..tostring(i);
        local UIItem = CS.client.UIItem(itemGo);
        local ItemEx = CS.client.ItemEx.CreateItemEx(info[i].category, info[i].id, info[i].num);
        UIItem:SetItem(ItemEx);
    end
end

function UpdateTicket()
    mTicketNum = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.MaterialBagModel)):GetMaterialCount(tonumber(mLuaInfo.lua_LUA_draw));
    CS.client.Global.SetItemText(mTicketText, tostring(mTicketNum));
end

function ResetAwards()
    mRewardMsg:SetActive(false);
    for i = 1, mRewardMsgBox.transform.childCount - 1 do
        CS.UnityEngine.Object.Destroy(mRewardMsgBox.transform:GetChild(i).gameObject);
    end
end

function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end