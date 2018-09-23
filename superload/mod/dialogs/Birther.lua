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
			--self.player.explode
			--game:unregisterDialog(retval)
		else
			self:atEnd("quit")
		end
	end
	
	return retval
end
return _M