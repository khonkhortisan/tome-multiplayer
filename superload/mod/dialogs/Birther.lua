local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
--local Party = require "mod.class.Party"
--local Player = require "mod.class.Player"

local _M = loadPrevious(...)

--mess with base dialog
local base_init = _M.init
function _M:init(title, actor, order, at_end, quickbirth, w, h)
  -- Do stuff "before" loading the original file

  -- make new num_players dialog?
  
  -- execute the original function
  --player 1 (first dialog made, last closed)
  local retval = base_init(self, title, actor, order, at_end, quickbirth, w, h)
  --	self.c_ok = Button.new{text="     Play!     ", fct=function() self:atEnd("created") end}
  --	self.c_cancel = Button.new{text="Cancel", fct=function() self:atEnd("quit") end}

  
  
  --Make Play button only work if last player
  --Make Cancel button only work...when?
  
  --button in bottom dialog or in party list at top to add new player
  --cancel removes new player and goes back to previous, or exits if ran out of players
  --play adds the current character, goes to new actually play/cancel/edit dialog?
  
  
  
  -- Do stuff "after" loading the original file
  --Dialog:yesnoPopup("Did it work?", "Superload attempted.", true, "No", "Yes I'm sure")
  --
  -- return whatever the original function would have returned
  return retval
end

--add button for multiplayer
local base_loadUI = _M.loadUI
function _M:loadUI(_array)
  --collect player values, make new dialog or edit old one?
  --change playername to playername2
  self.c_add_player = Button.new{text="Next Player", fct=function()
	
	--actually do something here toward multiplayer
	--add placeholder first character to party, let party dialog open on its own,
	-- replace/empty values?
	
	--get player info,
	--from Game.lua
	--self.actor
	--self.party.members
	--self.party = Party.new{}
	--[[
	local player = Player.new{name=self.player_name, game_ender=true}
	self.party:addMember(player, {
		control="full",
		type="player",
		title="Main character2",
		main=true,
		orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
	})
	self.party:setPlayer(player)
	
	local player = Player.new{name=self.player_name, game_ender=true}
	self.party:addMember(player, {
		control="full",
		type="player",
		title="Main character3",
		main=true,
		orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
	})
	self.party:setPlayer(player)
	]]
	
	--a way to add a return value
	--self.party.player.title = "Multiplayer"
	self:atEnd("created")
	
	--make character,
	--add to party
	
	--don't open this dialog again, once should serve purposes.
	--Assuming the list of players can be stored in a {party} array.
	--base_init(self, title, actor, order, at_end, quickbirth, w, h)
	
	--add Previous Player as inverted hide state to Next Player:
	--  moves last player in party back into dialog
  end}
  --~~made hide state match Play! hide state~~
  --self.c_rem_player = Button.new{text="Previous Player", fct=function() end}
  
  --should probably check whether this is actually the character creation dialog
  --  before assuming there's a cancel button
  table.insert(_array,{right=self.c_cancel, bottom=0, ui=self.c_add_player, hidden=true})
  --table.insert(_array,{right=self.c_add_player, bottom=0, ui=self.c_rem_player, hidden=true})
  
  --self:setupUI()
  base_loadUI(self, _array)
end

--match Next Player button hide state to Play! button
--aka fill out first player before moving on to second
local base_toggleDisplay = _M.toggleDisplay
function _M:toggleDisplay(button, ok)
  base_toggleDisplay(self, button, ok)
  if button.text=="     Play!     " then
	base_toggleDisplay(self, self.c_add_player, ok)
	--self.c_add_player.text=(ok and "Next" or "Previous").." Player"
  end
end


return _M