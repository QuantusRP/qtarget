function Load(name)
	local resourceName = GetCurrentResourceName()
	local chunk = LoadResourceFile(resourceName, ('data/%s.lua'):format(name))
	if chunk then
		local err
		chunk, err = load(chunk, ('@@%s/data/%s.lua'):format(resourceName, name), 't')
		if err then
			error(('\n^1 %s'):format(err), 0)
		end
		return chunk()
	end
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

Config = {}

-- It's possible to interact with entities through walls so this should be low
Config.MaxDistance = 7.0

-- Enable debug options and distance preview
Config.Debug = false

-- Supported values: ESX, QB, vRP, false
Config.Framework = false

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
local function JobCheck() return true end
local function GangCheck() return true end
local function ItemCount() return true end
local function CitizenCheck() return true end

CreateThread(function()
	if not Config.Framework then
		local framework = 'es_extended'
		local state = GetResourceState(framework)

		if state == 'missing' then
			framework = 'qb-core'
			state = GetResourceState(framework)
		elseif state == 'missing' then
			framework = 'vrp'
			state = GetResourceState(framework)
		end

		if state ~= 'missing' then
			if state ~= ('started' or 'starting') then
				local timeout = 0
				repeat
					Wait(0)
					timeout += 1
				until (GetResourceState(framework) == 'started' or timeout > 100)
			end
			Config.Framework = (framework == 'es_extended') and 'ESX' or 'QB' or 'vRP'
		end
	end

	if Config.Framework == 'ESX' then
		local ESX = exports['es_extended']:getSharedObject()

		if GetResourceState('ox_inventory') ~= 'unknown' then
			ItemCount = function(item)
				return exports.ox_inventory:Search(2, item)
			end
		else
			ItemCount = function(item)
				for _, v in pairs(ESX.GetPlayerData().inventory) do
					if v.name == item then
						return v.count
					end
				end
				return 0
			end
		end

		JobCheck = function(job)
			if type(job) == 'table' then
				job = job[ESX.PlayerData.job.name]
				if job and ESX.PlayerData.job.grade >= job then
					return true
				end
			elseif job == ESX.PlayerData.job.name then
				return true
			end
			return false
		end

		RegisterNetEvent('esx:playerLoaded', function(xPlayer)
			ESX.PlayerData = xPlayer
		end)

		RegisterNetEvent('esx:setJob', function(job)
			ESX.PlayerData.job = job
		end)

		RegisterNetEvent('esx:onPlayerLogout', function()
			table.wipe(ESX.PlayerData)
		end)

	elseif Config.Framework == 'QB' then
		local QBCore = exports['qb-core']:GetCoreObject()
		local PlayerData = QBCore.Functions.GetPlayerData()

		ItemCount = function(item)
			for _, v in pairs(PlayerData.items) do
				if v.name == item then
					return v.amount
				end
			end
			return 0
		end

		JobCheck = function(job)
			if type(job) == 'table' then
				job = job[PlayerData.job.name]
				if PlayerData.job.grade >= job then
					return true
				end
			elseif job == (PlayerData.job.name or 'all') then
				return true
			end
			return false
		end

		GangCheck = function(gang)
			if type(gang) == 'table' then
				gang = gang[PlayerData.gang.name]
				if PlayerData.gang.grade >= gang then
					return true
				end
			elseif gang == (PlayerData.gang.name or 'all') then
				return true
			end
			return false
		end

		CitizenCheck = function(citizenid)
			return (citizenid == PlayerData.citizenid or citizenid[PlayerData.citizenid])
		end

		RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
			PlayerData = QBCore.Functions.GetPlayerData()
		end)

		RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
			table.wipe(PlayerData)
		end)

		RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
			PlayerData.job = JobInfo
		end)

		RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
			PlayerData.gang = GangInfo
		end)

		RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
			PlayerData = val
		end)
			
	elseif Config.Framework == 'vRP' then
		local Tunnel = module("vrp", "lib/Tunnel")
		local Proxy = module("vrp", "lib/Proxy")

		vRP = Proxy.getInterface("vRP")

		local PlayerData = vRP.getUserId({source})

		ItemCount = function(user_id, idname)
			local data = vRP.getUserDataTable({user_id})
			for _, v in pairs(data.inventory) do
				if v.name == idname then
					return v.amount
				end
			end
			return 0
		end

		JobCheck = function(job)
			if type(job) == 'table' then
				job = job[vRP.hasGroup({PlayerData, job})]
				if vRP.hasPermission({PlayerData, grade}) >= job then
					return true
				end
			elseif job == (vRP.hasGroup({PlayerData, job}) or 'all') then
				return true
			end
			return false
		end
	end

	function CheckOptions(data, entity, distance)
		if data.distance and distance > data.distance then return false end
		if data.job and not JobCheck(data.job) then return false end
		if data.gang and not GangCheck(data.gang) then return false end
		if data.item and ItemCount(data.item) < 1 then return false end
		if data.citizenid and not CitizenCheck(data.citizenid) then return false end
		if data.canInteract and not data.canInteract(entity, distance, data) then return false end
		return true
	end
end)
