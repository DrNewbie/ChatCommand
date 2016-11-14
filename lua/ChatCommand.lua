if Network:is_client() then
	return
end

_G.ChatCommand = _G.ChatCommand or {}
ChatCommand.now_version = "[2016.11.15]"
ChatCommand.rtd_time = {0, 0, 0, 0}
ChatCommand.VIP_LIST = ChatCommand.VIP_LIST or {}
ChatCommand.VIP_LIST_IDX = ChatCommand.VIP_LIST_IDX or {}
ChatCommand.time2loopcheck = false

Hooks:PostHook(ChatManager, "init", "ChatCommand_Init", function(cmm, ...)
	cmm:AddCommand({"jail", "kill"}, false, false, function(peer)
		if not managers.trade:is_peer_in_custody(peer:id()) then
			if peer:id() == 1 then
				--Copy from Cheat
				local player = managers.player:local_player()
				managers.player:force_drop_carry()
				managers.statistics:downed( { death = true } )
				IngameFatalState.on_local_player_dead()
				game_state_machine:change_state_by_name( "ingame_waiting_for_respawn" )
				player:character_damage():set_invulnerable( true )
				player:character_damage():set_health( 0 )
				player:base():_unregister()
				player:base():set_slot( player, 0 )
			else
				--Copy from Cheat
				local _unit = peer:unit()
				_unit:network():send("sync_player_movement_state", "incapacitated", 0, _unit:id() )
				_unit:network():send_to_unit( { "spawn_dropin_penalty", true, nil, 0, nil, nil } )
				managers.groupai:state():on_player_criminal_death( _unit:network():peer():id() )
			end
		end
	end)
	cmm:AddCommand("add", true, false, function(peer, type1, type2, type3)
		if not managers.network then
			_send_msg("Error: !add")
		else
			local now_peer = { managers.network:session():peer(1) or nil,
				managers.network:session():peer(2) or nil,
				managers.network:session():peer(3) or nil,
				managers.network:session():peer(4) or nil }
			if (type2 ~= "1" and type2 ~= "2" and type2 ~= "3" and type2 ~= "4") or type3 ~= "ok" then
				cmm:say("You need to use [!add <id 1-4> ok] for adding new VIP.")
				if now_peer[1] then
					cmm:say("1: " .. now_peer[1]:name())
				end
				if now_peer[2] then
					cmm:say("2: " .. now_peer[2]:name())
				end
				if now_peer[3] then
					cmm:say("3: " .. now_peer[3]:name())
				end
				if now_peer[4] then
					cmm:say("4: " .. now_peer[4]:name())
				end
			else
				local file, err = io.open("mods/ChatCommand/vip_list.txt", "a")
				if file then
					local idx = tonumber(type2)
					if now_peer[idx] then
						file:write("" .. now_peer[idx]:user_id(), "\n")
						cmm:say("Host change [" .. now_peer[idx]:name() .."] to VIP")
					end
					file:close()
					Read_VIP_List()
				else
					cmm:say("Try again")
				end
			end
		end
	end)
	cmm:AddCommand({"donate", "d"}, false, false, function()
		local file, err = io.open("mods/ChatCommand/donate_msg.txt", "r")
		if file then
			local line = file:read()
			while line do
				cmm:say(tostring(line))
				line = file:read()
			end
		end
		file:close()
	end)
	cmm:AddCommand("loud", true, false, function()
		if managers.groupai and managers.groupai:state() and managers.groupai:state():whisper_mode() then
			managers.groupai:state():on_police_called("alarm_pager_hang_up")
			managers.hud:show_hint( { text = "LOUD!" } )
		end	
	end)
	cmm:AddCommand({"dozer", "taser", "tas" ,"cloaker", "clo", "sniper", "shield", "medic"}, true, true, function(peer, type1, type2, type3)
		if peer and peer:unit() then
			local unit = peer:unit()
			local unit_name = Idstring( "units/payday2/characters/ene_bulldozer_1/ene_bulldozer_1" )
			local count = 1
			if type1 == "!taser" or type1 == "!tas" or type1 == "/taser" or type1 == "/tas" then
				unit_name = Idstring( "units/payday2/characters/ene_tazer_1/ene_tazer_1" )
			end
			if type1 == "!cloaker" or type1 == "!clo" or type1 == "/cloaker" or type1 == "/clo" then
				unit_name = Idstring( "units/payday2/characters/ene_spook_1/ene_spook_1" )
			end
			if type3 and (type1 == "!dozer" or type1 == "/dozer") and tonumber(type3) <= 3 then
				unit_name = Idstring( "units/payday2/characters/ene_bulldozer_" .. type3 .. "/ene_bulldozer_" .. type3 )
			end
			if type1 == "!sniper" or type1 == "/sniper" then
				if tonumber(type3) == 1 or tonumber(type3) == 2 then
					unit_name = Idstring( "units/payday2/characters/ene_sniper_" .. type3 .. "/ene_sniper_" .. type3 )
				else
					unit_name = Idstring( "units/payday2/characters/ene_sniper_2/ene_sniper_2" )
				end
			end
			if type1 == "!shield" or type1 == "/shield" then
				if tonumber(type3) == 1 or tonumber(type3) == 2 then
					unit_name = Idstring( "units/payday2/characters/ene_shield_" .. type3 .. "/ene_shield_" .. type3 )
				else
					unit_name = Idstring( "units/payday2/characters/ene_shield_2/ene_shield_2" )
				end
			end
			if type1 == "!medic" or type1 == "/medic" then
				if tonumber(type3) == 2 then
					unit_name = Idstring("units/payday2/characters/ene_medic_m4/ene_medic_m4")
				else
					unit_name = Idstring("units/payday2/characters/ene_medic_r870/ene_medic_r870")
				end
			end
			if type2 then
				count = tonumber(type2)
			end
			for i = 1, count do
				local unit_done = World:spawn_unit( unit_name, unit:position(), unit:rotation() )
				ChatCommand:set_team( unit_done, unit_done:base():char_tweak().access == "gangster" and "gangster" or "combatant" )
			end
		end
	end)
	cmm:AddCommand({"restart", "res"}, true, false, function()
		--Copy from Quick/Instant restart 1.0 by: FishTaco
		local all_synced = true
		for k,v in pairs(managers.network:session():peers()) do
			if not v:synched() then
				all_synced = false
			end
		end
		if all_synced then
			managers.game_play_central:restart_the_game()
		end	
	end)
	cmm:AddCommand({"vipmenu"}, true, false, function()
		ChatCommand:Menu_VIPMENU()
	end)
	cmm:AddCommand({"version", "ver"}, false, false, function()
		cmm:say("Current version is " .. ChatCommand.now_version)
		cmm:say("More Info: http://goo.gl/W25Izf")
		cmm:say("Donate Me: http://goo.gl/mlFXAD")
	end)	
	cmm:AddCommand("end", true, false, function()
		if game_state_machine:current_state_name() ~= "disconnected" then
			MenuCallbackHandler:load_start_menu_lobby()
		end	
	end)
	cmm:AddCommand("vip", false, false, function(peer)
		if ChatCommand:is_VIP(peer) then
			cmm:say("[".. peer:name() .."] is VIP")
		elseif peer:id() == 1 then
			cmm:say("[".. peer:name() .."] is Host")
		else
			cmm:say("[".. peer:name() .."] is Normal player")
		end
	end)
	cmm:AddCommand("rtd", false, false, function(peer)
		if not peer or not peer:unit() then
			peer = managers.network:session():local_peer()
		end
		if peer and peer:unit() then
			local unit = peer:unit()
			local nowtime = math.floor(TimerManager:game():time())
			local pid = peer:id()
			local pname = peer:name()
			local pos = unit:position()
			local rot = unit:rotation()
			if ChatCommand.rtd_time[pid] < nowtime then
				ChatCommand.rtd_time[pid] = nowtime + 60
				local _roll = math.random(1, 14)
				if _roll == 1 then
					cmm:say("[".. pname .."] roll for Doctor Bag!!")
					DoctorBagBase.spawn( pos, rot, 0 )
				elseif _roll == 2 then
					cmm:say("[".. pname .."] roll for Ammo Bag!!")
					AmmoBagBase.spawn( pos, rot, 0 )
				elseif _roll >= 3 and _roll <= 5 then
					cmm:say("[".. pname .."] roll for Grenade Crate!!")
					GrenadeCrateBase.spawn( pos, rot, 0 )
				elseif _roll >= 6 and _roll <= 8 then
					cmm:say("[".. pname .."] roll for First Aid Kit!!")
					FirstAidKitBase.spawn( pos, rot, 0 , 0 )
				elseif _roll == 9 then
					cmm:say("[".. pname .."] roll for 10 Cloaker!!")
					local unit_name = Idstring( "units/payday2/characters/ene_spook_1/ene_spook_1" )
					for i = 1, 10 do
						local unit_done = World:spawn_unit( unit_name, unit:position(), unit:rotation() )
						ChatCommand:set_team( unit_done, unit_done:base():char_tweak().access == "gangster" and "gangster" or "combatant" )
					end
				elseif _roll == 10 then
					cmm:say("[".. pname .."] roll for Grenade Out!!")
					local projectile_index = tweak_data.blackmarket:get_index_from_projectile_id("frag")
					local _xy_fixed = {-10, 10, -100, 100, -200, 200, -500, 500}
					for i = 1, 10 do
						ProjectileBase.throw_projectile(projectile_index, pos + Vector3(_xy_fixed[math.random(8)], _xy_fixed[math.random(8)], 50), Vector3(0, 0, -1), 1)
					end
				elseif _roll == 11 then
					cmm:say("[".. pname .."] roll for Bomb this Area!!")
					local projectile_index = tweak_data.blackmarket:get_index_from_projectile_id("frag")
					local _start_pos = pos + Vector3(-2000, -2000, 0)
					local _d = tweak_data.blackmarket.projectiles.frag.time_cheat or 0.05
					ChatCommand.time2loopcheck = true
					ChatCommand.throw_projectile = {}
					for i = 1, 10 do
						for j = 1, 10 do
							local _table_size = table.size(ChatCommand.throw_projectile) + 1
							table.insert(ChatCommand.throw_projectile, {enable = true, projectile_index = projectile_index, pos = _start_pos + Vector3(i*400, j*400, 50), time_do = nowtime + 3 + _d*_table_size})
						end
					end
				else
					cmm:say("[".. pname .."] roll for nothing!!")
				end
				math.randomseed( os.time() )
			else
				cmm:say("[".. pname .."] you still need to wait [".. (ChatCommand.rtd_time[pid] - nowtime) .."]s for next roll.")				
			end
		end
	end)	
	cmm:AddCommand("help", false, false, function()
		cmm:say("[!rtd: Roll something special]")
		cmm:say("[!jail: Send yourself to jail]")
		cmm:say("[!vip: Let you know your level]")
		cmm:say("[!version: Tell something about this MOD]")
	end)
end)
function ChatManager:say(_msg, _msg2)
	if _msg then
		managers.chat:send_message(ChatManager.GAME, "", tostring(_msg))
	end
	if _msg2 then
		managers.chat:send_message(ChatManager.GAME, "", tostring(_msg))
	end
