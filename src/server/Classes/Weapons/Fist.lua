local Super = require(script.Parent.BaseWeapon)

local Fist = setmetatable({},{
   __index = Super;
})
Fist.__index = Fist

local WeaponSettings = {
    Model = nil,
    Damage = {
        Attacks = {
            5,
            5,
            5,
            10
        },
        Base = 5
    },
    Cooldowns = {
        Attacks = {
            .3,
            .3,
            .3,
            1.25
        },
        Base = .3
    },
    Animations = {
        Attacks = {
            "Anim1",
            "Anim2",
            "Anim3",
            "Anim4"
        },
        Block = "FistBlock1"
    },
    Hitbox = {
        Start = Vector3.new(2,2,2),
        End = Vector3.new(2,2,2)
    },
    ComboResetTime = 1.2,
    HitSlowedTime = .3
}

function Fist.new(CharacterClass)
    local self = setmetatable({}, Fist)
    return self:Constructor(CharacterClass) or self
end

function Fist:Constructor(CharacterClass)
    Super.Constructor(self, CharacterClass, WeaponSettings)
end

return Fist