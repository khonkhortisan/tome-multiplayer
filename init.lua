-- This file declares the mod. See Game.lua for the first file to take effect.
-- Multiplayer Hack
-- tome-multiplayer/init.lua

long_name = "Multiplayer Hack"
short_name = "multiplayer"
for_module = "tome"
version = {1,5,10}
addon_version = {1,0,0}
weight = 100
author = {'Khonkhortisan'}
homepage = 'https://github.com/khonkhortisan'
description = [[Adds a second character
New game menu allowing different classes/races (after starting level)
~~placeholder~~ AI that on its turn gives control to the player and takes over the first character

Game Options→Tactical Overlay:Combined Big recommended.

Todo:
Game rebalance (optional):
	duplicates starting items (transmog, rod of recall)
	Duplicates item pickups
		let player2 pick up items?
	shared experience points
	quest management only on player1?
		duplicates quest rewards
	disallows dropping items?
transmog popup for both people
bring both back to life after eidolon - go there immediately on any player death?
don't interrupt autoexplore/run (let it stack)
fix player1 living player2 undead error]]
tags = {'multiplayer'}

overload = true
superload = true
data = false
hooks = false