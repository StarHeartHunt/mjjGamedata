local util = require 'xlua.util'

-- xlua.hotfix(CS.client.GiftView, "DisplayRefresh", function(self)
-- 	print("test");
-- end)

xlua.hotfix(CS.client.Bundle, {
	['.ctor'] = function(csobj)
		util.state(csobj, {
			xlua.private_accessible(CS.client.Bundle._BundleData);
			_SetValue = function(self, key, val)
				if self.mDict:ContainsKey(key) then
					self.mDict:Remove(key);
				end
				if val ~= nil then
					local data = CS.client.Bundle._BundleData();
					data.type = typeof(CS.System.Collections.Generic["List`1[client.ItemEx]"]);
					data.val = val;
					self.mDict:Add(key, data);
				end
				return self;
			end;
		})
	end;
})

xlua.hotfix(CS.client.BagModel, "HaveCharacterIdCard", function(self,cardID)
	for k,v in pairs(self.mBaseCardsDict) do
		if (v.mCardType == CS.client.CARDTYPE.CARD_WHOLE) then
            if (v.Template.id == cardID)then
                return true;
            end
        end
	end
	 return false;
end)


--lua热更新测试 出包的时候打开 测试通过要更新cdn关闭
--[[
xlua.hotfix(CS.client.CharacterPreviewView, "OnClickBackBtn", function(self,obj)
	CS.client.BubbleTipsModel.Show(CS.TextManager.GetInstance():GetLocalizationString(21114));
	self:OnCardPreviewCallBack();
end)
]]

xlua.hotfix(CS.client.CharacterPreviewView,"TalentResourceEnough",function(self)
	print("TalentResourceEnough")
	local talentTreeModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.TalentTreeModel))
	local talentUnlockedPoint = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.TalentTreeModel)):GetTalentUnlockedpoint(self.mMainCard);
	if(talentUnlockedPoint ~= nil and talentUnlockedPoint.Count > 0) then
		for i=0,talentUnlockedPoint.Count-1 do
			local canUnlock = true;
			local talentBranchTemplateData = talentTreeModel:GetTalentBranchTemplateDataByIndex(self.mMainCard.Group.talent_tree_id,talentUnlockedPoint[i]);			
			if(talentBranchTemplateData ~= nil) then
				for j=1,talentBranchTemplateData.talent_cost_type.Count do
					local itemEx = CS.client.ItemEx.CreateItemEx(talentBranchTemplateData.talent_cost_type[j - 1], talentBranchTemplateData.talent_cost_id[j - 1]);
					local haveCount = 0;
                    local needCount = talentBranchTemplateData.talent_cost_num[j - 1];
					if (itemEx.TempType == 116) then
						haveCount =talentTreeModel:GetTalentPointCount(self.mMainCard.SID);
					else
						haveCount = itemEx.HaveCount;
					end
					if (haveCount < needCount) then
						canUnlock = false;
					end
				end
			end
			if(canUnlock) then
				return true
			end
		end
	end
	return false
end)

xlua.hotfix(CS.client.WarChessPiecesPlayerData,"SetTemplateData",function(self,tempid,protraitId)
	print("SetTemplateData")
	self.mTemplate = CS.TemplateManager.GetInstance():GetCharacter(tempid);
	self.group = CS.client.CardUtility.GetCharacterGroup(mTemplate);
	self.portrait = CS.TemplateManager.GetInstance():GetPortraitById(protraitId);
	
	if self.portrait == nil then
		self.portrait = CS.client.CardUtility.GetPortraitByCardId(tempid,true);
	end
	
	if self.mCurSkin == 0 then
		local live2D = CS.client.CardUtility.GetLive2dByCardTemplate(self.mTemplate,true);
		if live2D ~= nil then
			self.mCurSkin = live2D.id;
		else
			self.mCurSkin = 0;
		end
	end
	
	if self.mTemplate ~= nil then
		self.mAttribute = self.mTemplate.attribute;
        self.isUseluaAi = (self.mTemplate.enable_lua == 1);
        self.luaAiName = self.mTemplate.lua_name;
        self.mSingleSkillId = self.mTemplate.skill_single;
        self.mUltimateId = self.mTemplate.skill_ultimate;
        self.mPassiveId = self.mTemplate.skill_cap;
	end
	self.name = CS.TextManager.GetInstance():GetLocalizationString(self.mTemplate.NAME);
	self:SetConfigurationChange();
end)

