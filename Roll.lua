local addon, ns = ...
local O3 = O3

local Roll = O3.UI.Panel:extend({
	height = 32,
	width = 300,
	statusBarTexture = O3.Media:statusBar('Default'),
	set = function (self, id, time)
		local secs = time/1000
		self.id = id
		self.expires = GetTime()+secs
		self.statusBar.frame:SetMinMaxValues(0, secs)
		local texture, name, quantity, quality, bindOnPickUp, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(id)

		quantity = quantity or 0
		if quantity < 2 then
			quantity = ''
		end

		if canNeed then
			self.needControl:enable()
		else
			self.needControl:disable()
		end

		if canGreed then
			self.greedControl:enable()
		else
			self.greedControl:disable()
		end

		if canDisenchant then
			self.disenchantControl:enable()
		else
			self.disenchantControl:disable()
		end

		self.button:setTexture(texture)
		self.name:SetText(name)
		self.count:SetText(quantity or '')
		self.locked = locked
		self.quality = quality
		local r, g, b, hex = GetItemQualityColor(quality or 0)
		self.color.r = r
		self.color.g = g
		self.color.b = b
		self.statusBar.frame:SetStatusBarColor(r,g,b,1)

	end,
	preInit = function (self)
		self.color = {}
	end,
	hook = function (self)
		self.frame:SetScript('OnEnter', function (frame)
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			GameTooltip:SetLootRollItem(self.id)
			CursorUpdate(frame)
		end)

		self.frame:SetScript('OnLeave', function (frame)
			GameTooltip:Hide()
			ResetCursor()			
		end)
		self.frame:SetScript('OnUpdate', function (frame)
			self.statusBar.frame:SetValue(self.expires-GetTime())
		end)		
	end,
	style = function (self)
		self.bg = self:createTexture({
			layer = 'BACKGROUND',
			subLayer = 0,
			color = {0, 0, 0, 0.95},
			-- offset = {0, 0, 0, nil},
			-- height = 1,
		})	
		self:createOutline({
			layer = 'BORDER',
			gradient = 'VERTICAL',
			color = {1, 1, 1, 0.03 },
			colorEnd = {1, 1, 1, 0.05 },
			offset = {1, 1, 1, 1},
			-- width = 2,
			-- height = 2,
		})	
	end,
	createRegions = function (self)
		self.button = O3.UI.IconButton:instance({
			parent = self,
			icon = nil,
			offset = {0, nil, 0, nil},
			parentFrame = self.frame,
			height = self.height,
			width = self.height,
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
		self.statusBar = self:createPanel({
			type = 'StatusBar',
			offset = {self.height+1, 1, 2, 2},
			style = function (self)
		
				self.name = self:createFontString({
					offset = {2, 2, 2, nil},
					height = 12,
					justifyV = 'MIDDLE',
					justifyH = 'LEFT',
					shadow = {1, -1},
				})
				-- self.highlight = self:createTexture({
				-- 	layer = 'ARTWORK',
				-- 	gradient = 'VERTICAL',
				-- 	color = {0,1,1,0.10},
				-- 	colorEnd = {0,0.5,0.5,0.20},
				-- 	offset = {1,1,1,1},
				-- })
			end,
		})
		self.statusBar.frame:SetStatusBarTexture(O3.Media:statusBar('Default'))

		local index = 1
		local width = 50
		self.disenchantControl = O3.UI.Button:instance({
			parentFrame = self.frame,
			offset = {nil, -1*(1+index*(width)), 0, 0},
			color = {0.8, 0.2, 0.8, 1},
			width = width,
			text = 'D/E',
			onClick = function ()
				ConfirmLootRoll(self.id,3)
				self:free()
			end,
		})
		index = index + 1
		self.needControl = O3.UI.Button:instance({
			parentFrame = self.frame,
			offset = {nil, -1*(1+index*(width)), 0, 0},
			color = {0.2, 0.8, 0.2, 1},
			text = 'Need',
			width = width,
			onClick = function ()
				ConfirmLootRoll(self.id,1)
				self:free()
			end,
		})
		index = index + 1
		self.greedControl = O3.UI.Button:instance({
			parentFrame = self.frame,
			offset = {nil, -1*(1+index*(width)), 0, 0},
			color = {0.8, 0.8, 0.2, 1},
			text = 'Greed',
			width = width,
			onClick = function ()
				ConfirmLootRoll(self.id,2)
				self:free()
			end,
		})
		index = index + 1
		self.needControl = O3.UI.Button:instance({
			parentFrame = self.frame,
			offset = {nil, -1*(1+index*(width)), 0, 0},
			color = {0.8, 0.2, 0.2, 1},
			width = width,
			text = 'Pass',
			onClick = function ()
				ConfirmLootRoll(self.id,0)
				self:free()
			end,
		})

		self.name = self.statusBar.name
		self.count = self.button.count
	end,
	postInit = function (self)
		self.color = {}
		self.frame:EnableMouse(true)

	end,
	hide = function (self, ...)
		self.frame:Hide()
	end,
	show = function (self)
		self.frame:Show()
	end,
	point = function (self, ...)
		self.frame:SetPoint(...)
	end,
	start = function (self)
		self.frame:Show()
	end,
	register = function (self, handler)
		self.handler = handler
	end,
	free = function (self)
		self.handler:freeRoll(self.id)
	end,
})

ns.Roll = Roll