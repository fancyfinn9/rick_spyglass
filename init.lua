local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_tool("rick_spyglass:spyglass",{
	description = S("Rick Spyglass"),
	_doc_items_longdesc = S("A spyglass is an item that can be used for zooming in on specific locations."),
	inventory_image = "mcl_spyglass.png",
	stack_max = 1,
	_mcl_toollike_wield = true,
	touch_interaction = "short_dig_long_place",
})

minetest.register_craft({
	output = "rick_spyglass:spyglass",
    type = "shapeless",
	recipe = {
		"mcl_spyglass:spyglass",
		"mcl_jukebox:jukebox"
	}
})

mcl_fovapi.register_modifier({
	name = "spyglass",
	fov_factor = 8,
	time = 0.1,
	reset_time = 0,
	is_multiplier = false,
	exclusive = true,
})

local spyglass_scope = {}

local spyglass_rick = {}
local spyglass_rick_state = {}

function rotate_rick(player)
	core.after(0.07, function()
		if spyglass_rick[player] then
			player:hud_change(spyglass_rick[player], "text", "rick_spyglass_rick.png^[verticalframe:28:"..spyglass_rick_state[player])
			spyglass_rick_state[player] = spyglass_rick_state[player] + 1
			if spyglass_rick_state[player] > 28 then
				spyglass_rick_state[player] = 1
			end
			rotate_rick(player)
		end
	end)
end

local function add_scope(player)
	local wielditem = player:get_wielded_item()
	if wielditem:get_name() == "rick_spyglass:spyglass" then
		spyglass_scope[player] = player:hud_add({
			[mcl_vars.hud_type_field] = "image",
			position = {x = 0.5, y = 0.5},
			scale = {x = -100, y = -100},
			text = "mcl_spyglass_scope.png",
		})
		spyglass_rick[player] = player:hud_add({
			[mcl_vars.hud_type_field] = "image",
			position = {x = 0.5, y = 0.5},
			scale = {x = 1.5, y = 1.5},
			text = "rick_spyglass_rick.png^[verticalframe:28:1",
		})
		spyglass_rick_state[player] = 1
		rotate_rick(player)
		player:hud_set_flags({wielditem = false})
		if mcl_util.is_it_christmas() then
			local time = minetest.get_timeofday()
			if (time < 0.01 or time > 0.99) and player:get_look_vertical() < -1.335 then
				player:set_moon({texture = "mcl_moon_special.png"})
			end
		end
	end
end

local function remove_scope(player)
	if spyglass_scope[player] then
		player:hud_remove(spyglass_scope[player])
		player:hud_remove(spyglass_rick[player])
		spyglass_scope[player] = nil
		spyglass_rick[player] = nil
		spyglass_rick_state[player] = nil
		player:hud_set_flags({wielditem = true})
		mcl_fovapi.remove_modifier(player, "spyglass") -- use the api to remove the FOV effect.
		-- old code: player:set_fov(86.1)
	end
end

controls.register_on_press(function(player, key)
	if key ~= "RMB" and key ~= "zoom" then return end
	if spyglass_scope[player] == nil then
		add_scope(player)
	end
end)

controls.register_on_release(function(player, key, time)
	if key ~= "RMB" and key ~= "zoom" then return end
	local ctrl = player:get_player_control()
	if key == "RMB" and ctrl.zoom or key == "zoom" and ctrl.place then return end
	remove_scope(player)
end)

controls.register_on_hold(function(player, key, time)
	if key ~= "RMB" and key ~= "zoom" then return end
	local wielditem = player:get_wielded_item()
	if wielditem:get_name() == "rick_spyglass:spyglass" then
		mcl_fovapi.apply_modifier(player, "spyglass") -- apply the FOV effect.
		-- old code: player:set_fov(8, false, 0.1)
		if spyglass_scope[player] == nil then
			add_scope(player)
		end
	else
		remove_scope(player)
	end
end)

minetest.register_on_dieplayer(function(player)
	remove_scope(player)
end)

minetest.register_on_leaveplayer(function(player)
	spyglass_scope[player] = nil
	spyglass_rick[player] = nil
	spyglass_rick_state[player] = nil
end)
