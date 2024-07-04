for index, value in game.Players.LocalPlayer.Backpack:GetChildren() do
    if value:IsA("Tool") and value:FindFirstChild("Setting") then
        local setting = require(value.Setting) 
        setting.Auto = true
        setting.MaxClip = math.huge
        setting.AmmoPerClip = math.huge
        setting.ReloadTime = 0
        setting.FireRate = 0
    end
end