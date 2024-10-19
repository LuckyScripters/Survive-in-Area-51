type Character = Model & {Head : BasePart, Humanoid : Humanoid, HumanoidRootPart : BasePart}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

local __esp = {}
__esp.Enum = {
    Position = {
        ["Top"] = 1,
        ["Center"] = 2,
        ["Bottom"] = 3
    },
    HighlightMode = {
        ["Square"] = 1,
        ["Highlight"] = 2
    }
}
__esp.Settings = {
	__showName = true,
    __playersOnly = false,
	__showDistance = true,
    __customSettings = {}
}
__esp.Utilities = {
	forEach = function<I, V>(currentTable : {[I] : V}, handler : (index : I, value : V) -> ())
		for index, value in currentTable do
			if handler then
				handler(index, value)
			end
		end
	end,
    getRandomString = function(size : number) : string
	    local randomString = ""
	    for index = 1, size do
		    randomString = randomString .. string.char(math.random(32, 126))
	    end
	    return randomString
    end
}
__esp.CharacterUtilities = {
	isAlive = function(instance : Character) : boolean
		return instance:FindFirstChildOfClass("Humanoid").Health > 0
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
		if __esp.Settings.__playersOnly and not __esp.CharacterUtilities.isPlayer(instance) then
			return false
		end
		return true
	end
}
__esp.HighlightStorage = HighlightStorage or Instance.new("Folder", gethui())
__esp.HighlightStorage.Name = __esp.Utilities.getRandomString(15)

getgenv().HighlightStorage = __esp.HighlightStorage

function __esp:GetSetting(settingsName : string) : any?
	return __esp.Settings[settingsName] and __esp.Settings[settingsName] or nil
end

function __esp:GetCustomSetting(customSettingsName : string) : any?
	return __esp.Settings.__customSettings[customSettingsName] and __esp.Settings.__customSettings[customSettingsName] or nil
end

function __esp:SetSetting(settingsName : string, settingValue : any)
	if not __esp.Settings[settingsName] or not settingValue then
		return
	end
	__esp.Settings[settingsName] = settingValue
end

function __esp:SetCustomSetting(customSettingsName : string, customSettingValue : {Position : number, DrawLineColor : Color3, HighlightMode : number})
	if not __esp.Settings.__customSettings[customSettingsName] or not customSettingValue then
		return
	end
	__esp.Settings.__customSettings[customSettingsName] = customSettingValue
end

function __esp:GetBoundingBox(object : Model | BasePart) : (CFrame, Vector3)
    if object:IsA("Model") then
        return object:GetBoundingBox()
    end
    return object.CFrame, object.Size
end

function __esp:_Get2DPosition(position : Vector3) : (boolean, Vector2)
	local viewportPoint, inViewport = workspace.CurrentCamera:WorldToViewportPoint(position)
	return inViewport and true, Vector2.new(viewportPoint.X, viewportPoint.Y) or false, Vector2.zero
end

function __esp:_Get2DSize(upLeftPosition : Vector3, downRightPosition : Vector3) : Vector2
	local inViewport, upLeft2D = __esp:_Get2DPosition(upLeftPosition)
	local inViewport, downRight2D = __esp:_Get2DPosition(downRightPosition)
	return Vector2.new(downRight2D.X - upLeft2D.X, upLeft2D.Y - downRight2D.Y)
end

local function getRootPartCFrame() : CFrame?
    local character = localPlayer.Character
    if not character then
        return nil
    end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nil
    end
    return humanoidRootPart.CFrame
end

