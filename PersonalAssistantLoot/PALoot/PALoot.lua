-- Local instances of Global tables --
local PA = PersonalAssistant
local PAC = PA.Constants
local PAHF = PA.HelperFunctions
local PAL = PA.Loot
local PALProfileManager = PA.ProfileManager.PALoot

-- =====================================================================================================================

local GET_NUM_BAG_USED_SLOTS_INTERVAL_MS = 100
local GET_NUM_BAG_USED_SLOTS_TIMEOUT_MS = 1000
local CALL_LATER_FUNCTION_NAME = "CallLaterFunction_GetNumBagUsedSlots"

local IS_ITEM_SET_COLLECTION_PIECE_UNLOCKED_INTERVAL_MS = 250
local IS_ITEM_SET_COLLECTION_PIECE_UNLOCKED_TIMEOUT_MS = 3000 -- 3s should be sufficient; in personal testing I noticed "only" up to 1s so far
local CALL_LATER_FUNCTION_SET_COLLECTION_PIECE_UNLOCKED_NAME = "CallLaterFunction_SetCollectionPieceUnlocked"

local function _getUniqueUpdateIdentifier()
    return CALL_LATER_FUNCTION_NAME
end

local function _getUniqueSetCollectionUpdateIdentifier(itemId)
    return table.concat({CALL_LATER_FUNCTION_SET_COLLECTION_PIECE_UNLOCKED_NAME, tostring(itemId)})
end

