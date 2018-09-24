local Map = require "engine.Map"

local _M = loadPrevious(...)

local base_setPlayer = _M.setPlayer
function _M:setPlayer(actor, bypass)
	if type(actor) == "number" then actor = self.m_list[actor] end

	if not bypass then
		local ok, err = self:canControl(actor, true)
		if not ok then return nil, err end
	end

	if actor == game.player then return true end

	-- Stop!!
	if game.player and game.player.runStop then game.player:runStop("Switching control") end
	if game.player and game.player.restStop then game.player:restStop("Switching control") end

	local def = self.members[actor]
	local oldp = self.player
	self.player = actor

	-- Convert the class to always be a player
	if actor.__CLASSNAME ~= "mod.class.Player" and not actor.no_party_class then
		actor.__PREVIOUS_CLASSNAME = actor.__CLASSNAME
		local uid = actor.uid
		actor.replacedWith = false
		actor:replaceWith(mod.class.Player.new(actor))
		actor.replacedWith = nil
		actor.uid = uid
		__uids[uid] = actor
		actor.changed = true
	end

	-- Setup as the curent player
	actor.player = true
	game.paused = actor:enoughEnergy()
	game.player = actor
	game.uiset.hotkeys_display.actor = actor
	Map:setViewerActor(actor)
	if game.target then game.target.source_actor = actor end
	if game.level and actor.x and actor.y then game.level.map:moveViewSurround(actor.x, actor.y, 8, 8) end
	actor._move_others = actor.move_others
	actor.move_others = true

	-- Change back the old actor to a normal actor
	if oldp and oldp ~= actor then
		if self.members[oldp] and self.members[oldp].on_uncontrol then self.members[oldp].on_uncontrol(oldp) end

		if oldp.__PREVIOUS_CLASSNAME then
			local uid = oldp.uid
			oldp.replacedWith = false
			oldp:replaceWith(require(oldp.__PREVIOUS_CLASSNAME).new(oldp))
			oldp.replacedWith = nil
			oldp.uid = uid
			__uids[uid] = oldp
		end

		actor.move_others = actor._move_others
		oldp.changed = true
		oldp.player = nil
		if game.level and oldp.x and oldp.y then oldp:move(oldp.x, oldp.y, true) end
	end

	if def.on_control then def.on_control(actor) end

	if game.level and actor.x and actor.y then actor:move(actor.x, actor.y, true) end

	if not actor.hotkeys_sorted then actor:sortHotkeys() end

	game.logPlayer(actor, "#MOCCASIN#Character control switched to %s.", actor.name)

	if game.player.resetMainShader then game.player:resetMainShader() end

	return true
end

return _M