end

Hooks:PostHook(ChatManager, "receive_message_by_peer", "ChatCommand_Active", function(cmm, channel_id, peer, message)
	local is_run_by_Host = function ()
		if not Network then
			return false
		end
		return not Network:is_client()
	end
	local commad = string.lower(tostring(message))
	local _is_Host = peer:id() == 1 --HOST
	local _is_VIP = ChatCommand:is_VIP(peer) --VIP
	local _is_rHost = is_run_by_Host() --Is this only run by Host
	local type1, type2, type3 = unpack(commad:split(" "))
	if Utils:IsInHeist() and _is_rHost then
		if type1 and (type1:sub(1,1) == "!" or type1:sub(1,1) == "/") and cmm._commands and cmm._commands[string.lower(type1)] then
			if (cmm._commands[string.lower(type1)].ishost and _is_Host) or (cmm._commands[string.lower(type1)].isvip and _is_VIP) or (not cmm._commands[string.lower(type1)].ishost and not cmm._commands[string.lower(type1)].isvip) then
				cmm._commands[string.lower(type1)].func(peer, type1, type2, type3)
			else 
				cmm:say("You don't have premission to use this command")
			end
		elseif type1 and (type1:sub(1,1) == "!" or type1:sub(1,1) == "/") then
			cmm:say("The command: " .. type1 .. " doesn't exist")
		end
	end
end)

