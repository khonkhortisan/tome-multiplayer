local Party = require "mod.class.Party"
local Player = require "mod.class.Player"
local GameState = require "mod.class.GameState"
local Birther = require "mod.dialogs.Birther"
local Calendar = require "engine.Calendar"
local Map = require "engine.Map"
local Dialog = require "engine.ui.Dialog"

local _M = loadPrevious(...)
-- [[
--This function both creates a world and adds a character.
--It cannot be superloaded while also being split.
--Overloading in order to split.
local base_newGame = _M.newGame
function _M:newGame()
--init
	self.party = Party.new{}
--init
	-- Create the entity to store various game state things
	self.state = GameState.new{}
	
--perplayer
	local player = Player.new{name=self.player_name, game_ender=true}
	self.party:addMember(player, {
		control="full",
		type="player",
		title="Main character",
		main=true,
		orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
	})
	self.party:setPlayer(player)
	
	
--idk, uses online
	local birth_done = function()
--postplayer
		if self.state.birth.__allow_rod_recall then self.state:allowRodRecall(true) self.state.birth.__allow_rod_recall = nil end
		if self.state.birth.__allow_transmo_chest and profile.mod.allow_build.birth_transmo_chest then
			self.state.birth.__allow_transmo_chest = nil
			local chest = self.zone:makeEntityByName(self.level, "object", "TRANSMO_CHEST")
			if chest then
				self.zone:addEntity(self.level, chest, "object")
				self.player:addObject(self.player:getInven("INVEN"), chest)
			end
		end
--createworld
		for i = 1, 50 do
			local o = self.state:generateRandart{add_pool=true}
			self.zone.object_list[#self.zone.object_list+1] = o
		end
--perplayer
		if config.settings.cheat then self.player.__cheated = true end

		self.player:recomputeGlobalSpeed()
		self:rebuildCalendar()

		-- Force the hotkeys to be sorted.
		self.player:sortHotkeys()
--perplayer?
		-- Register the character online if possible
		self.player:getUUID()
		self:updateCurrentChar()
	end
	
	
--init
	if not config.settings.tome.tactical_mode_set then
		self.always_target = true
	else
		self.always_target = config.settings.tome.tactical_mode
	end
	local nb_unlocks, max_unlocks, categories = self:countBirthUnlocks()
	local unlocks_order = { class=1, race=2, cometic=3, other=4 }
	local unlocks = {}
	for cat, d in pairs(categories) do unlocks[#unlocks+1] = {desc=d.nb.."/"..d.max.." "..cat, order=unlocks_order[cat] or 99} end
	table.sort(unlocks, "order")
	self.creating_player = true
	self.extra_birth_option_defs = {}
	self:triggerHook{"ToME:extraBirthOptions", options = self.extra_birth_option_defs}
--perplayer
	local birth; birth = Birther.new("Character Creation ("..table.concat(table.extract_field(unlocks, "desc", ipairs), ", ").." unlocked options)", self.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass" }, function(loaded)
--perplayer
		if not loaded then
			self.calendar = Calendar.new("/data/calendar_"..(self.player.calendar or "allied")..".lua", "Today is the %s %s of the %s year of the Age of Ascendancy of Maj'Eyal.\nThe time is %02d:%02d.", 122, 167, 11)
			self.player:check("make_tile")
			self.player.make_tile = nil
			self.player:check("before_starting_zone")
			self.player:check("class_start_check")

			-- Save current state of extra birth options.
			self.player.extra_birth_options = {}
			for _, option in ipairs(self.extra_birth_option_defs) do
				if option.id then
					self.player.extra_birth_options[option.id] = config.settings.tome[option.id]
				end
			end
--once.? Place subsequent players by party mechanic
			-- Configure & create the worldmap
			self.player.last_wilderness = self.player.default_wilderness[3] or "wilderness"
			game:onLevelLoad(self.player.last_wilderness.."-1", function(zone, level)
				game.player.wild_x, game.player.wild_y = game.player.default_wilderness[1], game.player.default_wilderness[2]
				if type(game.player.wild_x) == "string" and type(game.player.wild_y) == "string" then
					local spot = level:pickSpot{type=game.player.wild_x, subtype=game.player.wild_y} or {x=1,y=1}
					game.player.wild_x, game.player.wild_y = spot.x, spot.y
				end
			end)

			-- Generate
			if self.player.__game_difficulty then self:setupDifficulty(self.player.__game_difficulty) end
			self:setupPermadeath(self.player)
			--self:changeLevel(1, "test")
			self:changeLevel(self.player.starting_level or 1, self.player.starting_zone, {force_down=self.player.starting_level_force_down, direct_switch=true})

			print("[PLAYER BIRTH] resolve...")
			self.player:resolve()
			self.player:resolve(nil, true)
			self.player.energy.value = self.energy_to_act
			Map:setViewerFaction(self.player.faction)
			self.player:updateModdableTile()

			self.paused = true
			print("[PLAYER BIRTH] resolved!")
			local birthend = function()
--perplayer message
				local d = require("engine.dialogs.ShowText").new("Welcome to #LIGHT_BLUE#Tales of Maj'Eyal", "intro-"..self.player.starting_intro, {name=self.player.name}, nil, nil, function()
					self.player:resetToFull()
					self.player:registerCharacterPlayed()
					self.player:onBirth(birth)
					-- For quickbirth
					savefile_pipe:push(self.player.name, "entity", self.party, "engine.CharacterVaultSave")

					self.player:grantQuest(self.player.starting_quest)
					self.creating_player = false

					birth_done()
					self.player:check("on_birth_done")
					self:setTacticalMode(self.always_target)
					self:triggerHook{"ToME:birthDone"}

					if __module_extra_info.birth_done_script then loadstring(__module_extra_info.birth_done_script)() end
				end, true)
				self:registerDialog(d)
				if __module_extra_info.no_birth_popup then d.key:triggerVirtual("EXIT") end
				
				
				
				if self.player.title == "Multiplayer" then
					Dialog:yesnoPopup("Did it work?", "Return value found.", true, "No", "Yes I'm sure")
				end
--perplayer
				local player = Player.new{name=self.player_name, game_ender=true}
				self.party:addMember(player, {
					control="full",
					type="player",
					title="Main character",
					main=true,
					orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
				})
				self.party:setPlayer(player)

				
				
			end

			if self.player.no_birth_levelup or __module_extra_info.no_birth_popup then birthend()
			else self.player:playerLevelup(birthend, true) end
--ignore premades, they force loading singleplayer :(
		-- Player was loaded from a premade
		else
			self.calendar = Calendar.new("/data/calendar_"..(self.player.calendar or "allied")..".lua", "Today is the %s %s of the %s year of the Age of Ascendancy of Maj'Eyal.\nThe time is %02d:%02d.", 122, 167, 11)
			Map:setViewerFaction(self.player.faction)
			if self.player.__game_difficulty then self:setupDifficulty(self.player.__game_difficulty) end
			self:setupPermadeath(self.player)

			-- Configure & create the worldmap
			self.player.last_wilderness = self.player.default_wilderness[3] or "wilderness"
			game:onLevelLoad(self.player.last_wilderness.."-1", function(zone, level)
				game.player.wild_x, game.player.wild_y = game.player.default_wilderness[1], game.player.default_wilderness[2]
				if type(game.player.wild_x) == "string" and type(game.player.wild_y) == "string" then
					local spot = level:pickSpot{type=game.player.wild_x, subtype=game.player.wild_y} or {x=1,y=1}
					game.player.wild_x, game.player.wild_y = spot.x, spot.y
				end
			end)

			-- Tell the level gen code to add all the party
			self.to_re_add_actors = {}
			for act, _ in pairs(self.party.members) do if self.player ~= act then self.to_re_add_actors[act] = true end end

			self:changeLevel(self.player.starting_level or 1, self.player.starting_zone, {force_down=self.player.starting_level_force_down, direct_switch=true})
			self.player:grantQuest(self.player.starting_quest)
			self.creating_player = false

			-- Add all items so they regen correctly
			self.player:inventoryApplyAll(function(inven, item, o) game:addEntity(o) end)

			birth_done()
			self.player:check("on_birth_done")
			self:setTacticalMode(self.always_target)
			self:triggerHook{"ToME:birthDone"}
		end
	end, quickbirth, 800, 600)
	--end birth function
	
--perplayer character creation dialog
	self:registerDialog(birth)
end

--]]
return _M