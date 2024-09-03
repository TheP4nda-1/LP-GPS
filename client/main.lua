Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(0)
    end
    startAction()
end)

local gpsTrackers = {}
local Periode = Config.Periode
local TrackerDeleteTime = Config.TrackerDeleteTime  -- Zeit in Millisekunden (standardmäßig 60 Sekunden)
local ActivationRadius = Config.ActivationRadius -- Aktivierungsradius in Metern (standardmäßig 3 Meter)
local zeroCoords = vector3(0.0, 0.0, 0.0)
local resourceName = GetCurrentResourceName()

function startAction()
    -- Initialisierungsnachricht
    print("^3".. " ^6------------------------------" .."")
    print("^6|".. "^3 LP_GPS_Tracker  " .."^6             |")
    print("^6|".. "^6------------------------------" .."^6|")
    print("^6|".. "^3 By TheP4nda     " .."^6             |")
    print("^6|".. "^3 "..GetResourceMetadata(resourceName, 'version', 0).."           " .."^6             |")
    print("^3".. " ^6------------------------------" .."")
    print("^6|".. "^3 Periode:  ".. Periode .."   ".."^6             |")
    print("^6|".. "^3 Löschen nach: ".. TrackerDeleteTime / 1000 .." Sekunden" .."^6  |")
    print("^6|".. "^3 Aktivierungsradius: ".. ActivationRadius .." Meter" .."^6|")
    print("^3".. " ^6------------------------------" .."")
end
RegisterCommand("test",function ()
    ESX.ShowNotification(string.format(Config.Locale.delete, 10))
end, false)


RegisterNetEvent('gpstracker:used')
AddEventHandler('gpstracker:used', function(playerPed)
    local trackerID = nil

    -- Suche nach der ersten freien ID
    for i = 1, 5 do
        if gpsTrackers[i] == nil then
            trackerID = i
            break
        end
    end

    -- Wenn keine freie ID gefunden wurde
    if trackerID == nil then
        
        ESX.ShowNotification(Config.Locale.allUsed, flash, saveToBrief, hudColorIndex)
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = ESX.Game.GetClosestVehicle(playerCoords)
    local vehicleCoords = GetEntityCoords(closestVehicle)
    local distance = #(playerCoords - vehicleCoords)

    -- Überprüfe, ob der Spieler innerhalb des Aktivierungsradius ist
    if distance > ActivationRadius then
        
        ESX.ShowNotification(string.format(Config.Locale.tofar, ActivationRadius), flash, saveToBrief, hudColorIndex)
        return
    end
    
    -- Speichere die Tracker-Daten in der entsprechenden ID
    gpsTrackers[trackerID] = {
        vehicle = closestVehicle,
        blip = nil,
        startTime = GetGameTimer() -- Zeitpunkt der Aktivierung
    }

    
    ESX.ShowNotification(string.format(Config.Locale.active, trackerID), flash, saveToBrief, hudColorIndex)
    TriggerServerEvent("Tracker", closestVehicle, trackerID)
end)

Citizen.CreateThread(function()
    while true do
        for trackerID, tracker in pairs(gpsTrackers) do
            if tracker.vehicle then
                local vehicleCoords = GetEntityCoords(tracker.vehicle)

                -- Überprüfe, ob das Fahrzeug nicht verschwunden ist
                if not DoesEntityExist(tracker.vehicle) then
                    
                    ESX.ShowNotification(string.format(Config.Locale.notexist, trackerID), flash, saveToBrief, hudColorIndex)
                    -- Blip löschen und Tracker resetten
                    if tracker.blip then
                        RemoveBlip(tracker.blip)
                    end
                    gpsTrackers[trackerID] = nil
                else
                    -- Überprüfe, ob die Zeit abgelaufen ist
                    if GetGameTimer() - tracker.startTime > TrackerDeleteTime then
                        
                        ESX.ShowNotification(string.format(Config.Locale.noTime, trackerID), flash, saveToBrief, hudColorIndex)
                        if tracker.blip then
                            RemoveBlip(tracker.blip)
                        end
                        gpsTrackers[trackerID] = nil
                    else
                        if not tracker.blip then
                            if vehicleCoords ~= zeroCoords then
                                -- Erstelle einen neuen Blip für den Tracker
                                tracker.blip = AddBlipForCoord(vehicleCoords)
                                SetBlipSprite(tracker.blip, 1)
                                SetBlipScale(tracker.blip, 0.8)
                                SetBlipColour(tracker.blip, 44)
                                SetBlipDisplay(tracker.blip, 4)
                                SetBlipAsShortRange(tracker.blip, true)
                            
                                BeginTextCommandSetBlipName("STRING")
                                AddTextComponentString("GPS-Tracker " .. trackerID)
                                EndTextCommandSetBlipName(tracker.blip)
                            
                                ESX.Streaming.RequestAnimDict("mp_car_bomb", function()
                                    TaskPlayAnim(ESX.PlayerData.ped, "mp_car_bomb", "car_bomb_mechanic", 8.0, -8.0, -1, 0, 0.0, false, false, false)
                                    RemoveAnimDict("mp_car_bomb")
                                end)
                            end
                        else
                            -- Aktualisiere die Position des Blips
                            if vehicleCoords == zeroCoords then
                                RemoveBlip(tracker.blip)
                                gpsTrackers[trackerID].blip = nil
                                
                                ESX.ShowNotification(string.format(Config.Locale.deleteBlip, trackerID), flash, saveToBrief, hudColorIndex)
                            else
                                SetBlipCoords(tracker.blip, vehicleCoords)
                            end
                        end
                    end
                end
            end
        end

        Citizen.Wait(Periode)
    end
end)