function __esp:AddObject(object : Model | BasePart, name : string, customSettingsName : string?, customSettings : {Position : number, DrawLineColor : Color3, HighlightMode : number}?) : {Destroy : () -> ()}
	local connection = nil
	local espContainer = {}
	local cFrame, size = __esp:GetBoundingBox(object)
	local converted2dSize = __esp:_Get2DSize(cFrame.Position + size / 2, cFrame.Position - size / 2)
    local humanoidRootPartCFrame = getRootPartCFrame()
	local inViewport, converted2dPosition = __esp:_Get2DPosition(cFrame.Position)
    while not humanoidRootPartCFrame do
        humanoidRootPartCFrame = getRootPartCFrame()
        task.wait()
    end
    customSettingsName = customSettingsName or character.Name
    customSettings = __esp.Settings.__customSettings[customSettingsName] and __esp.Settings.__customSettings[customSettingsName] or customSettings and customSettings or {
        Position = 3,
        DrawLineColor = Color3.fromRGB(255, 255, 255),
        HighlightMode = 2
    }
    __esp.Settings.__customSettings[customSettingsName] = customSettings
	local line = Drawing.new("Line")
	line.Visible = inViewport
	line.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	line.Transparency = 1
	line.Thickness = 1
	line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, __esp.Settings.__customSettings[customSettingsName].Position == 1 and 0 or __esp.Settings.__customSettings[customSettingsName].Position == 2 and workspace.CurrentCamera.ViewportSize.Y / 2 or __esp.Settings.__customSettings[customSettingsName].Position == 3 and workspace.CurrentCamera.ViewportSize.Y or 0)
	line.To = converted2dPosition
	table.insert(espContainer, line)
	local square = Drawing.new("Square")
	square.Visible = (__esp.Settings.__customSettings[customSettingsName].HighlightMode == 1 and inViewport)
	square.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	square.Transparency = 1
	square.Thickness = 1
	square.Size = converted2dSize
	square.Position = converted2dPosition - converted2dSize / 2
	square.Filled = false
	table.insert(espContainer, square)
	local text = Drawing.new("Text")
	text.Visible = (inViewport and (__esp.Settings.__showName or __esp.Settings.__showDistance))
	text.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	text.Text = (__esp.Settings.__showName and __esp.Settings.__showDistance) and name .. " - " ..  "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or __esp.Settings.__showName and name or __esp.Settings.__showDistance and "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or ""
	text.Transparency = 1
	text.Size = 15
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Position = converted2dPosition + converted2dSize - Vector2.new(converted2dSize.X, converted2dSize.Y + text.TextBounds.Y)
	text.Font = Drawing.Fonts.Monospace
	table.insert(espContainer, text)
	local highlight = Instance.new("Highlight", __esp.HighlightStorage)
	highlight.Name = __esp.Utilities.getRandomString(15)
	highlight.Adornee = object
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = __esp.Settings.__customSettings[customSettingsName].HighlightMode == 2
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.9
	highlight.OutlineColor = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	highlight.OutlineTransparency = 0
	table.insert(espContainer, highlight)
	connection = RunService.RenderStepped:Connect(function(deltaTime : number)
        if not object then
            return
        end
        local cFrame, size = __esp:GetBoundingBox(object)
        local converted2dSize = __esp:_Get2DSize(cFrame.Position + size / 2, cFrame.Position - size / 2)
        local humanoidRootPartCFrame = getRootPartCFrame()
        local inViewport, converted2dPosition = __esp:_Get2DPosition(cFrame.Position)
        if humanoidRootPartCFrame then
            text.Visible = (inViewport and (__esp.Settings.__showName or __esp.Settings.__showDistance))
            text.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            text.Text = (__esp.Settings.__showName and __esp.Settings.__showDistance) and name .. " - " ..  "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or __esp.Settings.__showName and name or __esp.Settings.__showDistance and "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or ""
            text.Size = 15
            text.Position = converted2dPosition + converted2dSize - Vector2.new(converted2dSize.X, converted2dSize.Y + text.TextBounds.Y)
            line.Visible = inViewport
            line.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, __esp.Settings.__customSettings[customSettingsName].Position == 1 and 0 or __esp.Settings.__customSettings[customSettingsName].Position == 2 and workspace.CurrentCamera.ViewportSize.Y / 2 or __esp.Settings.__customSettings[customSettingsName].Position == 3 and workspace.CurrentCamera.ViewportSize.Y or 0)
            line.To = converted2dPosition
            square.Visible = object:IsA("BasePart") and inViewport or (__esp.Settings.__customSettings[customSettingsName].HighlightMode == 1 and inViewport)
            square.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            square.Size = converted2dSize
            square.Position = converted2dPosition - converted2dSize / 2
            highlight.Enabled = __esp.Settings.__customSettings[customSettingsName].HighlightMode == 2
            highlight.OutlineColor = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
        end
	end)
    object.Destroying:Connect(function()
        if connection and connection.Connected then
            connection:Disconnect()
            connection = nil
        end
        __esp.Utilities.forEach(espContainer, function(index : number, drawingObject : any)
            drawingObject:Destroy()
        end)
    end)
	return {
		Destroy = function()
			if connection and connection.Connected then
                connection:Disconnect()
                connection = nil
            end
            __esp.Utilities.forEach(espContainer, function(index : number, drawingObject : any)
                drawingObject:Destroy()
            end)
		end
	}
end

