if Network:is_client() then
	return
end

_G.ChatCommand = _G.ChatCommand or {}

ChatCommand.Default_Health = ChatCommand.Default_Health or {}

ChatCommand.Enemy_Health_Bonus = 1

local _f_CopDamage_init = CopDamage.init

function CopDamage:init(unit)
	local _tweak_table = unit:base()._tweak_table
	local _char_tweak = tweak_data.character[_tweak_table]
	if not ChatCommand.Default_Health[_tweak_table] then
		ChatCommand.Default_Health[_tweak_table] = _char_tweak.HEALTH_INIT
	end
	tweak_data.character[_tweak_table].HEALTH_INIT = math.max(math.floor(ChatCommand.Default_Health[_tweak_table]*ChatCommand.Enemy_Health_Bonus), 10)
	_f_CopDamage_init(self, unit)
end