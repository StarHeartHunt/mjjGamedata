local json = require("json")
local LuaUIUtil = require "LuaUIUtil"
local LuaNetManager = require "LuaNetManager"
local ActivityItemTemplate = require "p2dtemplate_lua/activityitem"
local LuaTemplate = require "p2dtemplate_lua/lua"
local LuaDailyTaskTemplate = require "p2dtemplate_lua/luadaily"
local LuaMainTaskTemplate = require "p2dtemplate_lua/luamain"

local itemDic = {};
local mInviteUserNormalList = nil;
local mTaskGrid = nil;
local mTaskDic = {};
local mTaskModel = {};
local mTaskCount = 0;
local mLuaInfo = nil;
local mLuaTaskTemplate = {};
local mOldUserParent = nil;
local mActiveUserParent = nil;
local mActiveInviteNum = 0;         --活跃玩家邀请个数
local mActiveInvitedNum = 0;         --活跃玩家邀请被接受个数
local mPlayerInfoParent = nil;
local MAX_INVITE_COUNT = 30;
local mInviteInfoParent = nil;      --我邀请了谁
local mInviteUserDic = {};
local mBackSelf = nil;
local mBackInvite = nil;
local mBackAcceptInvite = nil;
local mInviterUsersParent = nil;    --谁邀请了我
local mInviterUsersDic = {};
local mInviterUserNormalList = nil;
local mInviterParent = nil;

function Awake( ... )
end

function Init(... )
    --("OldUserReturnView.Init useSelf ",self)
    itemDic = LuaUIUtil.GetAllItems(self.gameObject);
	activityId = OldUserReturn:GetActivityId()
	
    for k,v in pairs(LuaTemplate) do
        if v.lua_LUA_filename == "Activity/OldUserReturn/OldUserReturn" and v.lua_id == activityId then
            mLuaInfo = v;
        end
    end
    mOldUserParent = itemDic.OldPlayer;
    mActiveUserParent = itemDic.ActiveUser;

    mPlayerInfoParent = CS.client.Global.GetGameObject(mActiveUserParent,"PlayerInfo");
    mInviteInfoParent = CS.client.Global.GetGameObject(mActiveUserParent,"InviteInfo");
    mBackSelf = CS.client.Global.GetGameObject(mOldUserParent,"back_self");
    mBackInvite = CS.client.Global.GetGameObject(mOldUserParent,"back_invite");
    mBackAcceptInvite = CS.client.Global.GetGameObject(mOldUserParent,"back_accept_invite");

    mInviteUserNormalList = itemDic.Friend_Scroll_View:GetComponent(typeof(CS.client.NormalCircleList));
    mInviteUserNormalList:RegisterCellRefresh(OnCircleListInviteCallback);

    mInviterUsersParent = CS.client.Global.GetGameObject(mOldUserParent,"inviter_list");
    mInviterUserNormalList = itemDic.Scroll_View_Invite:GetComponent(typeof(CS.client.NormalCircleList));
    mInviterUserNormalList:RegisterCellRefresh(OnCircleListInviterCallback);

    mInviterParent = itemDic.inviter_info;

    mTaskGrid = itemDic.TaskList:GetComponent(typeof(CS.client.NormalCircleList));
    mTaskGrid:RegisterCellRefresh(OnCircleListTaskCallback);

    --商城跳转(活跃玩家)
    local btnCloseInvite = CS.client.Global.GetGameObject(mActiveUserParent,"ButtonShop");
    CS.client.Global.RegisterButtonClick(btnCloseInvite, function( ... )
        OnClickBtnShop();
    end)

    --商城跳转（老玩家）
    local btnCloseInviter = CS.client.Global.GetGameObject(mOldUserParent,"ButtonShop");
    CS.client.Global.RegisterButtonClick(btnCloseInviter, function( ... )
        OnClickBtnShop();
    end)
    --关闭邀请列表(活跃玩家)
    local btnCloseInvite = CS.client.Global.GetGameObject(mInviteInfoParent,"image_invite_mask");
    CS.client.Global.RegisterButtonClick(btnCloseInvite, function( ... )
        mInviteInfoParent:SetActive(false);
    end)

    --关闭邀请列表（老玩家）
    local btnCloseInviter = CS.client.Global.GetGameObject(mInviterUsersParent,"tap_to_close_0");
    CS.client.Global.RegisterButtonClick(btnCloseInviter, function( ... )
        mInviterUsersParent:SetActive(false);
    end)
    btnCloseInviter = CS.client.Global.GetGameObject(mInviterUsersParent,"Button_Cancle");
    CS.client.Global.RegisterButtonClick(btnCloseInviter, function( ... )
        mInviterUsersParent:SetActive(false);
    end)

    CS.client.NetManager.GetInstance():RegisterMsgCallBack(typeof(CS.p2dprotocol.LuaJsonACK), function(obj, delayed, param)
        local ack = json.decode(obj.json);
        --LOG_INFO(ptable(ack));
        if ack["name"] == "SCGetRecallActivityInfo" then
            RefreshContent(ack);
        elseif ack["name"] == "SCRecallTaskReward" then
            if CS.client.Global.CheckServerMsgRet(ack.ret) then
                OnGetTaskReward(ack);
            end
        elseif ack["name"] == "SCRecallInvite" then
            if CS.client.Global.CheckServerMsgRet(ack.ret) then
                OnRecallInviteAck(ack);
            end
        elseif ack["name"] == "SCRecallTaskModify" then
                OnTaskModify(ack);
        elseif ack["name"] == "SCRecallUsers" then
            if CS.client.Global.CheckServerMsgRet(ack.ret) then
                OnSCRecallUsersAck(ack);
            end
        elseif ack["name"] == "SCInviteUsers" then
            if CS.client.Global.CheckServerMsgRet(ack.ret) then
                OnSCInviteUsersAck(ack);
            end
        elseif ack["name"] == "SCRecallAccept" then
            if CS.client.Global.CheckServerMsgRet(ack.ret) then
                OnSCRecallAcceptAck(ack);
            end
        end
        
       
    end);

    local CSGetRecallActivityInfo = {
        name = "CSGetRecallActivityInfo"
    }
    LuaNetManager.SendMsg(CSGetRecallActivityInfo);

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

    --local imgNode = itemDic.RewardsBanner;
    --CS.client.UIAssetSpecify.LoadAndSetSprite(imgNode, mLuaInfo.lua_LUA_picture);
