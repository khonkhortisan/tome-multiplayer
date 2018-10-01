local _M = loadPrevious(...)

--- Define AI
function _M:newAI(name, fct)
	if not name == "party_member" then
		--edit nothing in other AI
		_M.ai_def[name] = fct
	else
		_M.ai_def[name] = function(self)
			--stop controlling golems and letting Norgan act multiple times
			if not (	game.party.members[self] and 
				game.party.members[self].title == "Main character") then
				--act normal, it's not a player
				fct(self)
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

				--don't use a turn just taking control
				newp.energy.used = true
				
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
		end
	end
end
return _M