local talentTreeCurRefreshCard = nil
xlua.hotfix(CS.client.TalentTreeModel,"RefreshTalentAndCardByTalentTree",function(self,talentTree)
	--print("***********CS.client.TalentTreeModel talentTree ",talentTree)
	if(talentTree ~= nil) then
		self.mAllCardTalentInfo[talentTree.cardsid] = talentTree;
		local bagModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.BagModel))
		local card = bagModel:GetCardBySID(talentTree.cardsid);
		talentTreeCurRefreshCard= card
		self:UpdateCardSkillByCardSid(card)
		self:RefreshCard()
	end
	
end)

xlua.hotfix(CS.client.TalentTreeModel,"RefreshCard",function(self)
	--print("***********CS.client.TalentTreeModel talentTreeCurRefreshCard ",talentTreeCurRefreshCard)
	if(talentTreeCurRefreshCard ~= nil) then
		local bagModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.BagModel))
		local cards = bagModel:GetAllEnableTeamCards()
		for i=0,cards.Count-1 do
			if(cards[i].SID == talentTreeCurRefreshCard.SID) then
				cards[i]:RefreshCard()
			end
		end
	end
end)

xlua.hotfix(CS.client.AudioManager,"PlayMusicByID",function(self,assetID)
	--print("***********CS.client.AudioManager assetID ",assetID)
	self.mListBgmVoice:Clear()
	self.mListBgmVoice:Add(assetID)
	self.mListBgmVoiceIndex = 0
	
	if(self.mMusicInfo.mIsWorking and self.mMusicInfo.mAudioSource.isPlaying) then
		if(assetID == self.mMusicInfo.mAssetID) then
			return
		end
	end
	self:PlayBgmMusic()
end)

xlua.hotfix(CS.client.AudioManager,"_InternalPlayMusic",function(self,clip,assetID)
	--print("***********CS.client.AudioManager _InternalPlayMusic clip ",clip)
	--print("***********CS.client.AudioManager _InternalPlayMusic assetID ",assetID)
	--print("***********CS.client.AudioManager _InternalPlayMusic self ",self)
	
	if(clip == nil) then
		print("=== AudioManager:_InternalPlayMusic error, clip is null!");
		return;
	end
	if(self.mMusicInfo == nil) then
		print("=== AudioManager:_InternalPlayMusic error, mMusicInfo is null!");
		return;
	end
	self:StopMusic();
	CS.client.TimerManager.GetInstance():AddTimer(0.1,function()
		--print("***********CS.client.AudioManager _InternalPlayMusic AddTimer self ",self)
		if(self.mMusicInfo.mAudioSource ~= nil) then
			self:SetAudioMusicVolume(self.mLerpInfoBGM.mLerp.mCurrentValue);
			local globalPrefsModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.GlobalPrefsModel))
			
			if(not self:IsAllSoundsStopped() and globalPrefsModel.AudioOpen) then
				self:FadeLerpBGM(2)
			end
			self.mMusicInfo.mAudioSource.clip = clip;
			self.mMusicInfo.mAudioSource:Play()
		end
		self.mMusicInfo.mAssetID = assetID;
		self.mMusicInfo.mIsWorking = true;
		self.mIsBgmLoadingResource = false;
	end)
end)