local TraitIndexFromItemTraitType = {
    [ITEM_TRAIT_TYPE_WEAPON_POWERED] = 1,       -- 1
    [ITEM_TRAIT_TYPE_WEAPON_CHARGED] = 2,       -- 2
    [ITEM_TRAIT_TYPE_WEAPON_PRECISE] = 3,       -- 3
    [ITEM_TRAIT_TYPE_WEAPON_INFUSED] = 4,       -- 4
    [ITEM_TRAIT_TYPE_WEAPON_DEFENDING] = 5,     -- 5
    [ITEM_TRAIT_TYPE_WEAPON_TRAINING] = 6,      -- 6
    [ITEM_TRAIT_TYPE_WEAPON_SHARPENED] = 7,     -- 7
    [ITEM_TRAIT_TYPE_WEAPON_DECISIVE] = 8,      -- 8
    [ITEM_TRAIT_TYPE_WEAPON_WEIGHTED] = 8,      -- 8
    [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED] = 9,     -- 26
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = nil,   -- 9
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE] = nil,      -- 10

    [ITEM_TRAIT_TYPE_ARMOR_STURDY] = 1,         -- 11
    [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = 2,   -- 12
    [ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = 3,     -- 13
    [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = 4,    -- 14
    [ITEM_TRAIT_TYPE_ARMOR_TRAINING] = 5,       -- 15
    [ITEM_TRAIT_TYPE_ARMOR_INFUSED] = 6,        -- 16
    [ITEM_TRAIT_TYPE_ARMOR_EXPLORATION] = 7,    -- 17
    [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS] = 7,     -- 17
    [ITEM_TRAIT_TYPE_ARMOR_DIVINES] = 8,        -- 18
    [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = 9,      -- 25
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = nil,    -- 20
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE] = nil,       -- 19

    [ITEM_TRAIT_TYPE_JEWELRY_ARCANE] = 1,       -- 22
    [ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] = 2,      -- 21
    [ITEM_TRAIT_TYPE_JEWELRY_ROBUST] = 3,       -- 23
    [ITEM_TRAIT_TYPE_JEWELRY_TRIUNE] = 4,       -- 30
    [ITEM_TRAIT_TYPE_JEWELRY_INFUSED] = 5,      -- 33
    [ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE] = 6,   -- 32
    [ITEM_TRAIT_TYPE_JEWELRY_SWIFT] = 7,        -- 28
    [ITEM_TRAIT_TYPE_JEWELRY_HARMONY] = 8,      -- 29
    [ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY] = 9, -- 31
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = nil,  -- 27
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = nil,     -- 24
}

local ResearchLineIndexFromType = {
    [CRAFTING_TYPE_CLOTHIER] = {
        ARMOR = {
            -- add +7 for "Medium" armor (instead of "Light")
            [EQUIP_TYPE_CHEST] = 1,             -- 3
            [EQUIP_TYPE_FEET] = 2,              -- 10
            [EQUIP_TYPE_HAND] = 3,              -- 13
            [EQUIP_TYPE_HEAD] = 4,              -- 1
            [EQUIP_TYPE_LEGS] = 5,              -- 9
            [EQUIP_TYPE_SHOULDERS] = 6,         -- 4
            [EQUIP_TYPE_WAIST] = 7,             -- 8
        },
    },
    [CRAFTING_TYPE_WOODWORKING] = {
        WEAPON = {
            [WEAPONTYPE_BOW] = 1,               -- 8
            [WEAPONTYPE_FIRE_STAFF] = 2,        -- 12
            [WEAPONTYPE_FROST_STAFF] = 3,       -- 13
            [WEAPONTYPE_LIGHTNING_STAFF] = 4,   -- 15
            [WEAPONTYPE_HEALING_STAFF] = 5,     -- 9
            [WEAPONTYPE_SHIELD] = 6,            -- 7
        }
    },
    [CRAFTING_TYPE_BLACKSMITHING] = {
        WEAPON = {
            [WEAPONTYPE_AXE] = 1,               -- 1
            [WEAPONTYPE_HAMMER] = 2,            -- 2
            [WEAPONTYPE_SWORD] = 3,             -- 3
            [WEAPONTYPE_TWO_HANDED_AXE] = 4,    -- 5
            [WEAPONTYPE_TWO_HANDED_HAMMER] = 5, -- 6
            [WEAPONTYPE_TWO_HANDED_SWORD] = 6,  -- 4
            [WEAPONTYPE_DAGGER] = 7,            -- 11
        },
        ARMOR = {
            [EQUIP_TYPE_CHEST] = 8,             -- 3
            [EQUIP_TYPE_FEET] = 9,              -- 10
            [EQUIP_TYPE_HAND] = 10,             -- 13
            [EQUIP_TYPE_HEAD] = 11,             -- 1
            [EQUIP_TYPE_LEGS] = 12,             -- 9
            [EQUIP_TYPE_SHOULDERS] = 13,        -- 4
            [EQUIP_TYPE_WAIST] = 14,            -- 8
        }
    },
    [CRAFTING_TYPE_JEWELRYCRAFTING] = {
        ARMOR = {
            [EQUIP_TYPE_NECK] = 1,              -- 2
            [EQUIP_TYPE_RING] = 2,              -- 12
        },
    },
}

local WoodworkingWeaponTypes = {
    [WEAPONTYPE_BOW] = true,
    [WEAPONTYPE_FIRE_STAFF] = true,
    [WEAPONTYPE_FROST_STAFF] = true,
    [WEAPONTYPE_HEALING_STAFF] = true,
    [WEAPONTYPE_LIGHTNING_STAFF] = true,
    [WEAPONTYPE_SHIELD] = true,
}

local BlacksmithingWeaponTypes = {
    [WEAPONTYPE_AXE] = true,
    [WEAPONTYPE_DAGGER] = true,
    [WEAPONTYPE_HAMMER] = true,
    [WEAPONTYPE_SWORD] = true,
    [WEAPONTYPE_TWO_HANDED_AXE] = true,
    [WEAPONTYPE_TWO_HANDED_HAMMER] = true,
    [WEAPONTYPE_TWO_HANDED_SWORD] = true,
}

local JewelcraftingEquipTypes = {
    [EQUIP_TYPE_RING] = true,
    [EQUIP_TYPE_NECK] = true,
}

local function GetCraftingTypeAndResearchLineIndexFromItemLink(itemLink)
    local itemType = GetItemLinkItemType(itemLink)
    -- Apparel
    if itemType == ITEMTYPE_ARMOR then
        -- check equipType to distinguish Jewelry from other Apparel
        local equipType = GetItemLinkEquipType(itemLink)
        if JewelcraftingEquipTypes[equipType] then
            return CRAFTING_TYPE_JEWELRYCRAFTING, ResearchLineIndexFromType[CRAFTING_TYPE_JEWELRYCRAFTING].ARMOR[equipType]
        else
            -- check armorType to distinguish Light/Medium/Heavy Armor
            local armorType = GetItemLinkArmorType(itemLink)
            if armorType == ARMORTYPE_LIGHT then
                return CRAFTING_TYPE_CLOTHIER, ResearchLineIndexFromType[CRAFTING_TYPE_CLOTHIER].ARMOR[equipType]
            elseif armorType == ARMORTYPE_MEDIUM then
                return CRAFTING_TYPE_CLOTHIER, ResearchLineIndexFromType[CRAFTING_TYPE_CLOTHIER].ARMOR[equipType] + 7
            elseif armorType == ARMORTYPE_HEAVY then
                return CRAFTING_TYPE_BLACKSMITHING, ResearchLineIndexFromType[CRAFTING_TYPE_BLACKSMITHING].ARMOR[equipType]
            end
        end
        -- Weapon
    elseif itemType == ITEMTYPE_WEAPON then
        -- check weaponType to distinguish between Blacksmithing and Woodworking
        local weaponType = GetItemLinkWeaponType(itemLink)
        if BlacksmithingWeaponTypes[weaponType] then
            return CRAFTING_TYPE_BLACKSMITHING, ResearchLineIndexFromType[CRAFTING_TYPE_BLACKSMITHING].WEAPON[weaponType]
        elseif WoodworkingWeaponTypes[weaponType] then
            return CRAFTING_TYPE_WOODWORKING, ResearchLineIndexFromType[CRAFTING_TYPE_WOODWORKING].WEAPON[weaponType]
        end
    end
    -- if no match found, return nil
    return nil
end


-- init with current numUsedSlots
local _prevUsedSlots = GetNumBagUsedSlots(BAG_BACKPACK)

-- ---------------------------------------------------------------------------------------------------------------------

-- refresh the item icons after a unlockable set collection item was bound
-- this is checked with a 500ms interval after the event was triggered. It will repeatedly check it until the status
-- has changed or until the timeout has been reached
local function _updateItemIconsWhenSetCollectionPieceUnlocked(itemId)
    -- before starting make sure any already registered UpdateEvent is unregistered to not run them in parallel
    local identifier = _getUniqueSetCollectionUpdateIdentifier(itemId)
    EVENT_MANAGER:UnregisterForUpdate(identifier)
    local startGameTime = GetGameTimeMilliseconds()
    local isBeforeSetCollectionPieceUnlocked = IsItemSetCollectionPieceUnlocked(itemId)
    EVENT_MANAGER:RegisterForUpdate(identifier, IS_ITEM_SET_COLLECTION_PIECE_UNLOCKED_INTERVAL_MS,
        function()
            local isSetCollectionPieceUnlocked = IsItemSetCollectionPieceUnlocked(itemId)
            local passedGameTime = GetGameTimeMilliseconds() - startGameTime
            if isSetCollectionPieceUnlocked or passedGameTime > IS_ITEM_SET_COLLECTION_PIECE_UNLOCKED_TIMEOUT_MS then
                EVENT_MANAGER:UnregisterForUpdate(identifier)
                PAL.debugln('IsItemSetCollectionPieceUnlocked took approx. %d ms (%s -> %s)', passedGameTime, tostring(isBeforeSetCollectionPieceUnlocked), tostring(isSetCollectionPieceUnlocked))
                PAL.ItemIcons.refreshScrollListVisible()
            end
        end)
end
-- ---------------------------------------------------------------------------------------------------------------------


local function combatState(fighting)
   if not fighting then
      PAL.learnNowOrLater()
	  PAL.bindNowOrLater()
	  PAL.combineNowOrLater()
   end
end

-- ---------------------------------------------------------------------------------------------------------------------

local function sceneChange(oldState, newState)
    if (newState == SCENE_SHOWN) then
        PAL.learnNowOrLater()
    elseif (newState == SCENE_HIDDEN) then
        -- do stuff
    end
end

-- ---------------------------------------------------------------------------------------------------------------------
local function hideBook() -- do not display the motif book
    SCENE_MANAGER:ShowBaseScene()
	EVENT_MANAGER:UnregisterForEvent("hideBook", EVENT_SHOW_BOOK)
end

-- ---------------------------------------------------------------------------------------------------------------------

local function learnNowOrLater(bagId, slotIndex)
    local hud = SCENE_MANAGER:GetScene("hud")
	local inHud = hud:GetState() == SCENE_SHOWN
	local inCombat = IsUnitInCombat("player")
    if bagId and slotIndex and inHud and not inCombat then
		EVENT_MANAGER:RegisterForEvent("hideBook", EVENT_SHOW_BOOK, hideBook)
		CallSecureProtected("UseItem", bagId, slotIndex)
		hud:UnregisterCallback("StateChange", sceneChange)
		EVENT_MANAGER:UnregisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE)

	elseif bagId and slotIndex then
       PAL.itemsToLearn = PAL.itemsToLearn or {}
       local thisItem = {}
       thisItem.name = GetItemName(bagId, slotIndex)	   
       thisItem.bagId = bagId
  	   thisItem.slotIndex = slotIndex
	   table.insert(PAL.itemsToLearn, thisItem) 
       hud:RegisterCallback("StateChange", sceneChange)
	   EVENT_MANAGER:RegisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE, combatState)

	else
	    if not ZO_IsTableEmpty(PAL.itemsToLearn) then
		    local lastEntry = #PAL.itemsToLearn
			local name = PAL.itemsToLearn[lastEntry].name
			local bagId = PAL.itemsToLearn[lastEntry].bagId
			local slotIndex = PAL.itemsToLearn[lastEntry].slotIndex
		    if name == GetItemName(bagId, slotIndex) then
			    PAL.learnNowOrLater(bagId, slotIndex)
			end
		    zo_callLater(PAL.learnNowOrLater, 1000)
			table.remove(PAL.itemsToLearn, lastEntry)
		end
        	
    end	
