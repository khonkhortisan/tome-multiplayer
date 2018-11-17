-- This file fixes only player1 allowed to autopickup items

local _M = loadPrevious(...)
local base_on_prepickup = _M.on_prepickup

--- Called when trying to pickup
function _M:on_prepickup(who, idx)
	--if self.quest and who ~= game.party:findMember{main=true} then
	if self.quest and not game.party.members[who].main then
		return "skip"
	end
	if who.player and self.lore then
		game.level.map:removeObject(who.x, who.y, idx)
		game.party:learnLore(self.lore)
		return true
	end
	if who.player and self.force_lore_artifact then
		game.party:additionalLore(self.unique, self:getName(), "artifacts", self.desc)
		game.party:learnLore(self.unique)
	end
end
return _M