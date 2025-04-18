
-- Taken from bb template
if CreepItemDrop == nil then
  DebugPrint ( '[creeps/item_drop] creating new CreepItemDrop object' )
  CreepItemDrop = class({})
end

--item power level defines what items drop at given time
local ItemPowerLevel = 1.0

--define how often items drop from creeps. min = 0 (0%), max = 1 (100%)
local DROP_CHANCE = 0.25

--creep properties enumerations
local NAME_ENUM = 1
local FROM_ENUM = 2
local TO_ENUM = 3
local RARITY_ENUM = 4

--defines items drop levels.
--item will start dropping, between FROM and TO itemPowerLevel.
-- RARITY is used to define how likely the item is to drop in comparison with other items.
-- the higher the value, the less likely the item is to drop
--for negative values:
--  *FROM -> any level smaller or equal than TO will have a chance to drop the item.
--  *TO   -> any level larger or equal than FROM will have  a chance to drop the item.
--  *FROM and TO -> item will drop at any level.
--  *RARITY -> item will not drop.
--it is possible to define the same item twice, for maximum flexibility
ItemPowerTable = {
  --NAME                        FROM    TO        RARITY
  { "item_infinite_bottle",      3,      -1,      1},
  { "item_madstone_bundle",      1,      -1,      1},
}

function CreepItemDrop:Init ()
  DebugPrint ( '[creeps/item_drop] Initialize' )
  self.moduleName = "CreepItemDrop (Bottle Drop)"

  Timers:CreateTimer(Dynamic_Wrap(self, 'ItemDropUpgradeTimer'), self)
end

function CreepItemDrop:SetPowerLevel (powerLevel)
  ItemPowerLevel = powerLevel
end

function CreepItemDrop:ItemDropUpgradeTimer ()
  -- upgrade creeps power level every time it triggers
  self:SetPowerLevel(ItemPowerLevel + 1)

  return 10.0
end

function CreepItemDrop:CreateDrop (itemName, death_location, killer_location)
  local newItem = CreateItem(itemName, nil, nil) -- CDOTA_Item
  newItem:SetPurchaseTime(0)
  CreateItemOnPositionSync(death_location, newItem) -- CDOTA_Item_Physical
  if itemName == "item_infinite_bottle" then
    newItem.firstPickedUp = false
    newItem:LaunchLoot(false, 300, 0.75, death_location + RandomVector(RandomFloat(50, 350)), nil)

    -- Bottle expire (despawn); can collide with ClearBottles, hence why multiple null checks
    Timers:CreateTimer(BOTTLE_DESPAWN_TIME, function ()
      -- check if safe to destroy
      if newItem and not newItem:IsNull() then
        local container = newItem:GetContainer() -- CDOTA_Item_Physical
        if container and not container:IsNull() then
          UTIL_Remove(container) -- Remove item container (CDOTA_Item_Physical)
        end
      end
    end)
  else
    newItem:LaunchLoot(false, 300, 0.25, killer_location + RandomVector(RandomFloat(50, 100)), nil)
  end
end

-- Function that removes bottles from the floor (code based on Dota 2 Offical Winter 2022 custom game and ModDota Dota 2 Tutorial)
function CreepItemDrop:ClearBottles()
  local items_on_the_ground = Entities:FindAllByClassname("dota_item_drop")
  for _, item in pairs(items_on_the_ground) do
    if item and not item:IsNull() then
      local containedItem = item:GetContainedItem()
      if containedItem and not containedItem:IsNull() then
        if containedItem.GetAbilityName and containedItem:GetAbilityName() == "item_infinite_bottle" then
          UTIL_Remove(containedItem) -- Remove item ability (CDOTA_Item)
          if item and not item:IsNull() then
            UTIL_Remove(item) -- Remove item container (CDOTA_Item_Physical)
          end
        end
      end
    end
  end
end

function CreepItemDrop:RandomDropItemName(campLocationString)
  if not CreepCamps then
    return ""
  end

  if not CreepCamps.CampPRDCounters then
    CreepCamps.CampPRDCounters = {}
    return ""
  end

  if CreepCamps.CampPRDCounters[campLocationString] == nil then
    CreepCamps.CampPRDCounters[campLocationString] = 1
  end

  local prng_multiplier = CreepCamps.CampPRDCounters[campLocationString]

  --first we need to check against the drop percentage.
  if RandomFloat(0, 1) > (PrdCFinder:GetCForP(DROP_CHANCE) * prng_multiplier) then
    -- Increment PRD counter if nothing was dropped
    CreepCamps.CampPRDCounters[campLocationString] = prng_multiplier + 1
    return ""
  end

  --now iterate through item power table and see which items qualify for
  local totalChancePool = 0.0
  local filteredItemTable = {}

  for i=1, #ItemPowerTable do
    local from = ItemPowerTable[i][FROM_ENUM]
    local to = ItemPowerTable[i][TO_ENUM]
    local rarity = ItemPowerTable[i][RARITY_ENUM]

    if (from < 0 or (from >= 0 and ItemPowerLevel >= from)) and (to < 0 or (to >= 0 and ItemPowerLevel <= to)) and rarity > 0 then
      totalChancePool = totalChancePool + 1.0 / rarity
      filteredItemTable[#filteredItemTable + 1] = ItemPowerTable[i]
    end
  end

  local passedItemsCumulativeChance = 0.0
  local dropChance = RandomFloat(0, 1) * totalChancePool

  for i=1, #filteredItemTable do
    passedItemsCumulativeChance = passedItemsCumulativeChance + 1.0 / filteredItemTable[i][RARITY_ENUM]
    if passedItemsCumulativeChance >= dropChance then
      -- Reset PRD counter on successful drop roll
      CreepCamps.CampPRDCounters[campLocationString] = 1
      return filteredItemTable[i][NAME_ENUM]
    end
  end

  --in case some configuration was done wrong, return empty, otherwise this point should not be reached normally.
  return ""
end