end

-- ---------------------------------------------------------------------------------------------------------------------

local function bindNowOrLater(bagId, slotIndex)
    --local hud = SCENE_MANAGER:GetScene("hud")
	--local inHud = hud:GetState() == SCENE_SHOWN
	local inCombat = IsUnitInCombat("player")
    if bagId and slotIndex and not inCombat then
        BindItem(bagId, slotIndex)
		--hud:UnregisterCallback("StateChange", sceneChange)
		EVENT_MANAGER:UnregisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE)

	elseif bagId and slotIndex then
       PAL.itemsToBind = PAL.itemsToBind or {}
       local thisItem = {}
       thisItem.name = GetItemName(bagId, slotIndex)	   
       thisItem.bagId = bagId
  	   thisItem.slotIndex = slotIndex
	   table.insert(PAL.itemsToBind, thisItem) 
       --hud:RegisterCallback("StateChange", sceneChange)
	   EVENT_MANAGER:RegisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE, combatState)

	else
	    if not ZO_IsTableEmpty(PAL.itemsToBind) then
		    local lastEntry = #PAL.itemsToBind
			local name = PAL.itemsToBind[lastEntry].name
			local bagId = PAL.itemsToBind[lastEntry].bagId
			local slotIndex = PAL.itemsToBind[lastEntry].slotIndex
		    if name == GetItemName(bagId, slotIndex) then
			    PAL.bindNowOrLater(bagId, slotIndex)
			end
		    zo_callLater(PAL.bindNowOrLater, 1000)
			table.remove(PAL.itemsToBind, lastEntry)
		end
        	
    end	
