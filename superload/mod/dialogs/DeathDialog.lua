-- This file is part of an attempt to manage deaths sanely in multiplayer. See Party.lua

local _M = loadPrevious(...)

--- Send the party to the Eidolon Plane
local base_eidolonPlane = _M.eidolonPlane
function _M:eidolonPlane()
--	self.actor:setEffect(self.actor.EFF_EIDOLON_PROTECT, 1, {})
	game:onTickEnd(function()
		if not self.actor:attr("infinite_lifes") then
			self.actor:attr("easy_mode_lifes", -1)
			game.log("#LIGHT_RED#You have %s left.", (self.actor:attr("easy_mode_lifes") and self.actor:attr("easy_mode_lifes").." life(s)") or "no more lives")
		end

		local is_exploration = game.permadeath == game.PERMADEATH_INFINITE
		--self:cleanActor(self.actor)
		--self:resurrectBasic(self.actor)
		for e, _ in pairs(game.party.members) do
			self:cleanActor(e)
			--bring player2 into eidolon plane
			if game.party.members[e].title == "Main character" then
				---doesn't exist all of a sudden?
				self.resurrectBasic(e)
			end
		end
		for uid, e in pairs(game.level.entities) do
			if not is_exploration or game.party:hasMember(e) then
				self:restoreResources(e)
			end
		end

		game.party:goToEidolon(self.actor)

		game.log("#LIGHT_RED#From the brink of death you seem to be yanked to another plane.")
		game.player:updateMainShader()
		if not config.settings.cheat then game:saveGame() end
	end)
	return true
end

return _M