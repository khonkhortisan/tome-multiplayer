local _M = loadPrevious(...)

--- Define AI
function _M:newAI(name, fct)
	if not name == "party_member" then
		--edit nothing in other AI
		_M.ai_def[name] = fct
	else
		_M.ai_def[name] = function(self)
			
			--stop controlling golems and letting Norgan act multiple times
			if not (game.party.members[self] and game.party.members[self].title == "Main character") then
			--if not self.main then
			--if not self.title == "Main character" then
				--act normal, it's not a player
				fct(self)
			else
				local oldp, newp = game.player, self
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
				
				-- [[
				if not newp:findInInventory(newp:getInven("INVEN"), "Transmogrification Chest") then
					local chest, chest_item = oldp:findInInventory(oldp:getInven("INVEN"), "Transmogrification Chest")
					newp:addObject(newp:getInven("INVEN"), chest)
				end
				if not newp:findInInventory(newp:getInven("INVEN"), "Scrying Orb") then
					local orb, orb_item = oldp:findInInventory(oldp:getInven("INVEN"), "Scrying Orb")
					newp:addObject(newp:getInven("INVEN"), orb)
				end
				--rod of recall takes multiple turns, can't just automatically switch it, right?
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
				--return
			end
		end
	end
end

return _M