function __esp:AddCharacter(character : Character, name : string, customSettingsName : string?, customSettings : {Position : number, DrawLineColor : Color3, HighlightMode : number}?) : {Destroy : () -> ()}
    local connection = nil
	local espContainer = {}
	local cFrame, size = __esp:GetBoundingBox(character)
	local converted2dSize = __esp:_Get2DSize(cFrame.Position + size / 2, cFrame.Position - size / 2)
    local humanoidRootPartCFrame = getRootPartCFrame()
	local inViewport, converted2dPosition = __esp:_Get2DPosition(cFrame.Position)
    if not __esp.CharacterUtilities.isCharacterValid(character) then
        return
    end
    while not humanoidRootPartCFrame do
        humanoidRootPartCFrame = getRootPartCFrame()
        task.wait()
    end
    customSettingsName = customSettingsName or character.Name
    customSettings = __esp.Settings.__customSettings[customSettingsName] and __esp.Settings.__customSettings[customSettingsName] or customSettings and customSettings or {
        Position = 3,
        DrawLineColor = Color3.fromRGB(255, 255, 255),
        HighlightMode = 2
    }
    __esp.Settings.__customSettings[customSettingsName] = customSettings
    local line = Drawing.new("Line")
	line.Visible = inViewport
	line.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	line.Transparency = 1
	line.Thickness = 1
	line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, __esp.Settings.__customSettings[customSettingsName].Position == 1 and 0 or __esp.Settings.__customSettings[customSettingsName].Position == 2 and workspace.CurrentCamera.ViewportSize.Y / 2 or __esp.Settings.__customSettings[customSettingsName].Position == 3 and workspace.CurrentCamera.ViewportSize.Y or 0)
	line.To = converted2dPosition
	table.insert(espContainer, line)
	local square = Drawing.new("Square")
	square.Visible = (__esp.Settings.__customSettings[customSettingsName].HighlightMode == 1 and inViewport)
	square.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	square.Transparency = 1
	square.Thickness = 1
	square.Size = converted2dSize
	square.Position = converted2dPosition - converted2dSize / 2
	square.Filled = false
	table.insert(espContainer, square)
	local text = Drawing.new("Text")
	text.Visible = (inViewport and (__esp.Settings.__showName or __esp.Settings.__showDistance))
	text.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	text.Text = (__esp.Settings.__showName and __esp.Settings.__showDistance) and name .. " - " ..  "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or __esp.Settings.__showName and name or __esp.Settings.__showDistance and "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or ""
	text.Transparency = 1
	text.Size = 15
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Position = converted2dPosition + converted2dSize - Vector2.new(converted2dSize.X, converted2dSize.Y + text.TextBounds.Y)
	text.Font = Drawing.Fonts.Monospace
	table.insert(espContainer, text)
	local highlight = Instance.new("Highlight", __esp.HighlightStorage)
	highlight.Name = __esp.Utilities.getRandomString(15)
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = __esp.Settings.__customSettings[customSettingsName].HighlightMode == 2
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.9
	highlight.OutlineColor = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
	highlight.OutlineTransparency = 0
	table.insert(espContainer, highlight)
    connection = RunService.RenderStepped:Connect(function(deltaTime : number)
		if not __esp.CharacterUtilities.isAlive(character) then
            if connection and connection.Connected then
                connection:Disconnect()
                connection = nil
            end
            __esp.Utilities.forEach(espContainer, function(index : number, drawingObject : any)
                drawingObject:Destroy()
            end)
            return
        end
        local cFrame, size = __esp:GetBoundingBox(character)
        local converted2dSize = __esp:_Get2DSize(cFrame.Position + size / 2, cFrame.Position - size / 2)
        local humanoidRootPartCFrame = getRootPartCFrame()
        local inViewport, converted2dPosition = __esp:_Get2DPosition(cFrame.Position)
        if humanoidRootPartCFrame then
            text.Visible = (inViewport and (__esp.Settings.__showName or __esp.Settings.__showDistance))
            text.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            text.Text = (__esp.Settings.__showName and __esp.Settings.__showDistance) and name .. " - " ..  "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or __esp.Settings.__showName and name or __esp.Settings.__showDistance and "[" .. tostring(math.floor((cFrame.Position - humanoidRootPartCFrame.Position).Magnitude)) .. "]" or ""
            text.Size = 15
            text.Position = converted2dPosition + converted2dSize - Vector2.new(converted2dSize.X, converted2dSize.Y + text.TextBounds.Y)
            line.Visible = inViewport
            line.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            line.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, __esp.Settings.__customSettings[customSettingsName].Position == 1 and 0 or __esp.Settings.__customSettings[customSettingsName].Position == 2 and workspace.CurrentCamera.ViewportSize.Y / 2 or __esp.Settings.__customSettings[customSettingsName].Position == 3 and workspace.CurrentCamera.ViewportSize.Y or 0)
            line.To = converted2dPosition
            square.Visible = (__esp.Settings.__customSettings[customSettingsName].HighlightMode == 1 and inViewport)
            square.Color = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
            square.Size = converted2dSize
            square.Position = converted2dPosition - converted2dSize / 2
            highlight.Enabled = __esp.Settings.__customSettings[customSettingsName].HighlightMode == 2
            highlight.OutlineColor = __esp.Settings.__customSettings[customSettingsName].DrawLineColor
        end
	end)
	return {
		Destroy = function()
			if connection and connection.Connected then
                connection:Disconnect()
                connection = nil
            end
            __esp.Utilities.forEach(espContainer, function(index : number, drawingObject : any)
                drawingObject:Destroy()
            end)
		end
	}
end

return __esp