end

function RefreshContent(info)
    --CS.client.Log.LogError(ptable(info))
    --LOG_INFO("info.recallInfo[%s] ", ptable(rewardInitData))
    --print_r(info);
    --printTable(info);
    --print("info.role",info["recallInfo"].role);
    if info.recallInfo.role == 1 then
        RefreshActiveUserContent(info.recallInfo);
        mActiveUserParent:SetActive(true);
        mOldUserParent:SetActive(false);
    elseif info.recallInfo.role == 2 then
        RefreshOldUserContent(info.recallInfo);
        mActiveUserParent:SetActive(false);
        mOldUserParent:SetActive(true);
    end
    RefreshTaskContent(info["taskArray"]);
end

function RefreshActiveUserContent( info )
    mActiveInviteNum = info.invite;
    mActiveInvitedNum = info.invited;
    RefreshInvite();
    local btnInvite = itemDic.InviteButton;
    CS.client.Global.RegisterButtonClick(btnInvite, function( ... )
        OnClickBtnInvite(info);
    end)
    local btnInfo = itemDic.ButtonInfo;
    CS.client.Global.RegisterButtonClick(btnInfo, function( ... )
        OnClickBtnInfo();
    end)
end

function RefreshInvite( ... )
    local bonusNode = itemDic.BonusBG;
    local inviteNum = CS.client.Global.GetGameObject(bonusNode, "text_invite_num");
    CS.client.Global.SetItemText(inviteNum,mActiveInviteNum.."/"..MAX_INVITE_COUNT);
    local invitedNum = CS.client.Global.GetGameObject(bonusNode, "text_invited_num");
    CS.client.Global.SetItemText(invitedNum,tostring(mActiveInvitedNum));
end

function RefreshInviteOnList( ... )
    local bonusNode = itemDic.BonusBG;
    local inviteNum = CS.client.Global.GetGameObject(mInviteInfoParent, "text_invite_num");
    CS.client.Global.SetItemText(inviteNum,mActiveInviteNum.."/"..MAX_INVITE_COUNT);
    local invitedNum = CS.client.Global.GetGameObject(mInviteInfoParent, "text_invited_num");
    CS.client.Global.SetItemText(invitedNum,tostring(mActiveInvitedNum));
