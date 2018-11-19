-- This file helps with handing over autoexplore status on player control switch. See PlayerRun.lua, party.lua

local _M = loadPrevious(...)

  local base_restStop = _M.restStop
--local base_runStop = _M.runStop
-- [[
function _M:restStop(msg)
	if msg ~= "Switching control" then
		self.resting_continue=false
	end
	base_restStop(self, msg)
end
--[[
function _M:runStop(msg)
	if msg ~= "Switching control" then
		self.running_continue=false
	end
	base_runStop(self, msg)
end
--]]
return _M