type Character = Model & {Head : BasePart, Humanoid : Humanoid, HumanoidRootPart : BasePart}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local __aimbot = {}
__aimbot.Settings = {
    __keyCode = "E",
	__aimPart = "HumanoidRootPart",
	__prediction = 2
}
__aimbot.Utilities = {
    lerp = function(a : number, b : number, t : number) : number
		return a + (b - a) * t
	end,
	sort = function<V>(currentTable : {[any] : V}, comparison : (valueA : V, valueB : V) -> boolean) : {[any] : V}
		local clonedTable = table.clone(currentTable)
		table.sort(clonedTable, comparison)
		return clonedTable
	end,
	keep = function(currentTable : {[any] : any}, amount : number) : {[any] : any}
		local clonedTable = table.clone(currentTable)
		for index = amount + 1, table.maxn(clonedTable) do
			table.remove(clonedTable, amount + 1)
		end
		return clonedTable
	end,
	forEach = function<I, V>(currentTable : {[I] : V}, handler : (index : I, value : V) -> ())
		for index, value in currentTable do
			if handler then
				handler(index, value)
			end
		end
	end,
}
__aimbot.CharacterUtilities = {
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
		if not __aimbot.CharacterUtilities.isAlive(instance) then
			return false
		end
        if not instance:FindFirstChild("Animate") then
            return false
        end
        if __aimbot.CharacterUtilities.isPlayer(instance) then
            return false
        end
		return true
	end
}
__aimbot.OnLoop = nil

function __aimbot:GetSetting(settingName : string) : any?
    return __aimbot.Settings[settingName] and __aimbot.Settings[settingName] or nil
end

function __aimbot:GetPrediction(target : Character) : Vector3
    return target:FindFirstChildOfClass("Humanoid").MoveDirection ~= Vector3.zero and target[__aimbot.Settings.__aimPart].AssemblyLinearVelocity.Unit * __aimbot.Settings.__prediction or Vector3.zero
end

function __aimbot:SetSetting(settingName : string, settingValue : any)
    if not __aimbot.Settings[settingName] then
        return
    end
    __aimbot.Settings[settingName] = settingValue
end

function __aimbot:LockCameraTo(position : Vector3)
	for index = 0, 1, 0.1 do
        workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, __aimbot.Utilities.lerp(workspace.CurrentCamera.CFrame.Position, position, index))
        RunService.Heartbeat:Wait()
    end
end

function __aimbot:ScanEnvironment(target : Character) : (boolean, Vector2, number)
	local partsObscuringTargetHead = workspace.CurrentCamera:GetPartsObscuringTarget({target.Head.Position}, {localPlayer.Character, target})
	local partsObscuringTargetHumanoidRootPart = workspace.CurrentCamera:GetPartsObscuringTarget({target.HumanoidRootPart.Position}, {localPlayer.Character, target})
	local viewportPoint, inViewport = workspace.CurrentCamera:WorldToViewportPoint(target.HumanoidRootPart.Position)
	if inViewport then
		if table.maxn(partsObscuringTargetHead) == 0 then
			return true, Vector2.new(viewportPoint.X, viewportPoint.Y), viewportPoint.Z
		elseif table.maxn(partsObscuringTargetHumanoidRootPart) == 0 then
			return true, Vector2.new(viewportPoint.X, viewportPoint.Y), viewportPoint.Z
		end
	end
	return false, Vector2.zero, 0
end

function __aimbot:GetClosestTargetInFOV() : Character?
	local data = {}
	local mouseLocation = UserInputService:GetMouseLocation()
	__aimbot.Utilities.forEach(workspace:GetDescendants(), function(index : number, target : Instance)
        if __aimbot.CharacterUtilities.isCharacterValid(target) then
            local inViewport, viewportPoint, depth = __aimbot:ScanEnvironment(target)
            if inViewport then
                table.insert(data, {Target = target, ViewportPoint = viewportPoint, Depth = depth})
            end
        end
	end)
	local sortedDataViewport = __aimbot.Utilities.sort(data, function(dataA : {Target : Character, ViewportPoint : Vector2, Depth : number}, dataB : {Target : Character, ViewportPoint : Vector2, Depth : number})
		if not dataA.Target then
			return false
		end
		if not dataB.Target then
			return true
		end
		return (dataA.ViewportPoint - mouseLocation).Magnitude < (dataB.ViewportPoint - mouseLocation).Magnitude
	end)
	local closestTargetsViewport = __aimbot.Utilities.keep(sortedDataViewport, 2)
	local sortedDataDepth = __aimbot.Utilities.sort(closestTargetsViewport, function(dataA : {Target : Character, ViewportPoint : Vector2, Depth : number}, dataB : {Target : Character, ViewportPoint : Vector2, Depth : number})
		if not dataA.Target then
			return false
		end
		if not dataB.Target then
			return true
		end
		return dataA.Depth < dataB.Depth
	end)
	return sortedDataDepth[1] and sortedDataDepth[1].Target
end

RunService:BindToRenderStep("Aimbot", Enum.RenderPriority.Camera.Value + 1, function(deltaTime : number)
	if __aimbot.OnLoop then
		__aimbot.OnLoop(deltaTime)
	end
end)

__aimbot.OnLoop = function(deltaTime : number)
	local target = __aimbot:GetClosestTargetInFOV()
	if target and UserInputService:IsKeyDown(__aimbot.Settings.__keyCode) then
		__aimbot:LockCameraTo(target[__aimbot.Settings.__aimPart].Position + __aimbot:GetPrediction(target))
	end
end