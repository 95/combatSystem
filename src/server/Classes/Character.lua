local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnimationsFolder = ReplicatedStorage.Animations

local Modules = script.Parent.Parent.Modules
local StatusInfo = require(Modules.StatusInfo)

local BaseCharacter = {}
BaseCharacter.__index = BaseCharacter
BaseCharacter.Characters = {}

function BaseCharacter.get(CharacterModel: Instance)
    return BaseCharacter.Characters[CharacterModel]
end

function BaseCharacter.new(...)
    local self = setmetatable({}, BaseCharacter)
    return self:Constructor(...) or self
end

function BaseCharacter:Constructor(Character: Model, Player)
    BaseCharacter.Characters[Character] = self

    self.Instance = Character

    self.Health = 100
    self.Statuses = {}

    self.UpdateConnection = RunService.Heartbeat:Connect(function()
        self:__Update()
    end)
end

function BaseCharacter:EquipWeapon(Weapon)
    self.Weapon = Weapon
end

function BaseCharacter:AddStatus(StatusName: string, Duration: number?)
    local RandomIndex = math.random()
    local ConvertedStatus = StatusName.."||"..RandomIndex

    table.insert(self.Statuses, ConvertedStatus)
    self.Player:UpdateStatuses(self.Statuses)

    if not Duration then
        return
    end

    task.delay(Duration, function()
        local StatusIndex = table.find(self.Statuses, ConvertedStatus)
        
        if not StatusIndex then
            return
        end

        table.remove(self.Statuses, StatusIndex)
        self.Player:UpdateStatuses(self.Statuses)
    end)
end

function BaseCharacter:HasStatus(Status: string | {string})
    Status = typeof(Status) == "string" and {Status} or Status

    for i, RawStatus in ipairs(self.Statuses) do
        local UnwrappedStatus = string.split(RawStatus, "||")[1]

        if table.find(Status, UnwrappedStatus) then
            return true
        end
    end
    
    return false
end

function BaseCharacter:RemoveStatus(Status: string | {string})
    Status = typeof(Status) == "string" and {Status} or Status

    for i,RawStatus in ipairs(self.Statuses) do
        local UnwrappedStatus = string.split(RawStatus, "||")[1]

        if table.find(Status, UnwrappedStatus) then
            table.remove(self.Statuses, i)
        end
    end

    self.Player:UpdateStatuses(self.Statuses)
end

function BaseCharacter:GetAllStatuses(): {string}
    local Result = {}

    for i,RawStatus in ipairs(self.Statuses) do
        local UnwrappedStatus = string.split(RawStatus, "||")[1]

        if not table.find(Result, UnwrappedStatus) then
            table.insert(Result, UnwrappedStatus)
        end
    end

    return Result
end

function BaseCharacter:LoadAnimation(AnimationName: string): AnimationTrack
    local AnimationObject = AnimationsFolder:FindFirstChild(AnimationName)
    local Humanoid = self.Instance:FindFirstChild("Humanoid")

    assert(Humanoid, "Humanoid not found")
    assert(AnimationObject, "No animation found with name "..AnimationName)

    local Animator = Humanoid:FindFirstChild("Animator") or Instance.new("Animator", Humanoid)
    return Animator:LoadAnimation(AnimationObject)
end

function BaseCharacter:RemoveAllStatuses()
    table.clear(self.Statuses)
    self.Player:UpdateStatuses(self.Statuses)
end

function BaseCharacter:TakeDamage(Damage: number)
    self.Health = math.max(1, self.Health - Damage)

    local Humanoid = self.Instance.Humanoid
    if not Humanoid then
        return
    end

    Humanoid.Health = self.Health
end

function BaseCharacter:__Update()
    local Humanoid = self.Instance.Humanoid
    if not Humanoid then
        return
    end

    local StatsToApply = {}

    for i,RawStatus in pairs(self.Statuses) do
        local Status = string.split(RawStatus, "||")[1]
        local Info = StatusInfo[Status]

        if not Info then
            continue
        end

        for StatName, SetTo in pairs(Info) do
            if StatName == "Priority" then
                continue
            end

            local function Overwrite()
                StatsToApply[StatName] = {
                    Value = SetTo,
                    Priority = Info.Priority
                }
            end

            if StatsToApply[StatName] then
                if StatsToApply[StatName].Priority <= Info.Priority then
                    continue
                end

                Overwrite()
                continue
            end
            Overwrite()
        end
    end

    for StatName, Value in pairs(StatusInfo.Base) do
        if StatsToApply[StatName] then
            continue
        end

        StatsToApply[StatName] = {
            Value = Value,
            Priority = 0
        }
    end

    for StatName,StatInfo in pairs(StatsToApply) do
        Humanoid[StatName] = StatInfo.Value
    end
end

return BaseCharacter