end

function RefreshOldUserContent( info )
    if info.inviteUid ~= "" then
        RefreshOldUserAccept(info);
    else
        if info.invited_num > 0 then
            mBackAcceptInvite:SetActive(false);
            mBackSelf:SetActive(false);
            mBackInvite:SetActive(true);
            local uninvitedText = CS.client.Global.GetGameObject(mBackInvite, "text_uninvited");
            local str = "欢迎回归，您的"..info.invited_num.."位好友向您发出了召回邀请，快来查看吧！";
            CS.client.Global.SetItemText(uninvitedText,str);
            local btnInviteUsers = CS.client.Global.GetGameObject(mBackInvite, "ButtonInfo_Invite");
            CS.client.Global.RegisterButtonClick(btnInviteUsers, function( ... )
            OnClickBtnInviteUsers(info);
            end)
        else
            mBackAcceptInvite:SetActive(false);
            mBackSelf:SetActive(true);
            mBackInvite:SetActive(false);
        end
    end

end

function RefreshOldUserAccept( info )
    mBackAcceptInvite:SetActive(true);
    mBackSelf:SetActive(false);
    mBackInvite:SetActive(false);
    local acceptInviteText = CS.client.Global.GetGameObject(mBackAcceptInvite, "text_accept_invite");
    local str = "您已接受UID为"..info.inviteUid.."的玩家召回邀请，点击查看邀请者信息。";
    CS.client.Global.SetItemText(acceptInviteText,str);
    local btnInviterInfo = CS.client.Global.GetGameObject(mBackAcceptInvite, "ButtonInfo_Friend");
    CS.client.Global.RegisterButtonClick(btnInviterInfo, function( ... )
        OnClickBtnInviterInfo(info);
    end)
end

function RefreshTaskContent(info)
    --print("info",#info);
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

    local taskDic = mTaskDic[info.id];
    taskDic.order = taskDic.order + 200000;
    local data = mTaskModel[info.id];
    data.reward = true;
    SortTaskList();
    mTaskGrid:InitListByCellCount(mTaskCount);
end

function OnClickBtnShop()
   CS.client.UIManager.GetInstance():Show(CS.client.UIPaths.UI_NewShop, CS.client.NewShopView.InputParam(67,99680));
end

function OnClickBtnInvite(info)
    if info.invite >= MAX_INVITE_COUNT then
        CS.client.MsgBoxOkView:Show("邀请人数已达上限");
        return;
    end
    local inputGo = CS.client.Global.GetGameObject(itemDic.BonusBG, "InputField_UID");
    local input = inputGo:GetComponent(typeof(CS.UnityEngine.UI.InputField));
    --print("input",input.text);
    local CSRecallInvite = {
        name = "CSRecallInvite",
        uid = input.text,
        opType = 1
    }

    LuaNetManager.SendMsg(CSRecallInvite);
end

function OnClickBtnInviterInfo(info)
    local CSRecallAccept = {
        name = "CSRecallAccept",
        uid = info.inviteUid,
        opType = 2
    }

    LuaNetManager.SendMsg(CSRecallAccept);
end

function OnClickBtnInviteUsers(info)
    local CSInviteUsers = {
        name = "CSInviteUsers",
    }

    LuaNetManager.SendMsg(CSInviteUsers);
end

function OnClickBtnInfo(info)
    local canRefer = mActiveInviteNum >= 1;
    if not canRefer then
        CS.client.MsgBoxOkView.Show("请先邀请一位老玩家");
        return;
    end
    local CSRecallUsers = {
        name = "CSRecallUsers",
    }

    LuaNetManager.SendMsg(CSRecallUsers);
end

function OnRecallInviteAck(info)
    if info.opType == 1 then
        RefreshPlayerInfo(info.user);
        mPlayerInfoParent:SetActive(true);
    elseif info.opType == 2 then
        mActiveInviteNum = mActiveInviteNum + 1;
        RefreshInvite();
        CS.client.MsgBoxOkView.Show("已成功发出邀请，点击查看邀请情况可追踪邀请结果");
    end
end

function OnSCRecallAcceptAck(info)
    if info.opType == 1 then
        ShowAwards(info.awardArray); 
        RefreshOldUserAccept(info);    
    elseif info.opType == 2 then
        RefreshInviterInfo(info.user);
        mInviterParent:SetActive(true);
    end
end

function ShowAwards( info )
    local content = CS.TextManager.GetInstance():GetLocalizationString(CS.client.Constant.TEXT_GET_ITEM_TITLE_1);
     for k,v in pairs(info) do
        local itemEx = CS.client.ItemEx.CreateItemEx(v.category,v.id,v.num);
        if itemEx ~= nil then
            content = content.."\n" .. itemEx.Name.."×"..itemEx.Count;
        end
    end
    CS.client.MsgBoxMailView.Show(content);
end

function RefreshInviterInfo( info )
    local frameBg =  CS.client.Global.GetGameObject(mInviterParent,"Image_role_frame_bg");
    local frame =  CS.client.Global.GetGameObject(mInviterParent,"image_role_frame");
    local icon =  CS.client.Global.GetGameObject(mInviterParent,"image_role_icon");
    local frameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel));
    local  frameTemp = CS.TemplateManager.GetInstance():GetFrameById(info.head_dis.frame);
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
    local  profileTemp = CS.TemplateManager.GetInstance():GetProfileById(info.head_dis.icon);
    CS.client.UIAssetSpecify.LoadAndSetSprite(icon,profileTemp.pic_id);
    --名字
    local name =  CS.client.Global.GetGameObject(mInviterParent,"text_player_name");
    CS.client.Global.SetItemText(name,info.name);
    --等级
    local level =  CS.client.Global.GetGameObject(mInviterParent,"text_player_level");
    CS.client.Global.SetItemText(level,tostring(info.level));
    --公会名字
    local  guildName = info.head_dis.guild_name;
    if guildName == "" then
       guildName = "无";
    end
    local text_guild =  CS.client.Global.GetGameObject(mInviterParent,"text_guild_name");
    CS.client.Global.SetItemText(text_guild,guildName);
    --id
    local id =  CS.client.Global.GetGameObject(mInviterParent,"text_id");
    CS.client.Global.SetItemText(id,info.uid);
    --邀请
    local btnCloseInviter = CS.client.Global.GetGameObject(mInviterParent,"tap_to_close_1");
    CS.client.Global.RegisterButtonClick(btnCloseInviter, function( ... )
        mInviterParent:SetActive(false);
    end)
