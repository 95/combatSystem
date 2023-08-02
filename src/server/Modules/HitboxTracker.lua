local Server = script.Parent.Parent
local BaseCharacter = require(Server.Classes.Character)

local HitboxTracker = {}

type Hitbox = {
    Start: Vector3,
    End: Vector3
}

local DEBUG = true
local function CreateDebugPart(Center, Size)
    local Part = Instance.new("Part", workspace)
    Part.CFrame = Center
    Part.Size = Size
    Part.CanCollide = false
    Part.Anchored = true
    Part.Color = Color3.new(1, 0, 0)
    Part.Transparency = 0.5
    task.delay(0.5, Part.Destroy, Part)
end

function HitboxTracker.GetPartsInHitbox(Center: CFrame, Hitbox: Hitbox, ExcludeList: {Instance} | nil): {BasePart}
    ExcludeList = ExcludeList or {}

    local ZoneRegion = Region3.new(Center - Hitbox.Start, Center + Hitbox.End)
    local HitboxSize, HitboxCFrame = ZoneRegion.Size, ZoneRegion.CFrame
    HitboxCFrame = HitboxCFrame * CFrame.Angles(Center:ToEulerAnglesXYZ())
    
    local OverlapParameters = OverlapParams.new()
    OverlapParameters.FilterType = Enum.RaycastFilterType.Exclude
    OverlapParameters.FilterDescendantsInstances = ExcludeList

    if DEBUG then
        CreateDebugPart(Center, HitboxCFrame)
    end
    local Parts = workspace:GetPartBoundsInBox(HitboxCFrame, HitboxSize, OverlapParameters)
    return Parts
end

function HitboxTracker.GetCharactersInHitbox(Center: CFrame, Hitbox: Hitbox, ExcludeList: {Instance} | nil)
    local Parts = HitboxTracker.GetPartsInHitbox(Center, Hitbox, ExcludeList)
    local Characters = {}

    for i,v in pairs(Parts) do
        local Model = v:FindFirstAncestorOfClass("Model")

        if not Model then
            continue
        end

        local Wrap = BaseCharacter.get(Model)

        if not Wrap then
            continue
        end

        table.insert(Characters, Wrap)
    end

    return Characters
end

return HitboxTracker