xlua.hotfix(CS.client.CharacterPreviewView,"SetBaseProperty",function(self)
	if(self.mMainCard.mCardType == CS.client.CARDTYPE.__CastFrom('CARD_WHOLE')) then
		--属性
		local mBundelName = CS.client.CardUtility.GetCardAttributeIconName(self.mMainCard.Template.attribute);
		local bundleId = CS.client.ResourceManager.GetInstance():GetIDByAssetName(mBundelName);
		self:LoadAndSetImage(bundleId, nil, self:GetItem("image_attribute")); 
		self:SetItemText("text_character_name", self.mMainCard.Name);
		
		--显示星星
		for i=0,6 do
			if(self.mStarLights[i] ~= nil) then
				if(i < self.mMainCard.Template.max_star) then
					self.mStarLights[i].transform.parent.gameObject:SetActive(true);
                    self.mStarLights[i]:SetActive(i < self.mMainCard.Template.star);
				else
					self.mStarLights[i].transform.parent.gameObject:SetActive(false);
				end
			end
		end
		--等级
		local maxLevel = CS.client.CardUtility.GetMaxLevel(self.mMainCard.Template.star);
		local level = self.mMainCard.mLevel .. "/" .. maxLevel;
		self:SetItemText("text_level", level);
		--经验
		local nextLevelNeedExp = CS.client.CardUtility.ExpOfLevelUp(self.mMainCard.Template, self.mMainCard.CardData.param.level);
		self:SetItemText("text_experience_now", self.mMainCard.CardData.param.exp);
		self:SetItemText("text_experience_full", nextLevelNeedExp);

		local ratio = self.mMainCard.CardData.param.exp / nextLevelNeedExp;
		if(self.mExpSlider ~= nil) then
			self.mExpSlider.value = ratio;
		end
		--属性
		local poemAddition = self.mMainCard:GetPoemAddition();
		
		self:SetItemText("text_kizuna", self.mMainCard.CrushLevName);
		self:SetItemText("text_hp", math.floor(self.mMainCard:GetPropertyExceptLingXi(CS.client.CardPropertyType.__CastFrom('Hp'))));
		self:SetItemText("text_atk", math.floor(self.mMainCard:GetPropertyExceptLingXi(CS.client.CardPropertyType.__CastFrom('Atk'))));
		self:SetItemText("text_def", math.floor(self.mMainCard:GetPropertyExceptLingXi(CS.client.CardPropertyType.__CastFrom('Def'))));
		
		strCrit = (math.floor(self.mMainCard:GetPropertyExceptLingXi(CS.client.CardPropertyType.__CastFrom('Crit')) * 100 +0.5)) .. "%";
		self:SetItemText("text_crt", strCrit);
		local strCritDam = (math.floor(self.mMainCard:GetPropertyExceptLingXi(CS.client.CardPropertyType.__CastFrom('CritDam')) * 100+0.5)).."%";
		self:SetItemText("text_crd", strCritDam);
		
		local baseTotalScore = math.floor(CS.client.CardUtility.GetTotalScore((self.mMainCard.mBaseAtk + poemAddition.poemAtk), (self.mMainCard.mBaseDef + poemAddition.poemDef), (self.mMainCard.mBaseHP + poemAddition.poemHP), self.mMainCard.Template.star));
		self:SetItemText("text_battle", self.mMainCard.mTotalScore);
	
		local lingXiAddAttr = self.mMainCard:GetLingxiAttrBySuit(self.mMainCard.mUsingLingxiSuit.lID);
		self:ShowItem(self:GetItem("text_lingxi_atk_value"), lingXiAddAttr.lingxiAtk > 0);
		self:SetItemText("text_lingxi_atk_value", "+" ..math.floor(lingXiAddAttr.lingxiAtk* self.mMainCard:GetPropertyAddPercent(CS.client.CardPropertyType.__CastFrom('Atk'))));
		self:ShowItem(self:GetItem("text_lingxi_hp_value"), lingXiAddAttr.lingxiHP > 0);
		self:SetItemText("text_lingxi_hp_value", "+" ..math.floor(lingXiAddAttr.lingxiHP * self.mMainCard:GetPropertyAddPercent(CS.client.CardPropertyType.__CastFrom('Hp'))));
		self:ShowItem(self:GetItem("text_lingxi_def_value"), lingXiAddAttr.lingxiDef > 0);
		self:SetItemText("text_lingxi_def_value", "+" .. math.floor(lingXiAddAttr.lingxiDef* self.mMainCard:GetPropertyAddPercent(CS.client.CardPropertyType.__CastFrom('Def'))));
		self:ShowItem(self:GetItem("text_lingxi_crt_value"), lingXiAddAttr.lingxiCrit > 0);
		self:SetItemText("text_lingxi_crt_value", "+" .. math.floor((lingXiAddAttr.lingxiCrit * (1 + self.mMainCard:GetPropertyAddPercent(CS.client.CardPropertyType.__CastFrom('Crit'))) * 100)) .. "%");
		self:ShowItem(self:GetItem("text_lingxi_crd_value"), lingXiAddAttr.lingxiCritDam > 0);
		self:SetItemText("text_lingxi_crd_value", "+" .. math.floor((lingXiAddAttr.lingxiCritDam * (1+self.mMainCard:GetPropertyAddPercent(CS.client.CardPropertyType.__CastFrom('CritDam'))) * 100)) .. "%");

		local lingXiAddScore = math.floor(CS.client.CardUtility.GetTotalScore(lingXiAddAttr.lingxiAtk, lingXiAddAttr.lingxiDef, lingXiAddAttr.lingxiHP, self.mMainCard.Template.star));
		self:ShowItem(self:GetItem("text_lingxi_battle_value"), lingXiAddScore > 0);
		self:SetItemText("text_lingxi_battle_value", "+" ..math.floor(lingXiAddScore));
		
		--羁绊
		local bond = CS.TemplateManager.GetInstance():GetBondLevelByLevel(self.mMainCard.CardData.param.aid_level);
		if (bond.bond_level == 0) then
			self:GetItem("text_assist_exp"):SetActive(false);
		else
			if (bond.bond_level_exp <= 0) then
				self:GetItem("text_assist_exp"):SetActive(false);
			else
				self:GetItem("text_assist_exp"):SetActive(true);
				local expDes = self.mMainCard.CardData.param.aid_exp.."/" .. bond.bond_level_exp;
				self:SetItemText("text_assist_exp", expDes);
			end
			
			for i=0,3 do
				if(self.mBondIcon[i] ~= nil) then
					if(i < bond.bond_level_icon.Count) then
						self.mBondIcon[i]:SetActive(true);
                        self:LoadAndSetImage(bond.bond_level_icon[i], nil, self.mBondIcon[i]);
					else
						self.mBondIcon[i]:SetActive(false);
					end
				end
			end
		end
	end
end)


