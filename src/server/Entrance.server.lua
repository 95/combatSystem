local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Classes = script.Parent.Classes
local CombatRequest = ReplicatedStorage.Remotes.CombatRequest
local CombatRequestType = require(ReplicatedStorage.Shared.Enums.CombatRequestType)

local BaseCharacter = require(Classes.Character)
local Fist = require(Classes.Weapons.Fist)

Players.PlayerAdded:Connect(function(Player)
    local function OnCharacter(Model)
        local NewCharacter = BaseCharacter.new(Model, Player)
        local NewWeapon = Fist.new(NewCharacter)

        NewCharacter:EquipWeapon(NewWeapon)
    end

    OnCharacter(Player.Character or Player.CharacterAdded:Wait())
    Player.CharacterAdded:Connect(OnCharacter)
end)

CombatRequest.OnServerEvent:Connect(function(Player, RequestType, ...)
    local Character = Player.Character
    local Wrap = Character and BaseCharacter.get(Character)

    if not Wrap then
        return
    end

    local Switch = {
        [CombatRequestType.Attack] = function()
            Wrap.Weapon:Attack()
        end,
        [CombatRequestType.Block] = function()
            Wrap.Weapon:Block()
        end,
        [CombatRequestType.Unblock] = function()
            Wrap.Weapon:Unblock()
        end
    }

    local Case = Switch[RequestType]
    if Case then
        Case(...)
    end
end)