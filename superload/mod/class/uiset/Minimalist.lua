-- This file shows messages for players whose turn it currently isn't, as they'd see things happen to them out of turn in singleplayer. See Minimalist.lua, Classic.lua

local _M = loadPrevious(...)

local showplayername = true -- debug

local base_activate = _M.activate
function _M:activate()

	local retval = base_activate(self)
		
	--	game.logSeen = function(e, style, ...) if e and e.player or (not e.dead and e.x and e.y and game.level and game.level.map.seens(e.x, e.y) and game.player:canSee(e)) then game.log(style, ...) end end
--		game.logPlayer = function(e, style, ...) if e == game.player or e == game.party then game.log(style, ...) end end
--	if showplayername then
	game.logPlayer = function(e, style, ...) 
		
		if showplayername then
			style = "logPlayer["..e.name.."] "..style
		end
		
		--might need to allow game.player back in for controlled alchemist golems
		if (game.party.members[e] and game.party.members[e].main) or e == game.party then
			game.log(style, ...)
		end
	end	
		
	--- Output a message to the log based on the visibility of an actor to the player
	-- @param e the actor(entity) to check visibility for
	-- @param style the message to display
	-- @param ... arguments to be passed to format for style
	function game.logSeen(e, style, ...)
		
		--if e and e.player or (not e.dead and e.x and e.y and game.level and game.level.map.seens(e.x, e.y) and game.player:canSee(e)) then game.log(style, ...) end
		if
			--if specific player mentioned, log immediately ("I've been shot!")
			--e and e.player or
			e and e.player then
				if showplayername then
					style = "logSeen["..e.name.."] "..style
				end
				game.log(style, ...)
				return
		--elseif
		end
		--e is a living monster? Or controllable party member?
		--should loop this whole line for party members.
		--map.seens might require a fog of war change.
		--or (not e.dead and e.x and e.y and game.level and game.level.map.seens(e.x, e.y) and game.player:canSee(e)) then
		if (not e.dead and e.x and e.y and game.level and game.level.map.seens(e.x, e.y)) then
			if game.player:canSee(e) then
				if showplayername then
					--seen by game.player
					style = "logSeen["..e.name..'|'..game.player.name.."] "..style
				end
				game.log(style, ...)
				return
			end
			for act, _ in pairs(self.party.members) do
				--don't log non-player party members (escorts/uncontrolled alchemist golems)
				if game.party.members[act].main and game.party.members[act]:canSee(e) then
						if showplayername then
							--seen by game.player
							style = "logSeen["..e.name..'|'..act.name.."] "..style
						end
						game.log(style, ...)
						return
				end
			end
		end
	end
	
	--logVisible
	
	--logMessage
	
	--delayedLogMessage - a killed b happening ~~after player switch~~ at next player turn?
	
	--displayDelayedLogMessage
	--displayDelayedLogDamage
	
	--delayedLogDamage
	
	return retval --does nothing but keeping it in
end
return _M