function ChatManager:AddCommand(cmd, ishost, isvip, func)
	if not self._commands then
		self._commands = {}
	end
	if type(cmd) == "string" then
		self._commands["!"..string.lower(cmd)] = {}
		self._commands["/"..string.lower(cmd)] = {}

		self._commands["!"..string.lower(cmd)].func = func
		self._commands["/"..string.lower(cmd)].func = func
		self._commands["!"..string.lower(cmd)].ishost = ishost
		self._commands["/"..string.lower(cmd)].ishost = ishost
		self._commands["!"..string.lower(cmd)].isvip = isvip
		self._commands["/"..string.lower(cmd)].isvip = isvip
	else
		for _, _cmd in pairs(cmd) do --Add multiple commands from table
			self._commands["!"..string.lower(_cmd)] = {}
			self._commands["/"..string.lower(_cmd)] = {}
			
			self._commands["!"..string.lower(_cmd)].func = func
			self._commands["/"..string.lower(_cmd)].func = func
			self._commands["!"..string.lower(_cmd)].ishost = ishost
			self._commands["/"..string.lower(_cmd)].ishost = ishost
			self._commands["!"..string.lower(_cmd)].isvip = isvip
			self._commands["/"..string.lower(_cmd)].isvip = isvip
		end
	end
end