end

-- ---------------------------------------------------------------------------------------------------------------------

local function combineNowOrLater(bagId, slotIndex)

	local inCombat = IsUnitInCombat("player")
    if bagId and slotIndex and not inCombat and not IsMounted() and not IsUnitSwimming("player") and not IsPlayerMoving() and not IsPlayerInAvAWorld() and not IsActiveWorldBattleground() then
	     --d("check if "..GetItemName(bagId, slotIndex).." can be combined")
		 local combinationId = GetItemCombinationId(bagId, slotIndex)
		 if combinationId == 0 then return end
		 if CheckPlayerCanPerformCombinationAndWarn(combinationId) then
		    --d(GetItemName(bagId, slotIndex).." can be combined")
			local collectibleId = GetCombinationCollectibleComponentId(combinationId, 1)
			if not IsCollectibleUnlocked(collectibleId) then
				CallSecureProtected("UseItem", bagId, slotIndex) 
			end
		 end

		EVENT_MANAGER:UnregisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE)

	elseif bagId and slotIndex then
       PAL.itemsToCombine = PAL.itemsToCombine or {}
       local thisItem = {}
       thisItem.name = GetItemName(bagId, slotIndex)	   
       thisItem.bagId = bagId
  	   thisItem.slotIndex = slotIndex
	   table.insert(PAL.itemsToCombine, thisItem) 
	   EVENT_MANAGER:RegisterForEvent("combatStateChange", EVENT_PLAYER_COMBAT_STATE, combatState)

	else
	    if not ZO_IsTableEmpty(PAL.itemsToCombine) then
		    local lastEntry = #PAL.itemsToCombine
			local name = PAL.itemsToCombine[lastEntry].name
			local bagId = PAL.itemsToCombine[lastEntry].bagId
			local slotIndex = PAL.itemsToCombine[lastEntry].slotIndex
		    if name == GetItemName(bagId, slotIndex) then
			    PAL.combineNowOrLater(bagId, slotIndex)
			end
		    zo_callLater(PAL.combineNowOrLater, 1000)
			table.remove(PAL.itemsToCombine, lastEntry)
		end
        	
    end	