xlua.hotfix(CS.client.CharacterFosterView,"UserGiftSucceed",function(self,proto)
	print("CS.client.CharacterFosterView UserGiftSucceed")
	self.mSelectKeepSakeItemData = nil
	if(proto.opType == 4) then
		return
	elseif(proto.opType == 3) then
		self:UpdateGiftUI()
	else
		self.mLastUserGift = proto
		self:SetImageMaskState(true)
		self.mGiftEffectGo:SetActive(true)
		local compoundAnim = self:GetItem(self.mGiftEffectGo, "kapai_ten_1"):GetComponent(typeof(CS.UnityEngine.Animator))
		self.userGiftEffectTime = compoundAnim:GetCurrentAnimatorStateInfo(0).length + 1;
		self.playUserGiftSucceedEffect = true;
        self.inUseGift = true;
	end
end)

xlua.hotfix(CS.client.WuJianConstellationWeekDetailView,"RefreshUI",function(self,constellationWeekInfo)
	self:InitUI();
	if(constellationWeekInfo ~= nil) then
		for weekIndex=0,self.mWeekDay-1 do
			local itemGo;
			local itemParent;
			if(weekIndex == 0) then
				itemGo = self.mWeekDetailGos[self.mWeekDay - 1];
                itemParent = self.mWeekDetailGosParent[self.mWeekDay - 1].transform;
			else
				itemGo = self.mWeekDetailGos[weekIndex - 1];
                itemParent = self.mWeekDetailGosParent[weekIndex - 1].transform;
			end
			if(constellationWeekInfo:ContainsKey(weekIndex) and constellationWeekInfo[weekIndex].Count > 0) then
				itemGo:SetActive(false);
                local groupIds = constellationWeekInfo[weekIndex];
				for index = 0,groupIds.Count-1 do
					local go = CS.UnityEngine.GameObject.Instantiate(itemGo);
					go:SetActive(true);
					go.transform:SetParent(itemParent, false);
					local wuJianGuardiansItem = CS.client.WuJianGuardiansItem(go);
					wuJianGuardiansItem:UpdateUI(groupIds[index]);
					self.mWeekDetailItemGos:Add(go);
				end
			else
				itemGo:SetActive(true);
                CS.client.Global.GetGameObject(itemGo, "Team_Card"):SetActive(false);
			end
			
			itemParent:GetComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter)).enabled = false;
			CS.client.TimerManager.GetInstance():AddTimer(0.1,function()
				itemParent:GetComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter)).enabled = true;
			end)
		end
	end
	self.mWuJianMainView:StartCoroutine(self:SetWeekIndex());