end

function OnSCInviteUsersAck( info )
    RefreshInviterUserInfo(info);
    mInviterUsersParent:SetActive(true);
end

function RefreshInviterUserInfo( info )
    mInviterUsersDic = {};
    for k,v in pairs(info.users) do
        table.insert(mInviterUsersDic, v);
    end
    mInviterUserNormalList:InitListByCellCount(tablelength(mInviterUsersDic));
end

function OnSCRecallUsersAck( info )
    RefreshInviteUserInfo(info);
    mInviteInfoParent:SetActive(true);
end

function RefreshInviteUserInfo( info )
    mInviteUserDic = {};
    --print("info.users",#info.users)
    mActiveInviteNum = #info.users;
    mActiveInvitedNum = 0;
    local  selfUid = CS.client.GameCore:GetUID();
    --print("selfUid",selfUid)
    for k,v in pairs(info.users) do
        --print("v",v.inviteUid)
        if v.inviteUid == selfUid then
            mActiveInvitedNum = mActiveInvitedNum + 1;
            v.inviteUid = 1;
        elseif v.inviteUid == "" then
            v.inviteUid = 2;
        elseif v.inviteUid ~= selfUid then
            v.inviteUid = 3;
        end
        table.insert(mInviteUserDic, v);
    end
     --已发出的邀请数量
    RefreshInvite();
    RefreshInviteOnList();

    table.sort(mInviteUserDic,function(a,b) return a.inviteUid < b.inviteUid end )

    mInviteUserNormalList:InitListByCellCount(tablelength(mInviteUserDic));
end

--刷新活跃玩家要邀请的人信息
function RefreshPlayerInfo( info )
    local frameBg =  CS.client.Global.GetGameObject(mPlayerInfoParent,"Image_role_frame_bg");
    local frame =  CS.client.Global.GetGameObject(mPlayerInfoParent,"image_role_frame");
    local icon =  CS.client.Global.GetGameObject(mPlayerInfoParent,"image_role_icon");
    local frameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel));
    local  frameTemp = CS.TemplateManager.GetInstance():GetFrameById(info.head_dis.frame);
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
    local  profileTemp = CS.TemplateManager.GetInstance():GetProfileById(info.head_dis.icon);
    CS.client.UIAssetSpecify.LoadAndSetSprite(icon,profileTemp.pic_id);
    --名字
    local name =  CS.client.Global.GetGameObject(mPlayerInfoParent,"text_player_name");
    CS.client.Global.SetItemText(name,info.name);
    --等级
    local levelText =  CS.client.Global.GetGameObject(mPlayerInfoParent,"text_player_level");
    CS.client.Global.SetItemText(levelText,tostring(info.level));
    --上次离线时间
    local friendModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.FriendModel));
    local lastLogout =  CS.client.Global.GetGameObject(mPlayerInfoParent,"text_date");
    CS.client.Global.SetItemText(lastLogout,friendModel:GetLastLoginTime(info.online,info.last_logout_timestamp));
    --公会名字
    local  guildName = info.head_dis.guild_name;
    if guildName == "" then
       guildName = "无";
    end
    local text_guild =  CS.client.Global.GetGameObject(mPlayerInfoParent,"text_guild_name");
    CS.client.Global.SetItemText(text_guild,guildName);

    --id
    local id =  CS.client.Global.GetGameObject(mPlayerInfoParent,"text_id");
    CS.client.Global.SetItemText(id,info.uid);
    --邀请
    local btnYes = itemDic.ButtonYes;
    CS.client.Global.RegisterButtonClick(btnYes, function( ... )
        OnClickBtnYes(info);
    end)
    --取消
    local btnNo = itemDic.ButtonNo;
    CS.client.Global.RegisterButtonClick(btnNo, function( ... )
        mPlayerInfoParent:SetActive(false);
    end)
