local HitboxTracker = require(script.Parent.Parent.Parent.Modules.HitboxTracker)
local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

export type DamageConfig = {
    Attacks: {[number]: number},
    Base: number
}

export type CooldownConfig = {
    Attacks: {[number]: number},
    Base: number
}

export type AnimationsList = {
    Attacks: {[number]: string},
    Block: string
}

export type Hitbox = {
    Start: Vector3,
    End: Vector3
}

export type WeaponSettings = {
    Model: BasePart,
    Damage: DamageConfig,
    Cooldowns: CooldownConfig,
    Animations: AnimationsList,
    Hitbox : Hitbox,
    ComboResetTime: number,
    HitSlowedTime: number
}

function BaseWeapon:Constructor(CharacterClass, Config: WeaponSettings)
    self.Character = CharacterClass
    self.Model = Config.Model and Config.Model:Clone()
    self.Damage = Config.Damage
    self.Cooldowns = Config.Cooldowns
    self.Animations = Config.Animations
    self.Hitbox = Config.Hitbox

    self.Combo = 1
    self.LastAttackTime = tick()
    self.ComboResetTime = Config.ComboResetTime
    self.HitSlowedTime = Config.HitSlowedTime
end

function BaseWeapon:Attack()
    if self.Character:HasStatus({"Blocking", "Stun", "AttackCooldown"}) then
        return
    end

    self:__UpdateCombo()

    local PlayerInstance = self.Character.Player
    local CharacterModel = self.Character.Instance
    local RootPart = CharacterModel.PrimaryPart
    local CenterPoint = RootPart.CFrame + RootPart.CFrame.LookVector * 3

    local HitAnim = self.Animations.Attacks[self.Combo]
    local AnimationTrack = self.Character:LoadAnimation(HitAnim)

    local function OnKeyframeReached(KeyframeName)
        if KeyframeName ~= "Start" then
            return
        end

        local CharactersAffected = HitboxTracker.GetCharactersInHitbox(
            CenterPoint,
            self.Hitbox,
            {CharacterModel}
        )

        local DamageToTake = self.Damage.Attacks[self.Combo] or self.Damage.Base

        for i, TargetCharacter in ipairs(CharactersAffected) do
            if not TargetCharacter:HasStatus("Blocking") then
                TargetCharacter:TakeDamage(DamageToTake)
                continue
            end

            local PlayerLookVector = RootPart.CFrame.LookVector
            local TargetLookVector = TargetCharacter.Instance.PrimaryPart.CFrame.LookVector
            local LookAngleDifference = math.acos(PlayerLookVector:Dot(TargetLookVector))
            local TargetFacingPlayer = LookAngleDifference < math.rad(45)
            
            if TargetFacingPlayer then
                TargetCharacter:TakeDamage(DamageToTake/2)
            else
                TargetCharacter:TakeDamage(DamageToTake)
            end
        end
    end

    self:AddStatus("HitSlowed", self.HitSlowedTime)

    AnimationTrack.KeyframeReached:Connect(OnKeyframeReached)
    AnimationTrack:Play(0.05, nil, 1.5)

    local CooldownTimeToApply = self.Cooldowns.Attacks[self.Combo]
    self.Character:AddStatus("AttackCooldown", CooldownTimeToApply)

    self.LastAttackTime = tick()
    self.Combo += 1
end

function BaseWeapon:Block()
    if self.Character:HasStatus({"Blocking", "Stun"}) then
        return
    end

    local BlockingTrack = self.Character:LoadAnimation(self.Animations.Block)
    BlockingTrack:Play()

    self.Character:AddStatus("Blocking")
end

function BaseWeapon:Unblock()
    if not self.Character:HasStatus("Blocking") then
        return
    end

    local Humanoid = self.Character.Instance.Humanoid
    for i,v in pairs(Humanoid.Animator:GetPlayingAnimationTracks()) do
        if v.Animation.Name ~= self.Animations.Block then
            return
        end

        v:Stop()
    end

    self.Character:RemoveStatus("Blocking")
end

function BaseWeapon:__UpdateCombo()
    if (tick() - self.LastAttackTime) > self.ComboResetTime then
        self.Combo = 1
        return
    end

    if self.Combo > #self.Animations.Attacks then
        self.Combo = 1
        return
    end
end

return BaseWeapon