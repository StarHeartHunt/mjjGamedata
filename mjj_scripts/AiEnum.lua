AiEnum = {}

--ai选取目标规则枚举
AiEnum.AiSkillSelectTargetType = {
	--目标人数最多
	MaxTargetNum = 0,
	--选中血最少的(满血不加)
	MinHp = 1,
	--目标身上没有相同buff
	CannotFindSameBuff = 2,
}
--ai选取目标范围枚举
AiEnum.AiSkillSelectTargetRange = {
	--敌方
	Opponent = 0,
	--己方
	Player = 1,
	--自己
	CurrentPiece = 2,
	--空地
	Space = 3,
	--所有在场角色
	AllPiece = 4,
}
--卡牌属性枚举
AiEnum.CardAttribute = {
	--阴
	Yin = 9,
	--阳
	Yang = 10,
	--刚
	Hard = 11,
	--柔
	Soft = 12,
}
--属性克制关系
--key属性的克制value属性的
AiEnum.AiAttributeRestrain = {
	[9] = 12,
	[10] = 9,
	[11] = 10,
	[12] = 11
}
AiEnum.AiType = {
	--智能型
	Default = 1,
	--攻击性
	Attack = 2
}
return AiEnum
