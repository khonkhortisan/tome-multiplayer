local _M = loadPrevious(...)

--mess with base dialog
local base_init = _M.init
function _M:init(title, actor, order, at_end, quickbirth, w, h)

	local retval = base_init(self, title, actor, order, at_end, quickbirth, w, h)
	
	--attempt changing field after-the-fact
	if config.settings.multiplayer_num > 1 then
		self.c_name:setText(game.player_name..config.settings.multiplayer_num)
	else
		self.c_name:setText("multiplayer") --for testing quickly and showing that it loaded
	end
	
	self.c_cancel.fct=function()
		if config.settings.multiplayer_num > 1 then
			config.settings.multiplayer_num = config.settings.multiplayer_num - 1
			game:unregisterDialog(self)
			
			--self.player.explode
			local extraplayer = game.player
			game.party:setPlayer(game.party:findMember{main=true})
			extraplayer.exp_worth = 0
			extraplayer.on_die = nil
			extraplayer.die = nil
			extraplayer:die()
			game.party:removeMember(extraplayer, true)
			
			--or turn into temporal clone
			--data/talents/chronomancy/anomaly.lua anomaly evil twin
			--data/talents/chronomancy/chronomancer makeparadoxclone
			if game.party and game.party:findMember{main=true} then
			game.logPlayer(game.player, "#MOCCASIN#Failing to add a player has upset the time stream!")
			game.player:forceUseTalent(game.player.T_ANOMALY_EVIL_TWIN, {ignore_energy=true})
			end
		else
			self:atEnd("quit")
		end
	end
	
	return retval
end
return _M