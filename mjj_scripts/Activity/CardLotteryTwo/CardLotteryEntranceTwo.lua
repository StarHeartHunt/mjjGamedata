function Awake( ... )
	CS.client.Global.RegisterButtonClick(self.gameObject, function( ... )
		CS.client.UIManager.GetInstance():Show("UILuaDialog", "Activity/CardLottery/CardLotteryTwo")
	end)
end