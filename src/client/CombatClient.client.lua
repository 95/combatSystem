local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Enums = ReplicatedStorage:WaitForChild("Shared").Enums

local CombatRequestType = require(Enums.CombatRequestType)
local FocusDistance = 50

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then
        return
    end

    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Remotes.CombatRequest:FireServer(CombatRequestType.Attack)
    elseif Input.KeyCode == Enum.KeyCode.F then
        Remotes.CombatRequest:FireServer(CombatRequestType.Block)
    end
end)

UserInputService.InputEnded:Connect(function(Input, GameProcessed)
    if GameProcessed then
        return
    end

    if Input.KeyCode ~= Enum.KeyCode.F then
        return
    end

    Remotes.CombatRequest:FireServer(CombatRequestType.Unblock)
end)

RunService.RenderStepped:Connect(function()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local RootPart1 = Character:WaitForChild("HumanoidRootPart")
    
    local TargetChar, TargetDist
    for _,v in pairs(Players:GetPlayers()) do
        if v == Player then
            continue
        end

        local EnemyChar = v.Character
        local EnemyRoot = EnemyChar and EnemyChar:FindFirstChild("HumanoidRootPart")

        if not EnemyRoot then
            continue
        end

        local Distance = (EnemyRoot.Position - RootPart1.Position).Magnitude
        if Distance > FocusDistance then
            continue
        end

        if TargetChar and (TargetDist < Distance) then
            continue
        end

        TargetChar = EnemyChar
        TargetDist = Distance
    end

    if not TargetChar then
        return
    end
    
    local RootPart2 = TargetChar.PrimaryPart
    local TowardsVector = (RootPart2.Position - RootPart1.Position).Unit

    RootPart1.CFrame = CFrame.fromMatrix(RootPart1.Position, TowardsVector:Cross(Vector3.yAxis), Vector3.yAxis, -TowardsVector)
end)