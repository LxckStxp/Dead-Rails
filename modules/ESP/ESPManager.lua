return function(Config, Utilities, ESPObject, ESPConfig)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer
    
    local ESPManager = {
        Items = {},
        Humanoids = {},
        Connection = nil,
        VanillaUIVisible = true
    }
    
    -- Function to hide vanilla name/health bars for players
    local function hideVanillaUI()
        if not ESPManager.VanillaUIVisible then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and player.Character:FindFirstChild("Humanoid") then
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in pairs({game.CoreGui, playerGui}) do
                        for _, child in pairs(gui:GetChildren()) do
                            if child:IsA("BillboardGui") and (child.Name:match("NameGui") or child.Name:match("HealthGui")) then
                                child.Enabled = false
                            end
                        end
                    end
                end
            end
        end
        ESPManager.VanillaUIVisible = false
    end
    
    -- Function to restore vanilla name/health bars
    local function restoreVanillaUI()
        if ESPManager.VanillaUIVisible then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character and player.Character:FindFirstChild("Humanoid") then
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in pairs({game.CoreGui, playerGui}) do
                        for _, child in pairs(gui:GetChildren()) do
                            if child:IsA("BillboardGui") and (child.Name:match("NameGui") or child.Name:match("HealthGui")) then
                                child.Enabled = true
                            end
                        end
                    end
                end
            end
        end
        ESPManager.VanillaUIVisible = true
    end
    
    function ESPManager.Update()
        if not Config.Enabled then return end
        
        local runtimeItems = workspace:FindFirstChild("RuntimeItems")
        if runtimeItems then
            for _, item in pairs(runtimeItems:GetChildren()) do
                if not ESPManager.Items[item] then
                    ESPManager.Items[item] = ESPObject.Create(item, "Item")
                end
            end
        end
        
        for item, esp in pairs(ESPManager.Items) do
            if item.Parent then
                esp:Update()
            else
                esp:Destroy()
                ESPManager.Items[item] = nil
            end
        end
        
        for _, humanoid in pairs(workspace:GetDescendants()) do
            if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not ESPManager.Humanoids[humanoid] then
                    local isPlayer = Utilities.isPlayerCharacter(humanoid)
                    ESPManager.Humanoids[humanoid] = ESPObject.Create(humanoid, isPlayer and "Player" or "NPC")
                end
            end
        end
        
        for humanoid, esp in pairs(ESPManager.Humanoids) do
            if humanoid.Parent then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    esp:Update()
                else
                    esp:Destroy()
                    ESPManager.Humanoids[humanoid] = nil
                end
            else
                esp:Destroy()
                ESPManager.Humanoids[humanoid] = nil
            end
        end
    end
    
    function ESPManager.Initialize()
        local lastUpdate = 0
        ESPManager.Connection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastUpdate >= ESPConfig.UpdateInterval then
                ESPManager.Update()
                lastUpdate = currentTime
            end
        end)
        ESPManager.Update()
        
        -- Hide vanilla UI initially if ESP is enabled
        if Config.Enabled then
            hideVanillaUI()
        end
    end
    
    function ESPManager.Cleanup()
        for _, esp in pairs(ESPManager.Items) do
            esp:Destroy()
        end
        for _, esp in pairs(ESPManager.Humanoids) do
            esp:Destroy()
        end
        ESPManager.Items = {}
        ESPManager.Humanoids = {}
        if ESPManager.Connection then
            ESPManager.Connection:Disconnect()
            ESPManager.Connection = nil
        end
        
        -- Restore vanilla UI when cleaning up
        restoreVanillaUI()
    end
    
    -- Handle ESP enable/disable explicitly
    function ESPManager.SetEnabled(enabled)
        Config.Enabled = enabled
        if enabled then
            hideVanillaUI()
            ESPManager.Update() -- Force an update to re-enable ESP
        else
            restoreVanillaUI()
            ESPManager.Cleanup()
        end
    end
    
    return ESPManager
end
