local base_party_member_fct = function(self)
--newAI("party_member", function(self)
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

--local _M = loadPrevious(...)

--- Define AI
--local base_newAI = _M.newAI
--function _M:newAI(name, fct)
newAI("party_member", function(self)
--[[
	if name ~= "party_member" then
		--edit nothing in other AI
		--_M.ai_def[name] = fct
		base_newAI(name, fct)
	else
		_M.ai_def[name] = function(self)
--]]
			--stop controlling golems and letting Norgan act multiple times
			if not (	game.party.members[self] and 
				game.party.members[self].title == "Main character") then
				--act normal, it's not a player
				--fct(self)
				base_party_member_fct(self)
			else
				local oldp, newp = game.player, self
				
				-- [[
				--create starting items. Move this to Game.lua.
				if not newp:findInInventory(newp:getInven("INVEN"), "Transmogrification Chest") then
					local chest, chest_item = oldp:findInInventory(oldp:getInven("INVEN"), "Transmogrification Chest")
					if chest then newp:addObject(newp:getInven("INVEN"), chest) end
				end
				if not newp:findInInventory(newp:getInven("INVEN"), "Scrying Orb") then
					local orb, orb_item = oldp:findInInventory(oldp:getInven("INVEN"), "Scrying Orb")
					if orb then newp:addObject(newp:getInven("INVEN"), orb) end
				end
				--rod of recall takes multiple turns, can't just automatically switch it, right?
				--]]

				--save player1's resting state
				--these are arrays containing functions
				oldp.resting_continue=oldp.resting
				oldp.running_continue=oldp.running
				
				--game.player→oldp
				game.party:setPlayer(newp) --game.party means enemies don't also form parties?
				--game.player→newp
				
				--This can't be right.
				--self.energy.value = self.energy.value + game.energy_to_act
				--oldp.energy.value, newp.energy.value = energy_freeze1, energy_freeze2
				--from mod/class/NPC.lua
				-- If AI did nothing, use energy anyway
					--if not self.energy.used then self:useEnergy() end
					--if old_energy == self.energy.value then break end -- Prevent infinite loops
				--self.energy.used = true --STOP USING UP TURNS ON PLAYER SWITCH
				--don't use a turn just taking control
				--newp.energy.used = true
				--don't freeze all enemies, though.
				--newp.energy.value = newp.energy.value + game.energy_to_act
				self.energy.used = true
				
				--restore player2's resting state
				if newp.resting_continue then
					newp.resting =	newp.resting_continue
						newp.resting_continue = false
					newp:restStep()
				end
				if newp.running_continue then
					newp.running =	newp.running_continue
						newp.running_continue = false
					newp:runStep()
				end
			end
--		end)
--	end
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

--return _M