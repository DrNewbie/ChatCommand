if Announcer then
	Announcer:AddHostMod('Chat Command, (Say [!help] for more info about this lobby)')
end

if ModCore then
	ModCore:new(ModPath .. "Config.xml", false, true):init_modules()
end