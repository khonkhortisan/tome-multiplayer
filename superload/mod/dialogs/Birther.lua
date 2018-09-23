local _M = loadPrevious(...)

--mess with base dialog
local base_init = _M.init
function _M:init(title, actor, order, at_end, quickbirth, w, h)

	local retval = base_init(self, title, actor, order, at_end, quickbirth, w, h)
	
	--attempt changing field after-the-fact
	if config.settings.multiplayer_num > 1 then
		self.c_name:setText(game.player_name..config.settings.multiplayer_num)
	end
	
	self.c_cancel.fct=function()
		if config.settings.multiplayer_num > 1 then
			game:unregisterDialog(self)
			
			--self.player.explode
			game.player.exp_worth = 0
			game.player.on_die = nil
			game.player.die = nil
			game.player:die()
			game.party:removeMember(game.player, true)
			
			--or turn into temporal clone
			--data/talents/chronomancy/anomaly.lua anomaly evil twin
			--data/talents/chronomancy/chronomancer makeparadoxclone
			if game.party and game.party:findMember{main=true} then
			--game.party:findMember{main=true}:forceUseTalent(self.T_ANOMALY_EVIL_TWIN, {ignore_energy=true})
			end
		else
			self:atEnd("quit")
		end
	end
	
	return retval
end
return _M