end

-- ---------------------------------------------------------------------------------------------------------------------

local function isTraitBeingResearched(itemLink)
    local craftingSkillType, researchLineIndex = GetCraftingTypeAndResearchLineIndexFromItemLink(itemLink)
    local traitType = GetItemLinkTraitInfo(itemLink)
    local traitIndex = TraitIndexFromItemTraitType[traitType]

    -- try to get remaining research time
    local duration = GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)

    -- either the duration is returned (being researched); or nil (not being researched)
    return duration ~= nil
end

-- ---------------------------------------------------------------------------------------------------------------------

local function tryToMarkAsJunk(bagId, slotIndex)
    if not CanItemBeMarkedAsJunk(bagId, slotIndex) or IsItemJunk(bagId, slotIndex) then
	    return
	end
	
	local itemValue = GetItemSellValueWithBonuses(bagId, slotIndex)
	if itemValue then
        SetItemIsJunk(bagId, slotIndex, true)
	end
end
-- ---------------------------------------------------------------------------------------------------------------------

local function OnInventorySingleSlotUpdate(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
    if PALProfileManager.hasActiveProfile() then
        local PALootSavedVars = PAL.SavedVars
        local usedSlots = GetNumBagUsedSlots(BAG_BACKPACK)

        -- check if addon is enabled
        if PALootSavedVars.LootEvents.lootEventsEnabled then
            local itemType, specializedItemType = GetItemType(bagId, slotIndex)
            local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
            local itemFilterType = GetItemFilterTypeInfo(bagId, slotIndex)
			local itemUseType = GetItemUseType(bagId, slotIndex)

            -- Recipes
            if itemType == ITEMTYPE_RECIPE then
                if PALootSavedVars.LootEvents.LootRecipes.unknownRecipeMsg or PALootSavedVars.LootEvents.LootStyles.autoLearnRecipe or PALootSavedVars.LootEvents.LootStyles.autoLearnFurnishingPlan then
                    local isRecipeKnown = PAHF.IsRecipeKnown(itemLink)
                    if not isRecipeKnown then
					    if PALootSavedVars.LootEvents.LootRecipes.unknownRecipeMsg then
                            if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     --d("Character Needs: "..tostring(PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink)))
                                     PAL.println(SI_PA_CHAT_LOOT_RECIPE_UNKNOWN, itemLink)
                                 end
                             else
                                 PAL.println(SI_PA_CHAT_LOOT_RECIPE_UNKNOWN, itemLink)
                             end
						end 

					    if specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD then -- recipe
						    if PALootSavedVars.LootEvents.LootStyles.autoLearnRecipe then -- auto learn recipe
							    if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                     if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                         learnNowOrLater(bagId, slotIndex)
                                     end
                                 else
                                     learnNowOrLater(bagId, slotIndex)
                                 end
							end 
					    else -- furnishing plan
						    if PALootSavedVars.LootEvents.LootStyles.autoLearnFurnishingPlan then
                                 if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                     if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                         learnNowOrLater(bagId, slotIndex)
                                     end
                                 else
                                     learnNowOrLater(bagId, slotIndex)
                                 end
							end   
						end
						
                    else
                        -- Recipe is already known;
                        PAL.debugln("known recipe looted: %s", itemLink)
						if PALootSavedVars.LootEvents.LootStyles.autoMarkAsJunkRecipes then
						     tryToMarkAsJunk(bagId, slotIndex) 
						end
                    end
                end

            -- Motifs
            elseif itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then
                if PALootSavedVars.LootEvents.LootStyles.unknownMotifMsg or PALootSavedVars.LootEvents.LootStyles.autoLearnMotif then
                    local isKnown = PAHF.IsBookKnown(itemLink)
                     if not isKnown then
                         if PALootSavedVars.LootEvents.LootStyles.autoLearnMotif then -- auto learn motif
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     learnNowOrLater(bagId, slotIndex)
                                 end
                             else
                                 learnNowOrLater(bagId, slotIndex)
                             end
                        end
						if PALootSavedVars.LootEvents.LootStyles.unknownMotifMsg then
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     PAL.println(SI_PA_CHAT_LOOT_MOTIF_UNKNOWN, itemLink)
                                 end
                             else
                                 PAL.println(SI_PA_CHAT_LOOT_MOTIF_UNKNOWN, itemLink)
                             end
                         end
                     else
                         -- Motif is already known; do nothing for now
                         PAL.debugln("known motif looted: %s", itemLink)
                    end
                end

            elseif PAHF.isItemForCompanion(bagId, slotIndex) then
                -- has to be checked before Apparel & Weapons, since Companion items are also considered apparel and weapons
                local itemQualityThreshold = PALootSavedVars.LootEvents.LootCompanionItems.qualityThreshold
                if isNewItem and itemQualityThreshold ~= PAC.ITEM_QUALITY.DISABLED then
                    local itemQuality = GetItemFunctionalQuality(bagId, slotIndex)
                    PAL.debugln("isItemForCompanion(true), is quality %d >= %d ?", itemQuality, itemQualityThreshold)
                    if itemQuality >= itemQualityThreshold then
                        local traitType = GetItemLinkTraitInfo(itemLink)
                        local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
                        PAL.println(SI_PA_CHAT_LOOT_COMPANION_ITEM, itemLink, traitName)
                    else
                        -- Companion item below quality threshold
                        PAL.debugln("isItemForCompanion(true), companion item below threshold: %s", itemLink)
                    end
                end

            -- Apparel & Weapons
            elseif itemFilterType == ITEMFILTERTYPE_ARMOR or itemFilterType == ITEMFILTERTYPE_WEAPONS or itemFilterType == ITEMFILTERTYPE_JEWELRY then
                if PALootSavedVars.LootEvents.LootApparelWeapons.unknownTraitMsg then
                    local canBeResearched = CanItemLinkBeTraitResearched(itemLink)
    --                local isBeingResearched = isTraitBeingResearched(itemLink)
                    if canBeResearched then
                        local traitType, traitDescription = GetItemLinkTraitInfo(itemLink)
                        local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
                        PAL.println(SI_PA_CHAT_LOOT_TRAIT_UNKNOWN, itemLink, traitName)
                    else
                        -- Trait already researched
                        PAL.debugln("item with known trait looted: %s", itemLink)
                    end
                end
                if PALootSavedVars.LootEvents.LootApparelWeapons.uncollectedSetMsg or PALootSavedVars.LootEvents.LootApparelWeapons.autoBind then
                    if IsItemLinkSetCollectionPiece(itemLink) then
                        if isNewItem then
                            local isItemSetCollectionPieceUnlocked = IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
                            if not isItemSetCollectionPieceUnlocked then
                                local _, setName = GetItemLinkSetInfo(itemLink)
								if PALootSavedVars.LootEvents.LootApparelWeapons.autoBind then -- auto bind
								    bindNowOrLater(bagId, slotIndex)
								elseif PALootSavedVars.LootEvents.LootApparelWeapons.uncollectedSetMsg then 
                                   PAL.println(SI_PA_CHAT_LOOT_SET_UNCOLLECTED, itemLink, setName)
								end

                                PAL.debugln("A) IsItemBound(%s)", tostring(IsItemBound(bagId, slotIndex)))
                            else
                                -- Set item already collected
                                PAL.debugln("set item already collected: %s", itemLink)
                                PAL.debugln("B) IsItemBound(%s) already", tostring(IsItemBound(bagId, slotIndex)))
                            end
                        else
                            -- if the item is not new anymore; then this is most likely because it was just bound -> refresh the icons
                            PAL.debugln("C) Set item is not new - was it just bound? REFRESH LIST! %s", itemLink)
                            _updateItemIconsWhenSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
                        end
                    end
                end

            -- Style Pages
            elseif specializedItemType == SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE or specializedItemType == SPECIALIZED_ITEMTYPE_COLLECTIBLE_STYLE_PAGE then
                if PALootSavedVars.LootEvents.LootStyles.unknownStylePageMsg or PALootSavedVars.LootEvents.LootStyles.autoLearnStylePage then 
                    local containerCollectibleId = GetItemLinkContainerCollectibleId(itemLink)
                    local isValidForPlayer = IsCollectibleValidForPlayer(containerCollectibleId)
                    local isUnlocked = IsCollectibleUnlocked(containerCollectibleId)
                    if isValidForPlayer and not isUnlocked then
					    if PALootSavedVars.LootEvents.LootStyles.unknownStylePageMsg then
                           PAL.println(SI_PA_CHAT_LOOT_MOTIF_UNKNOWN, itemLink)
						end  

						if PALootSavedVars.LootEvents.LootStyles.autoLearnStylePage then -- auto learn style page
						   	learnNowOrLater(bagId, slotIndex)
						end
						
                    else
                        -- Style Page already known; do nothing for know
                        PAL.debugln("known style page looted: %s", itemLink)
                    end
                end
			
            -- Scribing Scripts 			
			elseif IsScribingEnabled() and GetItemLinkItemUseType(itemLink) == ITEM_USE_TYPE_CRAFTED_ABILITY_SCRIPT then
                if PALootSavedVars.LootEvents.LootStyles.unknownScribingScriptMsg or PALootSavedVars.LootEvents.LootStyles.autoLearnScribingScript then
					local isKnown = PAHF.IsScribingScriptKnown(itemLink)
 					if not isKnown then
 					    if PALootSavedVars.LootEvents.LootStyles.unknownScribingScriptMsg then
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     PAL.println(SI_PA_CHAT_LOOT_SCRIBING_SCRIPT_UNKNOWN, itemLink)
                                 end
                             else
                                 PAL.println(SI_PA_CHAT_LOOT_SCRIBING_SCRIPT_UNKNOWN, itemLink)
                             end
 						end
					
                        if PALootSavedVars.LootEvents.LootStyles.autoLearnScribingScript then -- auto learn scribing script
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     learnNowOrLater(bagId, slotIndex)
                                 end
                             else
                                 learnNowOrLater(bagId, slotIndex)
                             end
 						end
 					else
					    -- Scribing Script already known
                        PAL.debugln("known scribing script looted: %s", itemLink)
						if PALootSavedVars.LootEvents.LootStyles.autoMarkAsJunkScribingScript then
						     tryToMarkAsJunk(bagId, slotIndex) -- hereherehere
						end
					end
			    end 
				
			-- Scribing Grimoires			
			elseif IsScribingEnabled() and GetItemLinkItemUseType(itemLink) == ITEM_USE_TYPE_CRAFTED_ABILITY then
                if PALootSavedVars.LootEvents.LootStyles.unknownScribingScriptMsg or PALootSavedVars.LootEvents.LootStyles.autoLearnScribingScript then
                    local isKnown = PAHF.IsScribingGrimoireKnown(itemLink)
 					if not isKnown then
 					    if PALootSavedVars.LootEvents.LootStyles.unknownScribingScriptMsg then
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     PAL.println(SI_PA_CHAT_LOOT_SCRIBING_SCRIPT_UNKNOWN, itemLink)
                                 end
                             else
                                 PAL.println(SI_PA_CHAT_LOOT_SCRIBING_SCRIPT_UNKNOWN, itemLink)
                             end
 						end
 						if PALootSavedVars.LootEvents.LootStyles.autoLearnScribingGrimoire then -- auto learn scribing grimoire
                             if PA.Libs.CharacterKnowledge.IsInstalled() and PA.Libs.CharacterKnowledge.IsEnabled() then
                                 if PA.Libs.CharacterKnowledge.DoesCharacterNeed(itemLink) then
                                     learnNowOrLater(bagId, slotIndex)
                                 end
                             else
                                 learnNowOrLater(bagId, slotIndex)
                             end
 						end
 					else
					    -- Scribing Script already known; do nothing for know
                        PAL.debugln("known scribing grimoire looted: %s", itemLink)
						if PALootSavedVars.LootEvents.LootStyles.autoMarkAsJunkScribingGrimoire then
						     tryToMarkAsJunk(bagId, slotIndex) -- hereherehere
						end
					end
			    end
 				
			-- Auto common fish filleting	
			elseif PALootSavedVars.LootEvents.Fishing.AutoFillet and itemType == ITEMTYPE_FISH  then 
			       local itemQuality = GetItemFunctionalQuality(bagId, slotIndex)
				   
			       if itemQuality == ITEM_FUNCTIONAL_QUALITY_NORMAL then 
				       zo_callLater(function()  CallSecureProtected("UseItem", bagId, slotIndex) end, 1000)
					   PAL.println(SI_PA_CHAT_LOOT_AUTO_FILLET, itemLink)
				   end
				   
			-- Auto assemble collectibles	    
			elseif PALootSavedVars.LootEvents.Collectibles.AutoCombine and (itemUseType == ITEM_USE_TYPE_COMBINATION or
			       specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_RUNEBOX_FRAGMENT or specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_RECIPE_FRAGMENT or
				   specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_UPGRADE_FRAGMENT or specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_KEY_FRAGMENT  or
				   specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_COLLECTIBLE_FRAGMENT)then
				   
                local combinationId = GetItemCombinationId(bagId, slotIndex) -- always return 0 so this doesn't work
				local numComponents = GetCombinationNumCollectibleComponents(combinationId)
				local numUnlockedComponents = GetCombinationNumUnlockedCollectibles(combinationId)

				
				local collectibleId = GetCombinationCollectibleComponentId(combinationId, 1)
                --d(GetItemName(bagId, slotIndex).." id "..combinationId.." components "..numUnlockedComponents.." / "..numComponents)
				if not IsCollectibleUnlocked(collectibleId) and combinationId ~= 0 then
					PAL.combineNowOrLater(bagId, slotIndex) 
				end
            end

            -- after all itemTypes are checked, see how much space is left in bag (only if usedSlots has increased)
            if usedSlots > _prevUsedSlots and PALootSavedVars.InventorySpace.lowInventorySpaceWarning then
                local freeSlots = GetNumBagFreeSlots(BAG_BACKPACK)
                local formatted = zo_strformat(GetString(SI_PA_PATTERN_INVENTORY_COUNT), freeSlots)
                local lowInventorySpaceThreshold = PALootSavedVars.InventorySpace.lowInventorySpaceThreshold

                if freeSlots == 0 then
                    -- if no free slots, have a orange-red message
                    PAL.println(formatted, PAC.COLORS.ORANGE_RED, PAC.COLORS.ORANGE_RED)
                elseif freeSlots <= lowInventorySpaceThreshold then
                    if freeSlots <= 5 then
                        -- if at or below 5 free slots, have a orange message
                        PAL.println(formatted, PAC.COLORS.ORANGE, PAC.COLORS.ORANGE)
                    else
                        -- in all other cases, have a yellow message
                        PAL.println(formatted, PAC.COLORS.DEFAULT, PAC.COLORS.DEFAULT)
                    end
                end
            end
        end

       -- update the stored number of previously used slots
       _prevUsedSlots = usedSlots end
