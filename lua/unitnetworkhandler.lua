--Announce when someone joins, credit to TdlQ.
Hooks:Add("NetworkManagerOnPeerAdded", "NetworkManagerOnPeerAdded_ModAnnounce", function(peer, peer_id)
	if Network:is_server() then
		DelayedCalls:Add("DelayedModAnnounces" .. tostring(peer_id), 2, function()
			local message = "Say(Press t) [!help] for more info about this lobby!!"
			local peer2 = managers.network:session() and managers.network:session():peer(peer_id)
			if peer2 then
				local level_index = tweak_data.levels:get_index_from_level_id("cane")
				local difficulty_index = tweak_data:difficulty_to_index(Global.game_settings.difficulty)
				peer2:send("send_chat_message", ChatManager.GAME, message)
				peer2:send("join_request_reply", 1, peer_id, "", level_index, difficulty_index)
			end
		end)
	end
end)