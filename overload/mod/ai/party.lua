local Player = require "mod.class.Player"
local Party = require "mod.class.Party"
--[[

local _M = loadPrevious(...)

newAI("player_party_member", function(self)
	self.player.ai = "player_party_member"
	self.party:setPlayer(self)
end)
newAI("party_member", function(self)
	self.player.ai = "party_member"
	self.party:setPlayer(self)
	return 0/0
end)

return _M
]]--
-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2018 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newAI("party_member", function(self)
--stop controlling golems and letting Norgan act multiple times
if game.party.members[self].title == "Main character" then
--game.party means enemies don't also form parties?
--if true then
	--game.player.ai = "party_member"
	--currentplayer = game:getPlayer(true)
	--currentplayer.control="full"
	--currentplayer.orders = {target=true, anchor=true, behavior=true, leash=true, talents=true}
	--currentplayer.type="player"
	--currentplayer.title="Main character"
	--currentplayer.main=true
	--self.ai = "party_member"
	--self.control="full"
	--self.orders = {target=true, anchor=true, behavior=true, leash=true, talents=true}
	--self.type="player"
	--self.title="Main character"
	--self.main=true
	--self.ai = ""
	--debug--game.logPlayer(game.player, "Turn %s: Current player is %s, AI action taken by %s:", game.turn, game.player.name, self.name)
	
	--attempt to continue autoexplore/run after handoff+handback
	--mod/class/game.lua REST RUNAUTO restInit( 
	--engine/interface/PlayerRun.lua PlayerRest.lua 	--mod/class/Player.lua onRestStart onRestStop
	
	--game.player._runStop = game.player.runStop
	--game.player._restStop = game.player.restStop
	
	--save player1's resting state
	game.player.resting_continue=game.player.resting
	game.player.running_continue=game.player.running
	
	game.party:setPlayer(self) --forcing handoff takes a turn?
	
	--restore player2's resting state
	if game.player.resting_continue then
		game.player.resting =	game.player.resting_continue
			game.player.resting_continue = false
		--game.player:restInit()
		game.player:restStep()
	end
	if game.player.running_continue then
		--local dir = game.player.running_continue.dir
		game.player.running =	game.player.running_continue
			game.player.running_continue = false
		--game.player.runInit(dir)
		game.player:runStep()
	end
	
	--game.player.runStop = game.player._runStop
	--game.player.restStop = game.player._restStop
	--currentplayer.ai = "party_member"
	--game.turn = game.turn - 9 --...so turns can go backward and (turn numbers) don't matter.
	
	--This can't be right.
	self.energy.value = self.energy.value + game.energy_to_act
	
	--what does the return value mean?
	return
else
	
	local anchor = self.ai_state.tactic_leash_anchor

	-- Stay close to the leash anchor
	if anchor and self.ai_state.tactic_leash and anchor.x and anchor.y then
		local leash_dist = core.fov.distance(self.x, self.y, anchor.x, anchor.y)
		if self.ai_state.tactic_leash < leash_dist then
--			print("[PARTY AI] leashing to anchor", self.name)
			return self:runAI("move_anchor")
		end
	end

	-- Unselect friendly targets
	if self.ai_target.actor and self:reactionToward(self.ai_target.actor) >= 0 then self:setTarget(nil) end

	-- Run normal AI
	local ret = self:runAI(self.ai_state.ai_party)

	if not ret and anchor and not self.energy.used then
--		print("[PARTY AI] moving towards anchor", self.name)
		return self:runAI("move_anchor")
	else
		return ret
	end
end
end)

newAI("move_anchor", function(self)
	local anchor = self.ai_state.tactic_leash_anchor
	if anchor and anchor.x and anchor.y then
		local a = engine.Astar.new(game.level.map, self)
		local path = a:calc(self.x, self.y, anchor.x, anchor.y)
		if not path then
			return self:moveDirection(anchor.x, anchor.y)
		else
			local moved = self:move(path[1].x, path[1].y)
			if not moved then return self:moveDirection(anchor.x, anchor.y) end
		end
	end
end)

