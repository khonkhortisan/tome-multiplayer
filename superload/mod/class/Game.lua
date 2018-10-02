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
	
	--perplayer, player1's instance here
	local player = Player.new{name=self.player_name, game_ender=true}
	self.party:addMember(player, {
		control="full",
		type="player",
		title="Main character",
		main=true,
		orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
	})
	self.party:setPlayer(player)
	config.settings.multiplayer_num = 1
	--0 player 1 of 1, singleplayer
	--1 player 1 of >1, multiplayer
	--2 player 2 of >2, multiplayer
	-- -1 or 9999? player last of >1, multiplayer
	
	--init
	-- Create the entity to store various game state things
	self.state = GameState.new{}
	
	--idk, uses online
	local birth_done = function()
		 --loading a game save calls this function!
		--postplayer
		if self.state.birth.__allow_rod_recall then self.state:allowRodRecall(true) self.state.birth.__allow_rod_recall = nil end
		if self.state.birth.__allow_transmo_chest and profile.mod.allow_build.birth_transmo_chest then
			self.state.birth.__allow_transmo_chest = nil
			local chest = self.zone:makeEntityByName(self.level, "object", "TRANSMO_CHEST")
			if chest then
				self.zone:addEntity(self.level, chest, "object")
				self.player:addObject(self.player:getInven("INVEN"), chest)
			end
		--[[
		--duplicate (reference to?) chest and orb for other players
		if (not loaded) and config.settings.multiplayer_num > 1 then
			--if not newp:findInInventory(newp:getInven("INVEN"), "Transmogrification Chest") then
				--local chest, chest_item = oldp:findInInventory(oldp:getInven("INVEN"), "Transmogrification Chest")
				--local chest = self.object_list["TRANSMO_CHEST"]
				local chest = self.zone:getEntities(self.level, "object")["TRANSMO_CHEST"]
				if chest then self.player:addObject(self.player:getInven("INVEN"), chest) end
			--end
			--when is scrying given?
			--if not newp:findInInventory(newp:getInven("INVEN"), "Scrying Orb") then
				--local orb, orb_item = oldp:findInInventory(oldp:getInven("INVEN"), "Scrying Orb")
				--local orb = self.object_list["ORB_SCRYING"]
				local orb = self.zone:getEntities(self.level, "object")["ORB_SCRYING"]
				if orb then self.player:addObject(self.player:getInven("INVEN"), orb) end
			--end
		end
		--]]
		end
		
		--createworld, once", fine if duplicate?
		if loaded or config.settings.multiplayer_num <= 1 then
			for i = 1, 50 do
				local o = self.state:generateRandart{add_pool=true}
				self.zone.object_list[#self.zone.object_list+1] = o
			end
		end
		--perplayer
		if config.settings.cheat then self.player.__cheated = true end

		self.player:recomputeGlobalSpeed()
		if loaded or config.settings.multiplayer_num <= 1 then
			self:rebuildCalendar()
		end

		-- Force the hotkeys to be sorted
		self.player:sortHotkeys()
		
		--perplayer?
		-- Register the character online if possible
		self.player:getUUID()
		self:updateCurrentChar()
	end --birth_done
	
	
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
	birtherfunction = function(loaded)
	--if config.settings.multiplayer_num == 2 then return end
	--perplayer
		if not loaded then
			--once
			if config.settings.multiplayer_num <= 1 then
				self.calendar = Calendar.new("/data/calendar_"..(self.player.calendar or "allied")..".lua", "Today is the %s %s of the %s year of the Age of Ascendancy of Maj'Eyal.\nThe time is %02d:%02d.", 122, 167, 11)
			end
			--perplayer
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
			if config.settings.multiplayer_num <= 1 then
				-- Configure & create the worldmap
				self.player.last_wilderness = self.player.default_wilderness[3] or "wilderness"
				game:onLevelLoad(self.player.last_wilderness.."-1", function(zone, level)
					game.player.wild_x, game.player.wild_y = game.player.default_wilderness[1], game.player.default_wilderness[2]
					if type(game.player.wild_x) == "string" and type(game.player.wild_y) == "string" then
						local spot = level:pickSpot{type=game.player.wild_x, subtype=game.player.wild_y} or {x=1,y=1}
						game.player.wild_x, game.player.wild_y = spot.x, spot.y
					end
				end)
			end
			--perplayer
			-- Generate
			if self.player.__game_difficulty then self:setupDifficulty(self.player.__game_difficulty) end
			self:setupPermadeath(self.player)
			--once
			--this is not the code that moves to starting zone?
			if config.settings.multiplayer_num <= 1 then
				--self:changeLevel(1, "test")
				self:changeLevel(self.player.starting_level or 1, self.player.starting_zone, {force_down=self.player.starting_level_force_down, direct_switch=true})
			end
			--perplayer
			print("[PLAYER BIRTH] resolve...")
			self.player:resolve()
			self.player:resolve(nil, true)
			self.player.energy.value = self.energy_to_act
			--once
			if config.settings.multiplayer_num <= 1 then
				Map:setViewerFaction(self.player.faction)
			else --doesn't need to be inside an else but doesn't have an effect on player1. I put faction stuff together.
				--play on same team to avoid autotargetting/minion attacks
				self.player.faction = game.party:findMember{main=true}.faction
			end
			--perplayer
			self.player:updateModdableTile()

			self.paused = true
			print("[PLAYER BIRTH] resolved!")
			local birthend = function()
				--perplayer message
				local replacement_name = self.player.name
				if (not loaded) and config.settings.multiplayer_num > 1 then
					--engine/dialogs/ShowText.lua:generateList
					local reGenerateList = function(file, replace)
						local f, err = loadfile("/data/texts/"..file..".lua")
						if not f and err then error(err) end
						local env = setmetatable({}, {__index=_G})
						setfenv(f, env)
						local str = f()

						str = str:gsub("@([^@]+)@", function(what)
							if not replace[what] then return "" end
							return util.getval(replace[what])
						end)
						return str
						--self.text = str

						--if env.title then
						--	self.title = env.title
						--end

						--return true
					end
					replacement_name = [[#LAST##MOCCASIN#players#LAST#.

]]..
reGenerateList("intro-"..self.party:findMember{main=true}.starting_intro, {name=[[#LAST##MOCCASIN#]]..self.party:findMember{main=true}.name..[[#LAST#. #LIGHT_BLUE#This is the intro for everyone's starting quest#LAST#]]})
..[[

Welcome #LIGHT_GREEN#]]..self.player.name..[[#LAST#. #LIGHT_BLUE#This is the intro for you(r race)#LAST#]]
				end
				local d = require("engine.dialogs.ShowText").new("Welcome to #LIGHT_BLUE#Tales of Maj'Eyal", "intro-"..self.player.starting_intro, {name=replacement_name}, nil, nil, function()
					--runs after welcome dialog is closed?
					self.player:resetToFull()
					self.player:registerCharacterPlayed()
					self.player:onBirth(birth)
					-- For quickbirth
					savefile_pipe:push(self.player.name, "entity", self.party, "engine.CharacterVaultSave")
					--perplayer? Nope, throws error.
					if config.settings.multiplayer_num <= 1 then
						self.player:grantQuest(self.player.starting_quest)
					end
					--lastplayer?
					self.creating_player = false
					--perplayer
					birth_done()
					self.player:check("on_birth_done")
					self:setTacticalMode(self.always_target)
					self:triggerHook{"ToME:birthDone"}

					if __module_extra_info.birth_done_script then loadstring(__module_extra_info.birth_done_script)() end
					
					----------------------------------------------------------------------
					--firstplayer
					--if config.settings.multiplayer_num == 1 then
					if not loaded then --needed to not lock loading saves
						Dialog:yesnoPopup("Multiplayer", "Ready Player "..config.settings.multiplayer_num+1, function(ret)
							if not ret then
								config.settings.multiplayer_num = config.settings.multiplayer_num + 1
								--if not player.title == "Multiplayer" then
								--if true then
								--start over for player 2
								--if self.player.title == "Multiplayer" then
								--	Dialog:yesnoPopup("Did it work?", "Return value found.", true, "No", "Yes I'm sure")
								--end
								--perplayer

								--[[
								--local x, y = util.findFreeGrid(game.player.x, game.player.y, 20, true, {[engine.Map.ACTOR]=true})
								local norgan = self.zone:makeEntityByName(self.level, "actor", "NORGAN")
								self.zone:addEntity(self.level, norgan, "actor", x, y)

								self.party:addMember(norgan, {
									ai="player_party_member", type="squadmate", title="Norgan", no_party_ai=true,
									})
									--]]
								--[
								--self.player.ai = "player_party_member"
								--self.player.no_party_ai = true
								--local player1 = self.player
								local x, y = util.findFreeGrid(self.player.x, self.player.y, 20, true, {[engine.Map.ACTOR]=true})
								
								local player2 = Player.new{name=self.player_name..config.settings.multiplayer_num, game_ender=true}
								
								--actually spawn player2 (Norgan-style!) - required for setPlayer
								self.zone:addEntity(self.level, player2, "actor", x, y)
								
								self.party:addMember(player2, {
									control="full",
									type="player",
									--ai="player_party_member",
									--title="Secondary main character",
									title="Main character", --currently using this for ai switching
									--main=true, --inferior to player1? needed for item pickup? Has other side effedts? Must be unset to load a save?
									orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
									--no_party_ai=true,
								})
								
								
								
								--[[
								--need to spawn player2 by dropping on/near player1 like a summon so player switching can succeed
								player2.wild_x, player2.wild_y = game.player.default_wilderness[1], game.player.default_wilderness[2]
								if type(player2.wild_x) == "string" and type(player2.wild_y) == "string" then
									local spot = self.level:pickSpot{type=player2.wild_x, subtype=player2.wild_y} or {x=1,y=1}
									player2.wild_x, player2.wild_y = spot.x, spot.y
								end--]]
								
								--This can't be right. V2
								player2.energy.value = self.energy_to_act
								
								self.party:setPlayer(player2) --fails with message, does nothing
								
								--yes, control dead nonexistent character.
								--self.party:setPlayer(player2, true) --just blinks screen
								
								
								--Force switch to player 2, OR
								--clone player 1 as second entity, use birther on first entity...?
								--[[
								local player1clone = self.player
								local player1name = self.player.name
								self.player.name = self.player.name.."clone"
								self.party:addMember(player1clone, {
									control="full",
									type="player",
									--ai="player_party_member",
									title="Secondary main character",
									main=true,
									orders = {target=true, anchor=true, behavior=true, leash=true, talents=true},
									--no_party_ai=true,
								})--]]
								--well, that didn't work. Just flashed screen.
								
								birth = Birther.new("Character Creation ("..table.concat(table.extract_field(unlocks, "desc", ipairs), ", ").." unlocked options)", self.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass" }, birtherfunction, quickbirth, 800, 600)
								
								--perplayer character creation dialog (player 2+)
								self:registerDialog(birth)
								--]]
							end --if not ret then
						end, "No", "Yes") --really add player dialog
					end -- if not loaded then
					----------------------------------------------------------------------

				end, true) --d (welcome dialog)
				self:registerDialog(d)
				if __module_extra_info.no_birth_popup then d.key:triggerVirtual("EXIT") end
								
			end --birthend

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

			birth_done() --loading a game save calls this function!
			self.player:check("on_birth_done")
			self:setTacticalMode(self.always_target)
			self:triggerHook{"ToME:birthDone"}
		end
	end --birtherfunction
	--local birth; 
	birth = Birther.new("Character Creation ("..table.concat(table.extract_field(unlocks, "desc", ipairs), ", ").." unlocked options)", self.player, {"base", "world", "difficulty", "permadeath", "race", "subrace", "sex", "class", "subclass" }, birtherfunction, quickbirth, 800, 600)
	--end birth function
	
--perplayer character creation dialog (player1)
	self:registerDialog(birth)
end

--AFFECTS SAVE/LOAD/BIRTH/NEWGAME!
local base_setPlayerName = _M.setPlayerName
--- Sets the player name
function _M:setPlayerName(name)
	name = name:removeColorCodes():gsub("#", " "):sub(1, 25)
	
	--Keep these as player1's name
	if (not config.settings.multiplayer_num) or config.settings.multiplayer_num <= 1 then
	self.save_name = name
	self.player_name = name
	end
	
	--there can be more than one
	if game.player then --remove superfluous error. This really shouldn't be called that early.
		game.player.name = name
		else
		--~~there can be only one~~
		if self.party and self.party:findMember{main=true} then
			self.party:findMember{main=true}.name = name
		end
	end
end


--]]
return _M