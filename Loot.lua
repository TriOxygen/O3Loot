local addon, ns = ...
local O3 = O3

local Loot = O3.UI.ItemListWindow:extend({
	name = 'O3LootWindow',
	titleText = 'Loot',
	frameStrata = 'HIGH',
	width = 250,
	offset = {100, nil, 100, nil},
	itemCount = 10,
	settings = {
		itemHeight = 32,
		itemsTopGap = 0,
		itemsBottomGap = 0,
	},
	updateItem = function (self, item, slot)
		item.slot = slot
		local texture, name, quantity, quality, locked = GetLootSlotInfo(slot)
		if not texture then
			item:hide()
		else
			item:show()
		end
		quantity = quantity or 0
		if quantity < 2 then
			quantity = ''
		end
		local slotType = GetLootSlotType(slot)
		if(slotType == LOOT_SLOT_MONEY) then
			name = name:gsub("\n", ", ")
		end
		item.button:setTexture(texture)
		item.text:SetText(name)
		item.count:SetText(quantity or '')
		item.locked = locked
		item.quality = quality
		local r, g, b, hex = GetItemQualityColor(quality or 0)
		item.bg:SetVertexColor(r, g, b, 0.6)
		item.bg:SetTexture(r, g, b, 0.6)

	end,
	createItem = function (self)
		local itemHeight = self.settings.itemHeight
		local item = self.content:createPanel({
			type = 'Button',
			offset = {2, 2, nil, nil},
			height = itemHeight,
			createRegions = function (self)
				self.button = O3.UI.IconButton:instance({
					parent = self,
					icon = nil,
					parentFrame = self.frame,
					height = itemHeight,
					width = itemHeight,
					onClick = function (self)
						if (self.parent.onIconClick) then
							self.parent:onIconClick()
						end
					end,
					createRegions = function (self)
						self.count = self:createFontString({
							offset = {2, nil, 2, nil},
							fontFlags = 'OUTLINE',
							text = nil,
							-- shadowOffset = {1, -1},
							fontSize = 12,
						})
					end,
				})
				self.button:point('TOPLEFT')
				self.bg = self:createTexture({
					layer = 'BACKGROUND',
					subLayer = 0,
					color = {0, 0, 0, 0.95},
					-- offset = {0, 0, 0, nil},
					-- height = 1,
				})
				self.panel = self:createPanel({
					offset = {itemHeight+2, 0, 0, 0},
					style = function (self)
				
						self.text = self:createFontString({
							offset = {2, 2, 2, nil},
							height = 12,
							justifyV = 'MIDDLE',
							justifyH = 'LEFT',
						})
						self:createOutline({
							layer = 'BORDER',
							gradient = 'VERTICAL',
							color = {1, 1, 1, 0.03 },
							colorEnd = {1, 1, 1, 0.05 },
							offset = {0, 0, 0, 0},
							-- width = 2,
							-- height = 2,
						})	
						self.highlight = self:createTexture({
							layer = 'ARTWORK',
							gradient = 'VERTICAL',
							color = {0,1,1,0.10},
							colorEnd = {0,0.5,0.5,0.20},
							offset = {1,1,1,1},
						})
						self.highlight:Hide()						
					end,
				})

				self.bottomText = self.panel.bottomText
				self.text = self.panel.text
				self.count = self.button.count
			end,
			hook = function (self)
				self.frame:SetScript('OnEnter', function (frame)
					self.panel.highlight:Show()

					if(GetLootSlotType(self.slot) == LOOT_SLOT_ITEM) then
						GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
						GameTooltip:SetLootItem(self.slot)
						CursorUpdate(frame)
					end

					
					if (self.onEnter) then
						self:onEnter()
					end
				end)
				self.frame:SetScript('OnLeave', function (frame)
					GameTooltip:Hide()
					ResetCursor()

					self.panel.highlight:Hide()
					if (self.onLeave) then
						self:onLeave()
					end
				end)
				self.frame:SetScript('OnClick', function (frame)
					LootSlot(self.slot)
					if (self.onClick) then
						self:onClick()
					end
				end)
			end,
			onIconClick = function (self)
				LootSlot(self.slot)
			end,			
		})
		return item
	end,	
	getNumItems = function (self)
		self.numItems = GetNumLootItems()
	end,
	loot = function (self, slotIndex)
		local slot = tonumber(slotIndex)
		for i = 1, self.itemCount do
			local item = self.items[i]
			if slot == item.slot then
				item:hide()
				break
			end
		end
		-- self:clear()
		-- self:populate()
	end,
})

