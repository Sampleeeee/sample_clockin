function GiveWeapon( hash )
    GiveWeaponToPed( PlayerPedId(), hash, 999, false)
end

function GiveItem( hash )
    GiveWeaponToPed( PlayerPedId(), hash, 1, false, true )
end

function notify( msg )
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(true,false)
end

function AddWeaponComponent( weapon, component )
    local p = PlayerPedId()
    
    if HasPedGotWeapon( p, weapon, false ) then
        GiveWeaponComponentToPed( p, hash, component )
    end
end

RegisterNetEvent( 'sample_clockin:GiveLeoWeapons', function()
    GiveItem( `weapon_fireextinguisher` )
    GiveItem( `WEAPON_FLARE` )       
    GiveWeapon( `weapon_flashlight` )
    GiveWeapon( `weapon_snspistol `)
    GiveWeapon( `weapon_nightstick`)
    GiveWeapon(`weapon_combatpistol`)
    AddWeaponComponent(`weapon_combatpistol`, `component_at_pi_flsh` )
    GiveWeapon( `weapon_stungun` )
    GiveWeapon( `weapon_carbinerifle` )
    AddWeaponComponent (`weapon_carbinerifle`, `component_at_ar_flsh` )
    AddWeaponComponent( `weapon_carbinerifle`, `component_at_scope_medium` )
    AddWeaponComponent( `weapon_carbinerifle`, `component_at_ar_afgrip` )
    GiveWeapon( `weapon_pumpshotgun` )
    AddWeaponComponent( `weapon_pumpshotgun`, `COMPONENT_AT_AR_FLSH` )  
    --ExecuteCommand('setstatus available')
    notify( "You're now on duty." )
    notify( "Please make sure to login to the CAD." )
end )

function IsNearPoliceDepartment( c )
    for i = 1, #CONFIG.PD_LOCATIONS do
        if #( c - CONFIG.PD_LOCATIONS[i] ) < 1 then
            return true
        end
    end

    return false
end

function IsNearFireDepartment( c )
    for i = 1, #CONFIG.FIRE_LOCATIONS do
        if #( c - CONFIG.FIRE_LOCATIONS[i] ) < 1 then
            return true
        end
    end

    return false
end

Citizen.CreateThread( function() 
    while true do
        local p = PlayerPedId()
        local c = GetEntityCoords( p )

        local fire = IsNearFireDepartment( c )
        local police = IsNearPoliceDepartment( c )

        if fire or police then
            LocalPlayer.state.clockin = LocalPlayer.state.clockin or { isLeo = false, isFire = false }
            local state = LocalPlayer.state.clockin
            local clockedin = state and ( state.isLeo or state.isFire )

            --print( json.encode( state ) )

            local text = "a"
            if clockedin then
                if state.isFire and fire then
                    text = "Press ~INPUT_CONTEXT~ to clock off."
                elseif state.isLeo and police then
                    text = "Press ~INPUT_CONTEXT~ to clock off."
                else
                    --print( state.isLeo, police, state.isFire, fire )
                    text = "You cannot clock out here."
                end
            else
                text = "Press ~INPUT_CONTEXT~ to clock in." 
            end

            BeginTextCommandDisplayHelp( "STRING" )
            AddTextComponentSubstringPlayerName( text )
            EndTextCommandDisplayHelp( 0, false, true, 0 )

            if IsControlJustPressed( 0, 51 ) then
                if clockedin then
                    TriggerServerEvent( 'sample_clockin:ClockOut' )
                else
                    TriggerServerEvent( 'sample_clockin:ClockIn', police )
                end
            end
        end

        for k, v in ipairs( CONFIG.PD_LOCATIONS ) do
            if #( c - v ) < 100 then
                DrawMarker( 2, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 0, 200, 222, false, false, false, true, false, false, false )
            end
        end

        for k, v in ipairs( CONFIG.FIRE_LOCATIONS ) do
            if #( c - v ) < 100 then
                DrawMarker( 2, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 100, 100, 255, false, false, false, true, false, false, false )
            end
        end

        Citizen.Wait( 0 )
    end
end )

local blips = {}
RegisterNetEvent( 'sample_clockin:UpdateBlips', function( type, t )
    blips[type] = blips[type] or {}

    -- for k, v in pairs( blips[type] ) do
    --     RemoveBlip( v )
    -- end
    
    for k, v in pairs( t ) do
        if DoesBlipExist( blips[type][k] ) then
            SetBlipCoords( blips[type][k], v.coords.x, v.coords.y, v.coords.z )
        else
            blips[type][k] = AddBlipForCoord( v.coords )
            SetBlipCategory( blips[type][k], 7 )
    
            if type == 'leo' then
                SetBlipColour( blips[type][k], 3 )
            elseif type == 'fire' then
                SetBlipColour( blips[type][k], 1 )
            end
    
            local text = v.name .. ' [' .. k .. ']'
            local id = 'blips_' .. type .. '_' .. k 
    
            AddTextEntry( id, text  )
            BeginTextCommandSetBlipName( id )
            AddTextComponentSubstringPlayerName( text )
            EndTextCommandSetBlipName( blips[type][k] )
        end
    end
end )

RegisterNetEvent("sample_clockin:ClockOut", function()
    for k, v in pairs( blips ) do
        for k2, v2 in pairs( v ) do
            RemoveBlip( v2 )
        end
    end

    blips = {}
end )

RegisterNetEvent( "sample_clockin:RemovePlayerBlip", function( player )
    print( player )
    print( "Player " .. player .. "clocking out." )

    for k, v in pairs( blips ) do
        print( k, v, type( k ) )
        local exists = DoesBlipExist( blips[k][player] )
        print( exists )
        if exists then
            print( blips[k][player] )
            RemoveBlip( blips[k][player] )
        end
    end
end )

-- Hacky solution to fix blips not being removed when someone clocks out
-- Citizen.CreateThread( function()
--     while true do
--         for k, v in pairs( blips ) do
--             for k2, v2 in pairs( blips ) do
--                 RemoveBlip( v2 )
--             end
--         end

--         blips = {}

--         Citizen.Wait( 5000 )
--     end
-- end )