end


-- update the number of used stacks in case player does stack all items in backpack (or if items are sold)
-- this is checked with a 100ms interval after the event was triggered. It will repeatedly try it until the number
-- has changed or until the timeout has been reached
local function UpdateNumBagUsedSlots(eventCode)
    -- before starting make sure any already registered UpdateEvent is unregistered to not run them in parallel
    local identifier = _getUniqueUpdateIdentifier()
    EVENT_MANAGER:UnregisterForUpdate(identifier)
    local startGameTime = GetGameTimeMilliseconds()
    local beforeUsedSlots = _prevUsedSlots
    EVENT_MANAGER:RegisterForUpdate(identifier, GET_NUM_BAG_USED_SLOTS_INTERVAL_MS,
        function()
            local nowUsedSlots = GetNumBagUsedSlots(BAG_BACKPACK)
            local passedGameTime = GetGameTimeMilliseconds() - startGameTime
            if nowUsedSlots ~= beforeUsedSlots or passedGameTime > GET_NUM_BAG_USED_SLOTS_TIMEOUT_MS then
                EVENT_MANAGER:UnregisterForUpdate(identifier)
                PAL.debugln('UpdateNumBagUsedSlots took approx. %d ms (%d -> %d)', passedGameTime, _prevUsedSlots, nowUsedSlots)
                _prevUsedSlots = nowUsedSlots
            end
        end)