O3:module({
	name = 'Loot',
	readable = 'Loot window',
	lootOpen = false,
	freeRolls = {},
	activeRolls = {},
	config = {
		enabled = true,
        font = O3.Media:font('Normal'),
        fontSize = 12,
        fontStyle = 'THINOUTLINE',
        autoLoot = false,
		xOffset = 0,
		yOffset = 100,
		anchor = 'CENTER',
		anchorTo = 'CENTER',
	},        
	events = {
		LOOT_OPENED = true,
		LOOT_CLOSED = true,
		LOOT_SLOT_CLEARED = true,
		START_LOOT_ROLL = true,
		PLAYER_ENTERING_WORLD = true,
	},
	settings = {
		rolls = {},
	},
	addOptions = function (self)
        self:addOption('_0', {
            type = 'Title',
            label = 'Options',
        })
        self:addOption('autoLoot', {
            type = 'Toggle',
            label = 'Auto loot',
        })
        self:addOption('_1', {
            type = 'Title',
            label = 'Font',
        })
        self:addOption('font', {
            type = 'FontDropDown',
            label = 'Font',
        })
        self:addOption('fontSize', {
            type = 'Range',
            min = 6,
            max = 20,
            step = 1,
            label = 'Font size',
        })

        self:addOption('fontStyle', {
            type = 'DropDown',
            label = 'Outline',
            _values = O3.Media.fontStyles,
        })
        self:addOption('_2', {
        	type = 'Title',
        	label = 'Loot Roll'
        })
        self:addOption('anchor', {
            type = 'DropDown',
            label = 'Point',
            setter = 'anchorSet',
            _values = O3.UI.anchorPoints
        })
        self:addOption('anchorTo', {
            type = 'DropDown',
            label = 'To Point',
            setter = 'anchorSet',
            _values = O3.UI.anchorPoints
        })        
		self:addOption('xOffset', {
			type = 'Range',
			label = 'Horizontal',
			setter = 'anchorSet',
			bag = self,
			min = -500,
			max = 500,
			step = 5,
		})
		self:addOption('yOffset', {
			type = 'Range',
			label = 'Vertical',
			setter = 'anchorSet',
			min = -500,
			max = 500,
			step = 5,
		})		

	end,
	anchorSet = function (self)
		self.lootRollFrame:point(self.settings.anchor, UIParent, self.settings.anchorTo, self.settings.xOffset, self.settings.yOffset)
	end,
	createLootRollFrame = function (self)
		O3:destroy(LootFrame)
		self.lootWindow = Loot:new()
		self.lootRollFrame = O3.UI.Panel:instance({
			width = 400,
			height = 20,
		})
		self:anchorSet()
		UIParent:UnregisterEvent("START_LOOT_ROLL")
		UIParent:UnregisterEvent("CANCEL_LOOT_ROLL")

	end,
	autoLoot = function (self)
		local items = GetNumLootItems()
		if(items > 0) then
			for i=1, items do
				LootSlot(i)
			end
		end
	end,
	LOOT_OPENED = function (self)
		self.lootOpen = true
		self.lootWindow:show()
		if(IsFishingLoot()) then
			self.lootWindow:setTitle('Fish')
		elseif(not UnitIsFriend("player", "target") and UnitIsDead("target")) then
			self.lootWindow:setTitle(UnitName("target"))
		else
			self.lootWindow:setTitle(LOOT)
		end		

		self.lootWindow:scrollTo(0)
		if (self.settings.autoLoot and not IsShiftKeyDown()) then
			self:autoLoot()
		end
	end,
	LOOT_CLOSED = function (self)
		self.lootOpen = false
		self.lootWindow:hide()
	end,
	reanchorRolls = function (self)
		local lastRoll = nil
		for id, roll in pairs(self.activeRolls) do
			roll.frame:ClearAllPoints()
			if (lastRoll) then
				roll.frame:SetPoint('TOP', lastRoll, 'BOTTOM', 0, -5)
			else
				roll.frame:SetPoint('TOP', self.lootRollFrame.frame, 'TOP', 0, -5)
			end
			lastRoll = roll.frame
		end
	end,
	freeRoll = function (self, id)
		local roll = self.activeRolls[id]
		if not roll then
			return
		end
		roll:hide()
		self.activeRolls[id] = nil
		table.insert(self.freeRolls, roll)
		self.settings.rolls[roll.id] = nil
		self:reanchorRolls()
	end,
	getFreeRoll = function (self)
		if (#self.freeRolls > 0) then
			local roll = self.freeRolls[1]
			table.remove(self.freeRolls, 1)
			
			return roll
		else
			local roll = ns.Roll:new({
				parentFrame = self.lootRollFrame
			})
			roll:register(self)
			return roll
		end
	end,
	LOOT_SLOT_CLEARED = function (self, slot)
		if (self.lootOpen) then
			self.lootWindow:loot(slot)
		end
	end,
	LOOT_SLOT_CHANGED = function (self)
		self:LOOT_OPENED()
	end,
	PLAYER_ENTERING_WORLD = function (self)
		if not self.initialized then
			self.initialized = true
			self:createLootRollFrame()
		end
		local now = GetTime()
		for id, expires in pairs(self.settings.rolls) do
			if expires and expires < now then
				self.settings.rolls[id] = nil
			else
				self:START_LOOT_ROLL(id, (expires-GetTime())*1000)
			end
		end

		-- for i = 6, 9 do
		-- 	self:START_LOOT_ROLL(i, 300*1000)
		-- end

	end,
	START_LOOT_ROLL = function (self, id, time)
		local roll = self:getFreeRoll()
		self.settings.rolls[id] = GetTime() + (time/1000)
		roll:set(id, time)
		roll:start()
		self.activeRolls[id] = roll
		self:reanchorRolls()

	end,

})