end)

xlua.hotfix(CS.client.WuJianConstellationWeekDetailView,"RefreshUI",function(self,constellationWeekInfo)
	self:InitUI();
	if(constellationWeekInfo ~= nil) then
		for weekIndex=0,self.mWeekDay do
			local itemGo;
			local itemParent;
			if(weekIndex == 0) then
				itemGo = self.mWeekDetailGos[self.mWeekDay - 1];
                itemParent = self.mWeekDetailGosParent[self.mWeekDay - 1].transform;
			else
				itemGo = self.mWeekDetailGos[weekIndex - 1];
                itemParent = self.mWeekDetailGosParent[weekIndex - 1].transform;
			end
			if(constellationWeekInfo:ContainsKey(weekIndex) and constellationWeekInfo[weekIndex].Count > 0) then
				itemGo:SetActive(false);
                local groupIds = constellationWeekInfo[weekIndex];
				for index = 0,groupIds.Count-1 do
					local go = CS.UnityEngine.GameObject.Instantiate(itemGo);
					go:SetActive(true);
					go.transform:SetParent(itemParent, false);
					local wuJianGuardiansItem = CS.client.WuJianGuardiansItem(go);
					wuJianGuardiansItem:UpdateUI(groupIds[index]);
					self.mWeekDetailItemGos:Add(go);
				end
			else
				--itemGo:SetActive(true);
                CS.client.Global.GetGameObject(itemGo, "Team_Card"):SetActive(false);
			end
		end
	end
	self.mWuJianMainView:StartCoroutine(self:SetWeekIndex());
	CS.client.TimerManager.GetInstance():AddTimer(0.1,function()
		if(constellationWeekInfo ~= nil) then
			for weekIndex=0,self.mWeekDay do
				local itemParent;
				if(weekIndex == 0) then
					itemParent = self.mWeekDetailGosParent[self.mWeekDay - 1].transform;
				else
					itemParent = self.mWeekDetailGosParent[weekIndex - 1].transform;
				end
				itemParent:GetComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter)).enabled = false;
			end
			
		end
		
	end)
	CS.client.TimerManager.GetInstance():AddTimer(0.2,function()
		if(constellationWeekInfo ~= nil) then
			for weekIndex=0,self.mWeekDay do
				local itemParent;
				if(weekIndex == 0) then
					itemParent = self.mWeekDetailGosParent[self.mWeekDay - 1].transform;
				else
					itemParent = self.mWeekDetailGosParent[weekIndex - 1].transform;
				end
				
				itemParent:GetComponent(typeof(CS.UnityEngine.UI.ContentSizeFitter)).enabled = true;
			end
			
		end
		
	end)
