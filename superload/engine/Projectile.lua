-- This file - Dang arrows hitting me!

require "engine.class"
local Entity = require "engine.Entity"
local Particles = require "engine.Particles"
local Map = require "engine.Map"

local _M = loadPrevious(...)

--- Called by the engine when the projectile can move
local base_act = _M.act
function _M:act()
game.log("Projectile|act")
	if self.dead then return false end
game.log("Projectile|act:alive")
	while self:enoughEnergy() and not self.dead do
game.log("Projectile|act:while enough energy")
		if self.project then
game.log("Projectile|act:project type")
			local x, y, act, stop = self.src:projectDoMove(self.project.def.typ, self.project.def.x, self.project.def.y, self.x, self.y, self.project.def.start_x, self.project.def.start_y)
			if x and y then self:move(x, y) end
			if self.src then self.src.__project_source = self end -- intermediate projector source
			if act then self.src:projectDoAct(self.project.def.typ, self.project.def.tg, self.project.def.damtype, self.project.def.dam, self.project.def.particles, self.x, self.y, self.tmp_proj) end
			if stop then
game.log("Projectile|act:stop")
				local block, hit, hit_radius = false, true, true
				if self.project.def.typ.block_path then
					block, hit, hit_radius = self.project.def.typ:block_path(self.x, self.y)
				end
				local radius_x, radius_y
				if hit_radius then
					radius_x, radius_y = self.x, self.y
				else
					radius_x, radius_y = self.old_x, self.old_y
				end
				self.src:projectDoStop(self.project.def.typ, self.project.def.tg, self.project.def.damtype, self.project.def.dam, self.project.def.particles, self.x, self.y, self.tmp_proj, radius_x, radius_y, self)
			end
			if self.src then self.src.__project_source = nil end -- intermediate projector source
		elseif self.homing then
game.log("Projectile|act:homing type")
			self:moveDirection(self.homing.target.x, self.homing.target.y)
			self.homing.count = self.homing.count - 1
			if self.src then self.src.__project_source = self end -- intermediate projector source
			if self.x == self.homing.target.x and self.y == self.homing.target.y then
				game.level:removeEntity(self, true)
				self.dead = true
				self.homing.on_hit(self, self.src, self.homing.target)
			elseif self.homing.count <= 0 then
				game.level:removeEntity(self, true)
				self.dead = true
			else
				self.homing.on_move(self, self.src)
			end
			if self.src then self.src.__project_source = nil end -- intermediate projector source
		end
	end
	return true
end

--- Something moved in the same spot as us, hit ?
local base_on_move = _M.on_move
function _M:on_move(x, y, target)
--STOP HITTING YOURSELF
--player shoots arrow, control is switched, they move in place for good measure, it's treated as a player moving onto a tile with an arrow in it, as if they just walked into the shot.
game.log("Projectile|on_move"..' x'..x..' y'..y..' target'..target.name)
	if self.dead then return false end
game.log("Projectile|on_move: alive")
	self.src.__project_source = self -- intermediate projector source
	if self.project and self.project.def.typ.line then 
game.log("Projectile|on_move: call projectDoAct")
	self.src:projectDoAct(self.project.def.typ, self.project.def.tg, self.project.def.damtype, self.project.def.dam, self.project.def.particles, self.x, self.y, self.tmp_proj) end
	if self.project and self.project.def.typ.stop_block then
game.log("Projectile|on_move: call projectDoStop")
		self.src:projectDoStop(self.project.def.typ, self.project.def.tg, self.project.def.damtype, self.project.def.dam, self.project.def.particles, self.x, self.y, self.tmp_proj, self.x, self.y, self)
	elseif self.homing then
game.log("Projectile|on_move: homing type, meh.")
		if (self.x == self.homing.target.x and self.y == self.homing.target.y) then
			game.level:removeEntity(self, true)
			self.dead = true
			self.homing.on_hit(self, self.src, self.homing.target)
		else
			self.homing.on_move(self, self.src)
		end
	end
	self.src.__project_source = nil
end