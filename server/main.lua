-- RegisterCommand('gps', function(source, args, rawCommand)
--     local trackerID = tonumber(args[1])
--     if trackerID == nil or trackerID < 1 or trackerID > 5 then
--         print("Bitte gib eine gültige Tracker-ID (1-5) an.")
--         return
--     end

--     local playerPed = PlayerPedId()
--     local playerCoords = GetEntityCoords(playerPed)
--     local closestVehicle = ESX.Game.GetClosestVehicle(playerCoords)
--     local vehicleCoords = GetEntityCoords(closestVehicle)

--     -- Sende Blip-Daten an alle Clients
--     TriggerClientEvent('example:receiveData', -1, GetNetworkIdFromEntity(closestVehicle), trackerID)
-- end, false)

ESX.RegisterUsableItem(Config.item, function(source)
	TriggerClientEvent('gpstracker:used', source)
end)