end

function OnClickBtnYes(info)
    local CSRecallInvite = {
        name = "CSRecallInvite",
        uid = info.uid,
        opType = 2
    }
    mPlayerInfoParent:SetActive(false);
    LuaNetManager.SendMsg(CSRecallInvite);
end

function OnClickBtnAgree(info)
    local content = "您仅可以接受一位玩家的邀请，接受邀请后您每天完成活动任务，该玩家都将获得一份奖励。接受邀请您也将获得金叶子×50，剑玉×10000。确认接受邀请吗？"
    CS.client.MsgBoxView.Show(content, function( isOK )
        if not isOK then
            return;
        end
        local CSRecallAccept = {
        name = "CSRecallAccept",
        uid = info.uid,
        opType = 1
        }
        mInviterUsersParent:SetActive(false);
        LuaNetManager.SendMsg(CSRecallAccept);
    end)
end

function OnTaskModify(info)
    RefreshTaskContent(info.modifyArray)
end

function OnCircleListInviteCallback(obj, index)
    index = index + 1;
    local info = mInviteUserDic[index];
    ShowInviteUserCell(obj, info);
end

function ShowInviteUserCell(obj, info)
    --print("obj",obj.name);
     local frameBg =  CS.client.Global.GetGameObject(obj,"image_frame_bg");
    local frame =  CS.client.Global.GetGameObject(obj,"image_frame");
    local icon =  CS.client.Global.GetGameObject(obj,"image_icon");
    local frameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel));
    local  frameTemp = CS.TemplateManager.GetInstance():GetFrameById(info.head_dis.frame);
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
    local  profileTemp = CS.TemplateManager.GetInstance():GetProfileById(info.head_dis.icon);
    CS.client.UIAssetSpecify.LoadAndSetSprite(icon,profileTemp.pic_id);
    --名字
    local name =  CS.client.Global.GetGameObject(obj,"text_friend_name");
    CS.client.Global.SetItemText(name,info.name);
    --等级
    local level =  CS.client.Global.GetGameObject(obj,"text_friend_level");
    CS.client.Global.SetItemText(level,tostring(info.level));
    --上次离线时间
    local friendModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.FriendModel));
    local lastLogout =  CS.client.Global.GetGameObject(obj,"text_login_time");
    CS.client.Global.SetItemText(lastLogout,friendModel:GetLastLoginTime(info.online,info.last_logout_timestamp));
    --id
    local id =  CS.client.Global.GetGameObject(obj,"text_ID_value");
    CS.client.Global.SetItemText(id,info.uid);
    --根据状态，文字不同
    local recived =  CS.client.Global.GetGameObject(obj,"text_stage2");
    local recivedOther =  CS.client.Global.GetGameObject(obj,"text_stage");
    local notRespond =  CS.client.Global.GetGameObject(obj,"text_stage1");
    local str = "";
    --local  selfUid = CS.client.GameCore:GetUID();
    if info.inviteUid == 1 then
        recived:SetActive(true);
        recivedOther:SetActive(false);
        notRespond:SetActive(false);
        --str = "已接受邀请";
    elseif info.inviteUid == 2 then
        recived:SetActive(false);
        recivedOther:SetActive(false);
        notRespond:SetActive(true);
        --str = "未回应";
    elseif info.inviteUid == 3 then
        recived:SetActive(false);
        recivedOther:SetActive(true);
        notRespond:SetActive(false);
        --str = "已接受他人邀请";
    end
    --状态
    --local stage =  CS.client.Global.GetGameObject(obj,"text_stage");
    --CS.client.Global.SetItemText(stage,str);
