AiLogic interface
***
* 获取AI
    
        GetTargetTable(aiName)
* 获取行为

        GetAIBehavior(uid,aiName)
* 获取大招行为
    
        GetUltimateSkillAIBehavior(uid,aiName)
---

BaseAI interface
***
* 获取玩家位置
    
            GetPlayerItemPos(uid)
* 获取棋子位置

            GetItemPos(uid)
* 获取棋子位置

            GetItemPos(uid)
* 获取玩家列表

            GetPlayerUids()
* 获取敌方列表
            
            GetOpponentUids()
* 获取buff列表
            
            GetWarChessBuffUids()
* 获取buff类型
            
            GetBuffEffectType(uid)
* 获取最近目标位置
            
            GetTargetPositionByDistance(uid,opponentUids)
* 获取移动步数
            
            GetItemStepNum(uid)
* 获取移动路径
     
            GetMoveToTargetPositionPath(sourcePosition,targetPosition,isIgnoreTargetPosition)
* 获取移动路径(限制移动步数)

            GetMoveToTargetPathByStemNum(uid,targetPosition,isIgnoreTargetPosition)
* 获取路径最少的目标点
            
            GetMinCostStepNumPos(sourcePos,targets)
* 不包含有害buff的路径
            
            GetIgnoreHarmfulBuffPath(uid,targetPosition,isIgnoreTargetPosition)
* buff路径
           
           GetBuffEffectPath
* 获取血量信息            
            
            GetItemHpInfo(uids)
* 可不可以释放主动技能
            
            IsCanReleaseSingleSkill(uid)
* 技能可以打到的目标
           
            GetSkillAttackResults(uid,itemPos,skillId)
* 获取技能可以打到最多人的技能释放点
           
            GetSkillAttackMaxItemSkillPos(uid,itemPos,skillId)
* 获取技能可以打到最多的目标 并且包含目标targetUid的技能点          
            
            GetSkillAttackMaxItemSkillPosContainTarget(uid,itemPos,skillId,targetUid)
            
* 获取主动技能ID
            
            GetSingleSkillId(uid)
* 是否可以普攻
           
            IsCanAttack(itemPos)
* 获取普攻ID            
            
            GetAttackSkillId(uid)
* 获取技能可以打到指定目标的点
              
            GetCanAttackPosTable(uid,skillId,targetPos)  
* 获取技能释放点
              
            GetSkillPos(uid,itemPos,skillId,selectTargetRange,selectTargetType)
* 判断是否是己方
         
            IsPlayer(uid)
* 判断是否是敌方
            
            IsOpponent(uid)
* 获取当前怒气值
            
            GetCurrentMp()
* 获取等级
            
            GetItemLevel(uid)
* 选出血量少于指定值(百分比)的目标
            
            (targets,hpPercent)
* 获取预警技作用的格子
            
            GetBossArertPostions()
* 包含
            
            IsContain(itemId,itemIds)
* 是否有不受预警技影像的线路
            
            HavePathNotAffectedByBossArert(uid,skillId,targetId)
* 取不受boss预警技影响的目标
            
            GetUidsNotAffectedByBossArert(uid,skillId,targets)
* 技能是否可以打到目标点
             
            IsSkillContainTarget(uid,skillId,targetId)
* 选出血量最少的目标
            
            GetMinHpUid(targets)
* 获取敌人上下左右玩家的uid
            
            GetPlayerUidsRoundOpponent(opponentUid)
* 筛选出敌人上下左右有玩家的敌人
            
            GetOpponentUidsHavePlayerRound(playerUid,opponentUids)
* 得到玩家属性
            
            GetAttributeByUid(uid)
* 得到源属性是否克制目标属性
            
            IsRestrainAttribute(sourceAttribute,targetAttribute)
* 得到不克制玩家属性属性的敌人列表
            
            GetNotRestrainPlayerAttributeUids(uid,opponentUids)
* 得到玩家克制的敌人列表
             
            GetRestrainOpponentUids(uid,opponentUids)
* 根据玩家可以移动的步数得到玩家可以到达的区域
            
            GetPlayerCanArraveAreaTable(uid)
* 根据玩家可以移动的步数得到玩家可以到达的区域 去掉受boss预警技影响的点
            
            GetPlayerCanArraveAreaNotIncludeBossArert(uid)
* 获取除了目标点以外的点
            
            GetPostionsExceptSourcePostion(sourcePostion,targetPostions)
* 对目标点进行排序 到达目标点步数由少到多的
            
            GetTargetsSortByStepNum()
            
        
            
            
            
            


            