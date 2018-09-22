local _M = loadPrevious(...)

newAI("player_party_member", function(self)
	self.player.ai = "player_party_member"
	self.party:setPlayer(player)
end)

return _M