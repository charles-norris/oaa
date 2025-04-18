LinkLuaModifier( "modifier_lycan_boss_shapeshift_transform", "abilities/boss/lycan_boss/modifier_lycan_boss_shapeshift_transform", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lycan_boss_shapeshift", "abilities/boss/lycan_boss/modifier_lycan_boss_shapeshift", LUA_MODIFIER_MOTION_NONE )

lycan_boss_shapeshift = class(AbilityBaseClass)

function lycan_boss_shapeshift:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_shapeshift_portrait.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_shapeshift_revert.vpcf", context)
  PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_lycan.vsndevts", context)
  PrecacheResource("model", "models/creeps/knoll_1/werewolf_boss.vmdl", context)
  --PrecacheResource("soundfile", "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts", context)
end

function lycan_boss_shapeshift:OnAbilityPhaseStart()
	if IsServer() then
		self:GetCaster():EmitSound("lycan_lycan_ability_shapeshift_06")
	end
	return true
end

--------------------------------------------------------------------------------

function lycan_boss_shapeshift:OnSpellStart()
  self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_lycan_boss_shapeshift_transform", { duration = self:GetSpecialValueFor( "transformation_time" ) } )
end
