newTalentType {
  type = "technique/skirmisher-slings",
  name = "Skirmisher - Slings",
  allow_random = true,
  description = "Slings! Pow Pow!",
}

local sling_equipped = function(self, silent)
  if not self:hasArcheryWeapon("sling") then
    if not silent then
      game.logPlayer(self, "You must weild a sling!")
    end
    return false
  end
  return true
end

-- Hack in Sling Supremacy to affect reload rate.
local reload = Talents:getTalentFromId("T_RELOAD")
local old_shots_per_turn = reload.shots_per_turn
reload.shots_per_turn = function(self, t)
  local old_spt = old_shots_per_turn(self, t)
  local sling_supremacy = Talents:getTalentFromId("T_SKIRMISHER_SLING_SUPREMACY")
  local new_spt = self:getTalentLevelRaw(t) +
    (self:attr("ammo_reload_speed") or 0) +
    sling_supremacy.reload_bonus(self, sling_supremacy)
  return math.max(old_spt, new_spt)
end

-- Currently just a copy of Sling Mastery.
-- TODO Make unique.
newTalent {
  short_name = "SKIRMISHER_SLING_SUPREMACY",
  name = "Sling Supremacy",
  type = {"technique/skirmisher-slings", 1},
  require = { stat = { dex=function(level) return 12 + level * 6 end }, },
  points = 5,
  mode = "passive",
  reload_bonus = function(self, t)
    local level = self:getTalentLevelRaw(t)
    if level >= 5 then return 3 end
    if level >= 4 then return 2 end
    if level >= 2 then return 1 end
    return 0
  end,
	getDamage = function(self, t) return self:getTalentLevel(t) * 10 end,
	getPercentInc = function(self, t) return math.sqrt(self:getTalentLevel(t) / 5) / 2 end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local inc = t.getPercentInc(self, t)
		return ([[Increases Physical Power by %d and increases weapon damage by %d%% when using slings.
		Also, when using Reload:
		At level 2, it grants one more reload per turn.
		At level 4, it grants two more reloads per turn.
		At level 5, it grants three more reloads per turn.
		]]):
		format(damage, inc * 100)
	end,
}

newTalent {
  short_name = "SKIRMISHER_SWIFT_SHOT",
  name = "Swift Shot",
  type = {"technique/skirmisher-slings", 2},
  require = techs_dex_req2,
  points = 5,
  no_energy = "fake",
  random_ego = "attack",
  tactical = {ATTACK = {weapon = 2}},
  range = archery_range,
  cooldown = 0,
  stamina = 10,
	on_pre_use = function(self, t, silent) return sling_equipped(self, silent) end,
  getDamage = function(self, t)
    return self:combatTalentWeaponDamage(t, 1.4, 2.4)
  end,
  callbackOnMove = function(self, t, moved, force, ox, oy)
    local cooldown = self.talents_cd[t.id] or 0
    if cooldown > 0 then
      self.talents_cd[t.id] = math.max(cooldown - 1, 0)
    end
  end,
  action = function(self, t)
		if not sling_equipped(self) then return end

    local old_speed = self.combat_physspeed
    self.combat_physspeed = old_speed * 2

		local targets = self:archeryAcquireTargets(nil, {one_shot=true})
		if not targets then
      self.combat_physspeed = old_speed
      return
    end

		self:archeryShoot(targets, t, nil, {mult=t.getDamage(self, t)})
    self.combat_physspeed = old_speed
    return true
  end,
	info = function(self, t)
		return ([[Fire off a quick sling bullet for %d%% damage, at double your normal attack speed. Moving lowers the cooldown by 1.]])
      :format(t.getDamage(self, t) * 100)
	end,
}
