local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"

local _M = loadPrevious(...)

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
  Dialog:yesnoPopup("Did it work?", "Superload attempted.", true, "No", "Yes I'm sure")
  --
  -- return whatever the original function would have returned
  return retval
end

local base_loadUI = _M.loadUI
function _M:loadUI(_array)
  self.c_add_player = Button.new{text="Next Player", fct=function() base_init(self, title, actor, order, at_end, quickbirth, w, h) end}
  --should probably check whether this is actually the character creation dialog
  --  before assuming there's a cancel button
  table.insert(_array,{right=self.c_cancel, bottom=0, ui=self.c_add_player})
  --self:setupUI()
  base_loadUI(self, _array)
end


return _M