end

function OnCircleListInviterCallback(obj, index)
    index = index + 1;
    local info = mInviterUsersDic[index];
    ShowInviterUserCell(obj, info);
end

function ShowInviterUserCell(obj, info)
    local frameBg =  CS.client.Global.GetGameObject(obj,"Image_frame_list_bg");
    local frame =  CS.client.Global.GetGameObject(obj,"image_frame_list");
    local icon =  CS.client.Global.GetGameObject(obj,"image_card_list");
    local frameModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.RoleIconFrameModel));
    local  frameTemp = CS.TemplateManager.GetInstance():GetFrameById(info.head_dis.frame);
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
    local  profileTemp = CS.TemplateManager.GetInstance():GetProfileById(info.head_dis.icon);
    CS.client.UIAssetSpecify.LoadAndSetSprite(icon,profileTemp.pic_id);
    --名字
    local name =  CS.client.Global.GetGameObject(obj,"text_friend_name_list");
    CS.client.Global.SetItemText(name,info.name);
    --等级
    local level =  CS.client.Global.GetGameObject(obj,"text_player_level");
    CS.client.Global.SetItemText(level,tostring(info.level));
    --id
    local id =  CS.client.Global.GetGameObject(obj,"text_id");
    CS.client.Global.SetItemText(id,info.uid);
    --公会名字
    local  guildName = info.head_dis.guild_name;
    if guildName == "" then
       guildName = "无";
    end
    local text_guild =  CS.client.Global.GetGameObject(obj,"text_guild_name");
    CS.client.Global.SetItemText(text_guild,guildName);
    --接受邀请
    local btnAgree = CS.client.Global.GetGameObject(obj,"Button_Agree");
    CS.client.Global.RegisterButtonClick(btnAgree, function( ... )
        OnClickBtnAgree(info);
    end)
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
    local itemEx = CS.client.ItemEx.CreateItemEx(info.lua_award_1_type,info.lua_award_1_par1,info.lua_award_1_par2,true,true);
    if itemEx then
        CS.client.UIAssetSpecify.LoadAndSetSprite(couponNode, itemEx.AssistId);
    end

    local numbeText = CS.client.Global.GetGameObject(obj, "text_task_num");
    taskDic["numTextObj"] = numbeText;

    local couponText = CS.client.Global.GetGameObject(obj, "text_reward");
    if itemEx then
        local mText = CS.TextManager.GetInstance():GetLocalizationString(19766);
        local mNameText = itemEx.Name;
        local text = CS.System.String.Format(mText, mNameText, tostring(itemEx.Count));
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
	local CSRecallTaskReward = {
        name = "CSRecallTaskReward",
        id = id
    }
    LuaNetManager.SendMsg(CSRecallTaskReward);
end

function SortTaskList()
    mLuaTaskTemplate = {};
    table.sort(mTaskDic, function (k1, k2) return k1.order < k2.order end);
    for k,v in spairs(mTaskDic, function(t,a,b) return t[b].order > t[a].order end) do
       -- if has_value(mLuaInfo.lua_LUA_dailytast, k) or has_value(mLuaInfo.lua_LUA_miantast, k) then
            table.insert(mLuaTaskTemplate, v);
        --end
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