end)


--优化,自己的排名显示真实排名，不显示排名区间
xlua.hotfix(CS.client.UIWorldBossUserRank,"SetData",function(self,rank,rankType)
	--print("UIWorldBossUserRank")
    if rank == nil then
        return;
    end
    CS.client.UIAssetSpecify.LoadAndSetSprite(self.mIcon, rank.IconId);
    CS.client.UIAssetSpecify.LoadAndSetSprite(self.mFrame, rank.FrameId);
    CS.client.UIAssetSpecify.LoadAndSetSprite(self.mBgFrame, rank.BgFrameId);
    CS.client.Global.SetItemText(self.mName, rank.Name);
    CS.client.Global.SetItemText(self.mTextHarm, tostring(rank.Harm));
    local myRankDes = tostring(rank.Rank);
    if myRankDes == "0" then
    	myRankDes = CS.TextManager.GetInstance():GetLocalizationString(CS.client.Constant.TEXT_BOSS_NO_RANK);
    end
    CS.client.Global.SetItemText(self.mTextRank, myRankDes);
end)

--优化,界面血条>99%显示99%，<1%显示1%
xlua.hotfix(CS.client.WorldBossItem,"SetData",function(self,protobuf)
	--print("WorldBossItem")
    if protobuf == nil then
        return;
    end;
    if self.mBoss ~= nil then
        self.mHp = self.mBoss.boss_hp;
        self.mMaxHp = self.mBoss.boss_hp;
    end
    self.mStage = protobuf.stage;
    self:SetListTotalRankInfo(protobuf);
    self:SetListSingleRankInfo(protobuf);
    if protobuf.self_single_rank ~= nil then
        self.mSelfSingleRank = CS.client.WorldBossUserRankInfo(protobuf.self_single_rank);
    end
    if protobuf.self_total_rank ~= nil then
        self.mSelfTotalRank = CS.client.WorldBossUserRankInfo(protobuf.self_total_rank);
    end
    if protobuf.boss == nil then
        return;
    end
    self.mUid = protobuf.boss.gid;
    self.mHp = protobuf.boss.hp;
    self.mMaxHp = protobuf.boss.maxhp;
    if self.mHp >= self.mMaxHp * 0.99 and self.mHp < self.mMaxHp then
        self.mHp = self.mMaxHp *0.99;
  	end
end)

--无剑灵犀属性框
xlua.hotfix(CS.client.WuJianChemistryItme, {
	['.ctor'] = function(self,templateType,id)
	self.mTempl = CS.TemplateManager.GetInstance():GetWuJianChemistryById(id);
    if self.mTempl ~= nil then
        self.mName = self:GetName();
        self.mAssistId = self:GetAssistId();
        self.mItemType = self:GetItemType();
        self.mDes = self:GetDes();
        self.mPath = self:GetPath();
        self.mPart = self:GetPart();
        self.mFrameId = CS.client.LingxiModel.GetFrameAssetIdByStar(self.mTempl.star);       
    end
	
end})


--优化,配合后端实验防加速
xlua.hotfix(CS.client.NetManager,"UpdateHeartBeat",function(self)
	--print("NetManager UpdateHeartBeat")
	local passTime = CS.UnityEngine.Time.time - self.mHeartBeatLastTime;
	if self.mIsSendingHeartBeat then
		if passTime >= 6 then
			self:CheckConnectState();
		end
	else
		if passTime >= 2 then
			self:DoHeartBeat();
		end
	end
end)

--优化,配合后端实验防加速
xlua.hotfix(CS.client.NetManager,"DoHeartBeat",function(self)
	--print("NetManager DoHeartBeat")
	self.mIsSendingHeartBeat = true;
	self.mHeartBeatLastTime = CS.UnityEngine.Time.time;

	local proto = CS.p2dprotocol.HeartBeat();
	self:_SendMsg(proto, false);
end)

