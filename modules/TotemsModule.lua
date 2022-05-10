local allTotemIds = 
{
	58774,   -- Mana Spring Totem
    58757,   -- Healing Stream Totem
    8170,    -- Cleansing Totem
    8143,    -- Tremor Totem
    6495,    -- Sentry Totem
    3738,    -- Wrath of Air Totem
    8177,    -- Grounding Totem
    58745,   -- Frost Resistance Totem
    58749,   -- Nature Resistance Totem
    58753,   -- Stoneskin Totem
    8512,    -- Windfury Totem
    58643,   -- Strenght of Earth Totem
    2062,    -- Earth Elemental Totem
    58656,   -- Flametounge Totem
    58704,   -- Searing Totem
    58582,   -- Stoneclaw Totem
    58734,   -- Magma Totem
    2484,    -- Earthbind Totem
    2894,    -- Fire Elemental Totem
    16190,   -- Mana Tide Totem (Restoration Shamans)
    58739,   -- Fire Resistance Totem
    57722,   -- Totem of Wrath
}

local moduleName = "Totems"
local AceAddon = LibStub("AceAddon-3.0");
local LibLogger = LibStub("LibLogger-1.0");
local LibNameplate = LibStub("LibNameplate-1.0");

local addon = AceAddon:GetAddon("PlatesClasses");
local module = addon:NewModule(moduleName);
local log = LibLogger:New(module);
local Utils = addon.Utils;

function module:OnInitialize()
	self.totems = 
	{
		--[key] = { spellId, icon, name }
	}
	for i = 1, #allTotemIds do
		local spellId = allTotemIds[i];
		local info = {GetSpellInfo(spellId)};
		local name = info[1];
		local icon = info[3];
		local key = self:GetNameKey(name)
		self.totems[key] = {name = name, spellId = spellId, icon = icon};
	end

	hooksecurefunc(addon, "UpdateFrameAppearence", function(this, ...) self:OnUpdateFrameAppearence(...) end);
end

function module:OnEnable()
	addon:UpdateAllNameplates()
end

function module:OnDisable()
	addon:UpdateAllNameplates()
end

function module:GetNameKey(name)
	return string.sub(name, 0, 8);
end

function module:OnUpdateFrameAppearence(nameplateFrame, settings)
	if self:IsEnabled() ~= true then
		return;
	end
	
	if settings == self.db.IconSettings then 
		return; -- avoid cycle
	end
	
	if nameplateFrame.targetName ~= nil then
		local key = self:GetNameKey(nameplateFrame.targetName);
		local info = self.totems[key];
		
		if info ~= nil then
			if self.db.DisplayTotems[info.name] then
				addon:UpdateFrameAppearence(nameplateFrame, self.db.IconSettings);
				
				nameplateFrame:Show();
				SetPortraitToTexture(nameplateFrame.classTexture, info.icon);
				nameplateFrame.classTexture:SetTexCoord(0.075, 0.925, 0.075, 0.925);
				nameplateFrame.classBorderTexture:Hide();
			end
		end
		
	end
end

function module:GetDbMigrations()
	local modules = {}
	
	modules[1] = function(db)
		db.Enabled = true;
		db.DisplayTotems = 
		{
			["Tremor Totem"] = true,
			["Cleansing Totem"] = true,
		};
		db.IconSettings = addon:GetDefaultNameplateIconSettings();
	end
	
	return modules;
end

function module:AddTotemsListOptions(options, dbConnection, iterator)
	options.args["TotemsListDesciptionSpace"] = 
	{
		type = "description",
		name = " ",
		fontSize = "large",
		order = iterator()
	}
	
	options.args["TotemsListDesciption"] = 
	{
		type = "description",
		name = "Totems to display:",
		fontSize = "large",
		order = iterator()
	}
	
	for totemKey, totemInfo in pairs(self.totems) do
		options.args[totemInfo.name] = 
		{
			type = "toggle",
			name = totemInfo.name,
			image = totemInfo.icon,
			desc = "",
			get = dbConnection.Get,
			set = dbConnection:BuildSetter(function(newState) addon:UpdateAllNameplates(); end),
			order = iterator()
		}
	end
end

function module:BuildBlizzardOptions()
	local dbConnection = Utils.DbConfig:New(function(key) return self.db end);
	local iterator = Utils.Iterator:New();
	
	local options = 
	{
		type = "group",
		name = module.moduleName,
		get = dbConnection.Get,
		set = dbConnection:BuildSetter( function(newState) addon:UpdateAppearence() end),
		childGroups = "tab",
		args = {}
	}
	
	local generalSettingsOptions = 
	{
		type = "group",
		name = "General",
		args = {},
		order = iterator()
	}
	
	generalSettingsOptions.args["Enabled"] = 
	{
		type = "toggle",
		name = "Enabled",
		desc = "",
		set = dbConnection:BuildSetter(function(newState) if newState then module:Enable() else module:Disable() end end),
		order = iterator()
	}
	
	options.args.GeneralSettingsOptions = generalSettingsOptions;
	
	local iconSettingsOptions = 
	{
		type = "group",
		name = "Icon settings",
		args = {},
		order = iterator()
	}
	local iconSettingsDbConnection = Utils.DbConfig:New(function(key) return self.db.IconSettings end, function(key, value) addon:UpdateAppearence() end);
	addon:AddBlizzardOptionsForNameplateIcon(iconSettingsOptions, iconSettingsDbConnection, iterator);
	options.args.IconSettingsOptions = iconSettingsOptions

	local totemListOptions =
	{
		type = "group",
		name = "Totem list",
		args = {},
		order = iterator()
	}
	local totemsDbConnection = Utils.DbConfig:New(function(key) return self.db.DisplayTotems end);
	self:AddTotemsListOptions(totemListOptions, totemsDbConnection, iterator);
	options.args.TotemListOptions = totemListOptions;
	
	return options
end