function ChatCommand:is_VIP(peer)
	local line = tostring(peer:user_id())
	if ChatCommand.VIP_LIST[line] then
		return true
	else
		return false
	end
end

function ChatCommand:Read_VIP_List()
	local file, err = io.open("mods/ChatCommand/vip_list.txt", "r")
	ChatCommand.VIP_LIST = {}
	ChatCommand.VIP_LIST_IDX = {}
	if file then
		local line = file:read()
		local count = 0
		while line do
			line = tostring(line)
			if not ChatCommand.VIP_LIST[line] then
				count = count + 1
				ChatCommand.VIP_LIST[line] = count
				table.insert(ChatCommand.VIP_LIST_IDX, line)
			end
			line = file:read()
		end
		file:close()
	end
end

ChatCommand:Read_VIP_List()

function ChatCommand:set_team( unit, team )
	local M_groupAI = managers.groupai
	local AIState = M_groupAI:state()	
	local team_id = tweak_data.levels:get_default_team_ID( team )
	unit:movement():set_team( AIState:team_data( team_id ) )
end

function ChatCommand:Menu_VIPMENU(params)
	local opts = {}
	local start = params and params.start or 0
	start = start >= 0 and start or 0
	for k, v in pairs(ChatCommand.VIP_LIST_IDX or {}) do
		if k > start then
			opts[#opts+1] = { text = "" .. v .. "", callback_func = callback(self, self, "Menu_VIPMENU_Selected", {id = tostring(v)}) }
		end
		if (#opts) >= 10 then
			start = k
			break
		end	
	end
	opts[#opts+1] = { text = "[Next]--------------", callback_func = callback(self, self, "Menu_VIPMENU", {start = start}) }
	opts[#opts+1] = { text = "[Back to Main]----", callback_func = callback(self, self, "Menu_VIPMENU", {}) }
	opts[#opts+1] = { text = "[Cancel]", is_cancel_button = true }
	local _dialog_data = {
		title = "VIP MENU ",
		text = "",
		button_list = opts,
		id = tostring(math.random(0,0xFFFFFFFF))
	}
	if managers.system_menu then
		managers.system_menu:show(_dialog_data)
	end
end

function ChatCommand:Menu_VIPMENU_Selected(params)
	local opts = {}
	opts[#opts+1] = { text = "View", callback_func = callback(self, self, "Menu_VIPMENU_Selected_View", {id = params.id}) }
	opts[#opts+1] = { text = "Remove", callback_func = callback(self, self, "Menu_VIPMENU_Selected_Remove", {id = params.id}) }
	opts[#opts+1] = { text = "[Cancel]", is_cancel_button = true }
	local _dialog_data = {
		title = "" .. params.id,
		text = "",
		button_list = opts,
		id = tostring(math.random(0,0xFFFFFFFF))
	}
	if managers.system_menu then
		managers.system_menu:show(_dialog_data)
	end
end

function ChatCommand:Menu_VIPMENU_Selected_View(params)
	Steam:overlay_activate("url", "http://steamcommunity.com/profiles/" .. params.id)
	ChatCommand:Menu_VIPMENU_Selected({id = params.id})
end

function ChatCommand:Menu_VIPMENU_Selected_Remove(params)
	local file, err = io.open("mods/ChatCommand/vip_list.txt", "w")
	if file then
		for k, v in pairs(ChatCommand.VIP_LIST_IDX or {}) do
			if tostring(v) ~= tostring(params.id) then
				file:write(tostring(v) .. "\n")			
			end
		end
		file:close()
	end
	Read_VIP_List()
	local _dialog_data = {
		title = "" .. params.id,
		text = "He is removed from VIP list.",
		button_list = {{ text = "OK", is_cancel_button = true }},
		id = tostring(math.random(0,0xFFFFFFFF))
	}
	if managers.system_menu then
		managers.system_menu:show(_dialog_data)
	end
end

Hooks:Add("GameSetupUpdate", "RTDGameSetupUpdate", function(t, dt)
	if ChatCommand.time2loopcheck then
		local nowtime = TimerManager:game():time()
		ChatCommand.throw_projectile = ChatCommand.throw_projectile or {}
		for id, data in pairs(ChatCommand.throw_projectile) do
			if data.enable and type(data.time_do) == "number" and nowtime > data.time_do then
				ChatCommand.throw_projectile[id].enable = false
				ProjectileBase.throw_projectile(data.projectile_index, data.pos, Vector3(0, 0, -1), 1)
				ChatCommand.throw_projectile[id] = {}
			end
		end
		if table.size(ChatCommand.throw_projectile) <= 0 then
			ChatCommand.time2loopcheck = false
		end
	end
end)