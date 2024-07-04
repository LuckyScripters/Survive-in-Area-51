type Character = Model & {Head : BasePart, Humanoid : Humanoid, HumanoidRootPart : BasePart}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local __esp = {}
__esp.Settings = {
	__showName = true,
	__showHealth = true,
	__showDistance = true,
	__enemyColor = Color3.fromRGB(255, 0, 0),
	__playerColor = Color3.fromRGB(255, 255, 255),
}
__esp.Utilities = {
	forEach = function<I, V>(currentTable : {[I] : V}, handler : (index : I, value : V) -> ())
		for index, value in currentTable do
			if handler then
				handler(index, value)
			end
		end
	end
}
__esp.CharacterUtilities = {
	isAlive = function(instance : Character) : boolean
		return (instance:FindFirstChildOfClass("Humanoid").Health > 0)
	end,
	isPlayer = function(instance : Character) : boolean
		return Players:GetPlayerFromCharacter(instance) ~= nil
	end,
	isCharacterValid = function(instance : Character) : boolean
		if typeof(instance) ~= "Instance" then
			return false
		end
		if not instance:IsA("Model") then
			return false
		end
		if not instance:FindFirstChild("Head") or not instance:FindFirstChildOfClass("Humanoid") or not instance:FindFirstChild("HumanoidRootPart") then
			return false
		end
		if not __esp.CharacterUtilities.isAlive(instance) then
			return false
		end
		if not instance:FindFirstChild("Animate") then
			return false
		end
		if __esp.CharacterUtilities.isPlayer(instance) then
			return false
		end
		return true
	end
}
__esp.OnLoop = nil
__esp.Storage = {}

function __esp:GetSetting(settingName : string) : any?
	return __esp.Settings[settingName] and __esp.Settings[settingName] or nil
end

function __esp:SetSetting(settingName : string, settingValue : any)
	if not __esp.Settings[settingName] then
		return
	end
	__esp.Settings[settingName] = settingValue
end