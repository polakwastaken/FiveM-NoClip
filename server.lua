local CONFIG = {
	commandName = "noclip",
	allowedAcePermissions = {
		"noclip.use",
	},
}

local function hasNoclipPermission(playerId)
	for _, permission in ipairs(CONFIG.allowedAcePermissions) do
		if IsPlayerAceAllowed(playerId, permission) then
			return true
		end
	end

	return false
end

local function tryToggleNoclip(source)
	if source == 0 then
		print(("[%s] Console cannot toggle noclip directly."):format(CONFIG.commandName))
		return
	end

	if not hasNoclipPermission(source) then
		return
	end

	TriggerClientEvent("noclip:toggle", source)
end

RegisterCommand(CONFIG.commandName, function(source)
	tryToggleNoclip(source)
end, false)

RegisterNetEvent("noclip:requestToggle", function()
	tryToggleNoclip(source)
end)