end

local function ShowInventoryFragment()
    SCENE_MANAGER:GetScene('gameMenuInGame'):AddFragment(INVENTORY_FRAGMENT)
    SCENE_MANAGER:GetScene('gameMenuInGame'):AddFragment(RIGHT_PANEL_BG_FRAGMENT)
end

local function HideInventoryFragment()
    SCENE_MANAGER:GetScene('gameMenuInGame'):RemoveFragment(INVENTORY_FRAGMENT)
    SCENE_MANAGER:GetScene('gameMenuInGame'):RemoveFragment(RIGHT_PANEL_BG_FRAGMENT)
end


-- =====================================================================================================================
-- Export
PA.Loot = PA.Loot or {}
PA.Loot.TraitIndexFromItemTraitType = TraitIndexFromItemTraitType
PA.Loot.isTraitBeingResearched = isTraitBeingResearched
PA.Loot.OnInventorySingleSlotUpdate = OnInventorySingleSlotUpdate
PA.Loot.UpdateNumBagUsedSlots = UpdateNumBagUsedSlots
PA.Loot.ShowInventoryFragment = ShowInventoryFragment
PA.Loot.HideInventoryFragment = HideInventoryFragment
PA.Loot.learnNowOrLater = learnNowOrLater
PA.Loot.combineNowOrLater = combineNowOrLater