--优化,配合后端实验防加速
xlua.hotfix(CS.client.NetManager,"_ResetHeartBeat",function(self)
	--print("NetManager _ResetHeartBeat")
	self.mIsSendingHeartBeat = false;
	self.mHeartBeatLastTime = CS.UnityEngine.Time.time;
end)

--battle表中pvp_set == 5时隐藏战斗里的蓝血条
xlua.hotfix(CS.client.UIWarChess,"OnContinueBattle",function(self)
	--print("UIWarChess OnContinueBattle")
	local continueBattleModel = CS.client.ModelManager.GetRequired_Lua(typeof(CS.client.ContinueBattleModel))
	if continueBattleModel.IsContinueBattle then
		self:SetAutoAttack();
	end
	local battleId = self.warChessController:GetWarChessModule():GetWarChessData():GetBattleId();
	local battleTemp = CS.TemplateManager.GetInstance():GetBattleById(battleId);
	local rectTrans = self.bossRoot:GetComponent(typeof(CS.UnityEngine.RectTransform));
	if battleTemp ~= nil and rectTrans ~= nil then
		if battleTemp.pvp_set == 5 then
			rectTrans.localScale = CS.UnityEngine.Vector3(0,0,0);
		else
			rectTrans.localScale = CS.UnityEngine.Vector3(1,1,1);
		end	
	end
end)

--世界boss战斗中显示回合数
xlua.hotfix(CS.client.UIWarChess,"InitWinConditionUI",function(self)
	--print("UIWarChess InitWinConditionUI")
	return;
end)



xlua.hotfix(CS.client.WebMainView, "OnShowQuestion", function(self,pageId)
	--print("OnShowQuestion pageId ",pageId)
	
	local questWebAddr = "";
	local pageActivity = CS.TemplateManager.GetInstance():GetPageActivityById(pageId);
	--print("OnShowQuestion pageActivity ",pageActivity)
	--print("OnShowQuestion CS.UnityEngine.Application.platform ",CS.UnityEngine.Application.platform)
	--print("OnShowQuestion pageActivity.html_URL_IOS ",pageActivity.html_URL_IOS)
	--print("OnShowQuestion pageActivity.html_URL_android ",pageActivity.html_URL_android)
	if(CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.__CastFrom('IPhonePlayer')) then
		questWebAddr = pageActivity.html_URL_IOS;
	elseif(CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.__CastFrom('Android')) then
		questWebAddr = pageActivity.html_URL_android;
	end
	--print("OnShowQuestion questWebAddr ",questWebAddr)
    local uid = CS.client.GameCore.GetUID();
	--print("OnShowQuestion uid ",uid)
	local sid = CS.client.NetManager.GetInstance():GetServerTag();
	--print("OnShowQuestion sid ",sid)
	questWebAddr = pageActivity.html_URL_android.."uid="..uid.."&sid="..sid
	--print("OnShowQuestion questWebAddr2 ",questWebAddr)


	if(CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.__CastFrom('WindowsEditor') or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.__CastFrom('WindowsPlayer')) then
		local content = CS.TextManager.GetInstance():GetLocalizationString(46948);
		CS.client.BubbleTipsModel.Show(content);
		return
	end
	
	local bottomLeftWebNode = self:GetItem("bottom_left_web_node");
	--print("OnShowQuestion bottomLeftWebNode ",bottomLeftWebNode)
	local topRightWebNode = self:GetItem("top_right_web_node");
	--print("OnShowQuestion topRightWebNode ",topRightWebNode)
	
	local sR = CS.client.Global.GetSafeArea();
	--print("OnShowQuestion sR ",sR)
	
	CS.client.UniWebManager.GetInstance():ShowWeb(questWebAddr, bottomLeftWebNode, topRightWebNode, sR.x,
		function()
			CS.client.WebMainView:LoadWebFinish();
		end
	);
	
end)











