local Dialog = require "engine.ui.Dialog"

local _M = loadPrevious(...)
local base_init = _M.init

function _M:init(title, actor, order, at_end, quickbirth, w, h)
  -- Do stuff "before" loading the original file

  -- make new num_players dialog?
  Dialog:yesnoPopup("Did it work?", "Superload attempted.", true, "No", "Yes I'm sure")
  
  -- execute the original function
  local retval = base_init(self, title, actor, order, at_end, quickbirth, w, h)

  -- Do stuff "after" loading the original file
  --c_add_player = Button.new{text="Add Player", fct=function() self:atEnd("created") end}
  -- return whatever the original function would have returned
  return retval
end

return _M