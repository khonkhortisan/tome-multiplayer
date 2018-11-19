-- This file - Dang arrows hitting me!

require "engine.class"
local Map = require "engine.Map"
local Target = require "engine.Target"
local DamageType = require "engine.DamageType"

local _M = loadPrevious(...)

--- Project damage to a distance using a moving projectile
-- @param t a type table describing the attack, passed to engine.Target:getType() for interpretation
-- @param x target coords
-- @param y target coords
-- @param damtype a damage type ID from the DamageType class
-- @param dam damage to be done
-- @param particles particles effect configuration, or nil
local base_projectile = _M.projectile
function _M:projectile(t, x, y, damtype, dam, particles)
	if type(particles) ~= "function" and type(particles) ~= "table" then particles = nil end

	self:check("on_project_init", t, x, y, damtype, dam, particles)

	local mods = {}
	if game.level.map:checkAllEntities(x, y, "on_project_acquire", self, t, x, y, damtype, dam, particles, true, mods) then
		if mods.x then x = mods.x end
		if mods.y then y = mods.y end
	end

--	if type(dam) == "number" and dam < 0 then return end
	local typ = Target:getType(t)
	typ.source_actor = self
	typ.start_x = typ.start_x or typ.x or (typ.source_actor and typ.source_actor.x or self.x)
	typ.start_y = typ.start_y or typ.y or (typ.source_actor and typ.source_actor.y or self.y)
	if self.lineFOV then
		typ.line_function = self:lineFOV(x, y, nil, nil, typ.start_x, typ.start_y)
	else
		typ.line_function = core.fov.line(typ.start_x, typ.start_y, x, y)
	end
	local block_corner = typ.block_path and function(_, bx, by) local b, h, hr = typ:block_path(bx, by, true) ; return b and h and not hr end
		or function(_, bx, by) return false end

	typ.line_function:set_corner_block(block_corner)

	local proj = require(self.projectile_class):makeProject(self, t.display, {x=x, y=y, start_x=typ.start_x, start_y=typ.start_y, damtype=damtype, tg=t, typ=typ, dam=dam, particles=particles, _allow_upvalues = true,})
game.log("ActorProject|game.zone:addEntity"..' '..typ.start_x..' '..typ.start_y)
	game.zone:addEntity(game.level, proj, "projectile", typ.start_x, typ.start_y)
game.log("ActorProject|self:check(on_projectile_fired"..' '..x..' '..y)
	self:check("on_projectile_fired", proj, typ, x, y, damtype, dam, particles)
	return proj
end

--- Do move
-- @param typ a target type table
-- @param tgtx the target's x-coordinate
-- @param tgty the target's y-coordinate
-- @param x the projectile's x-coordinate
-- @param y the projectile's y-coordinate
-- @param srcx the sourcs's x-coordinate
-- @param srcy the source's y-coordinate
-- @return lx x-coordinate the projectile travels to next
-- @return ly y-coordinate the projectile travels to next
-- @return act should we call `projectDoAct`() (usually only for beam)
-- @return stop is this the last (blocking) tile?
local base_projectDoMove = _M.projectDoMove
function _M:projectDoMove(typ, tgtx, tgty, x, y, srcx, srcy)
game.log("ActorProject|projectDoMove"..' '..tgtx..' '..tgty..' '..x..' '..y..' '..srcx..' '..srcy)
	local lx, ly, blocked_corner_x, blocked_corner_y = typ.line_function:step()
	if blocked_corner_x and x == srcx and y == srcy then
		return blocked_corner_x, blocked_corner_y, false, true
	end

	if lx and ly then
		local block, hit, hit_radius = false, true, true
		if blocked_corner_x then
			block, hit, hit_radius = true, false, false
		elseif typ.block_path then
			block, hit, hit_radius = typ:block_path(lx, ly)
		end
		if block then
			if hit then
				return lx, ly, false, true
			-- If we don't hit the tile, pass back nils to stop on the current spot
			else
				return nil, nil, false, true
			end
		end

		-- End of the map
		if lx < 0 or lx >= game.level.map.w or ly < 0 or ly >= game.level.map.h then
			return nil, nil, false, true
		end

		-- Deal damage: beam
		if typ.line and (lx ~= tgtx or ly ~= tgty) then return lx, ly, true, false end
	end
	-- Ok if we are at the end
	if (not lx and not ly) then return lx, ly, false, true end
	return lx, ly, false, false
end

--- projectDoAct
local base_projectDoAct = _M.projectDoAct
function _M:projectDoAct(typ, tg, damtype, dam, particles, px, py, tmp)
game.log("ActorProject|projectDoAct:start"..' '..px..' '..py)
	-- Now project on each grid, one type
	-- Call the projected method of the target grid if possible
	if not game.level.map:checkAllEntities(px, py, "projected", self, typ, px, py, damtype, dam, particles) then
		-- Check self- and friendly-fire, and if the projection "misses"
		local act = game.level.map(px, py, engine.Map.ACTOR)
--game.log("projectDoAct:act="..' '..act.name..' '..self.name)
		if act and act == self and not ((type(typ.selffire) == "number" and rng.percent(typ.selffire)) or (type(typ.selffire) ~= "number" and typ.selffire)) then
game.log("ActorProject|projectDoAct:act == self"..' '..act.name..' '..self.name)
		elseif act and self.reactionToward and (self:reactionToward(act) >= 0) and not ((type(typ.friendlyfire) == "number" and rng.percent(typ.friendlyfire)) or (type(typ.friendlyfire) ~= "number" and typ.friendlyfire)) then
game.log("ActorProject|projectDoAct:reactionToward"..' '..act.name..' '..self.name)
		-- Otherwise hit
		else
game.log("ActorProject|projectDoAct:Otherwise hit"..' '..self.name)
			DamageType:projectingFor(self, {project_type=tg})
			if type(damtype) == "function" then if damtype(px, py, tg, self, tmp) then return true end
			else DamageType:get(damtype).projector(self, px, py, damtype, dam, tmp, nil, tg) end
			if particles and type(particles) == "table" then
				game.level.map:particleEmitter(px, py, 1, particles.type, particles.args)
			end
			DamageType:projectingFor(self, nil)
		end
	end
end