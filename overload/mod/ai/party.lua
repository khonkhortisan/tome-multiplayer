--local Player = require "mod.class.Player"
--local Party = require "mod.class.Party"
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
local oldp, newp = game.player, self
--stop controlling golems and letting Norgan act multiple times
if game.party.members[newp].title == "Main character" then
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
	
	--THROW items
	--[[
	local chest = self.zone:makeEntityByName(self.level, "object", "TRANSMO_CHEST")
			if chest then
				self.zone:addEntity(self.level, chest, "object")
				self.player:addObject(self.player:getInven("INVEN"), chest)
			end
	local orb = game.zone:makeEntityByName(game.level, "object", "ORB_SCRYING")
			if orb then player:addObject(player:getInven("INVEN"), orb) orb:added() orb:identify(true) end
	--]]
	--local chest = game.zone:getEntityByName(oldp.level, "object", "TRANSMO_CHEST")
	--local orb = game.zone:getEntityByName(oldp.level, "object", "ORB_SCRYING")
	
	--[[
	local chest, chest_item = oldp:findInInventory(oldp:getInven("INVEN"), "Transmogrification Chest")
	local orb, orb_item = oldp:findInInventory(oldp:getInven("INVEN"), "Scrying Orb")
	newp:addObject(newp:getInven("INVEN"), chest)
	newp:addObject(newp:getInven("INVEN"), orb)
	--]]
	
	
	--if it's actually my turn
	--if (not game.player:enoughEnergy()) and self:enoughEnergy() then
	--if newp:enoughEnergy() then
	--save player1's resting state
	oldp.resting_continue=oldp.resting
	oldp.running_continue=oldp.running
	--these are arrays containing functions
	
	--local energy_freeze1,energy_freeze2 = oldp.energy.value, newp.energy.value
	
	--forcing handoff takes a turn? 
	game.party:setPlayer(newp) --game.player: oldp→newp
	--mod/class/Party.lua:setPlayer calls mod/class/Actor.lua:move with force=true which doesn't call self:useEnergy
	
	--game.paused = true
	
	--This can't be right.
	--self.energy.value = self.energy.value + game.energy_to_act
	--oldp.energy.value, newp.energy.value = energy_freeze1, energy_freeze2
	--from mod/class/NPC.lua
	-- If AI did nothing, use energy anyway
		--if not self.energy.used then self:useEnergy() end
		--if old_energy == self.energy.value then break end -- Prevent infinite loops
	self.energy.used = true --STOP USING UP TURNS ON PLAYER SWITCH
	
	--restore player2's resting state
	if newp.resting_continue then
		newp.resting =	newp.resting_continue
			newp.resting_continue = false
		--newp:restInit()
		newp:restStep()
	end
	if newp.running_continue then
		--local dir = newp.running_continue.dir
		newp.running =	newp.running_continue
			newp.running_continue = false
		--newp.runInit(dir)
		newp:runStep()
	end
	
	--game.player.runStop = game.player._runStop
	--game.player.restStop = game.player._restStop
	--currentplayer.ai = "party_member"
	--game.turn = game.turn - 9 --...so turns can go backward and (turn numbers) don't matter.
	--end
	
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

