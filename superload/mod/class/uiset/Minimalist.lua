-- This file shows messages for players whose turn it currently isn't, as they'd see things happen to them out of turn in singleplayer. See Minimalist.lua

--[[
require "engine.class"
local UI = require "engine.ui.Base"
local UISet = require "mod.class.uiset.UISet"
local DebugConsole = require "engine.DebugConsole"
local HotkeysDisplay = require "engine.HotkeysDisplay"
local HotkeysIconsDisplay = require "engine.HotkeysIconsDisplay"
local ActorsSeenDisplay = require "engine.ActorsSeenDisplay"
local LogDisplay = require "engine.LogDisplay"
local LogFlasher = require "engine.LogFlasher"
local FlyingText = require "engine.FlyingText"
local Shader = require "engine.Shader"
local ActorResource = require "engine.interface.ActorResource"
local Tooltip = require "mod.class.Tooltip"
local TooltipsData = require "mod.class.interface.TooltipsData"
local Dialog = require "engine.ui.Dialog"
local Map = require "engine.Map"
local FontPackage = require "engine.FontPackage"
--]]

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
			style = '['..e.name.."] "..style
		end
		
		if (game.party.members[e] and game.party.members[e].main) or e == game.party then
			game.log(style, ...)
		end
	end	
	
	return retval
end
return _M