--[[function GetPlayerName( player )
    return exports.sample_util:GetPlayerName( player )
end]]--

local clockinTime = {}

RegisterNetEvent( 'sample_clockin:ClockIn' )
AddEventHandler( 'sample_clockin:ClockIn', function( leo )
    if leo == nil then leo = true end
    local player = source

    if leo and not exports.sample_util:IsCop( player ) then
        TriggerClientEvent( 'chat:addMessage', player, {
            args = { "^1ERROR", "You do not have permission to clock in as a police officer." }
        })

        return
    end

    if fire and not exports.sample_util:IsFire( player ) then
        TriggerClientEvent( 'chat:addMessage', player, {
            args = { "^1ERROR", "You do not have permission to clock in as a firefighter." }
        })

        return
    end

    local name = GetPlayerName( player )
    local time = os.date( "%m/%d/%Y %I:%M%p", os.time() - 18000 )
    local content = {
        embeds = {
            {
                title = name,
                description = "Clocked in as " .. ( leo and 'LEO' or 'Fire') .. '.',
                color = leo and "255" or "16711680",
                footer = {
                    text = time
                }
            }
        }
    }

    local identifier = GetPlayerIdentifier(player)
    clockinTime[identifier] = os.date('%Y-%m-%d %H:%M:%S')

    if leo and exports.sample_util:IsCop( player ) or exports.sample_util:IsFire( player ) then
        TriggerClientEvent( 'sample_clockin:ClockedIn', player, true, false )

        -- exports.sample_util:FireWebhook( leo and 'Clock-in Leo' or 'Clock-in Fire', content )

        -- TODO door perms

        local state = Player( player ).state
        state.clockin = { isLeo = leo, isFire = not leo }

        if leo then
            TriggerClientEvent( 'sample_clockin:GiveLeoWeapons', player )
            -- TriggerClientEvent( 'asrp:doorperms', player )
        end
    end
end )

local function ClockOut( player )
    local leo = IsLeo( player )
    local fire = IsFire( player )

    if not leo and not fire then return end

    local name = GetPlayerName( player )
    local time = os.date( "%m/%d/%Y %I:%M%p", os.time() - 18000 )
    local content = {
        embeds = {
            {
                title = name,
                description = "Clocked out from " .. ( leo and 'LEO' or 'Fire') .. '.',
                color = leo and "255" or "16711680",
                footer = {
                    text = time
                }
            }
        }
    }

    local identifier = GetPlayerIdentifier(player)
    clockinTime[identifier] = nil

    exports.sample_util:FireWebhook( leo and 'Clock-in Leo' or 'Clock-in Fire', content )

    Player( player ).state.clockin = { isLeo = false, isFire = false }
    TriggerClientEvent( "sample_clockin:ClockOut", player )
    RemoveClockinBlip( player )
end

RegisterNetEvent( 'sample_clockin:ClockOut' )
AddEventHandler( 'sample_clockin:ClockOut', function()
    local player = source

    ClockOut( player )
end )

AddEventHandler( 'playerDropped', function()
    local player = source
    local state = Player( player ).state.clockin or { isLeo = false, isFire = false }

    if state.isLeo or state.isFire then
        ClockOut( player )
    end
end )
local leo = {}
local fire = {}

-- local disabledTrackers = {}

-- -- RegisterCommand( 'toggletracker', function( player )
-- --     if disabledTrackers[player] then
-- --         disabledTrackers[player] = false
-- --         TriggerClientEvent( 'chat:addMessage', player, {
-- --             args = { 'Tracker', 'Your tracker has been re-enabled.' }
-- --         } )
            
-- --         return
-- --     end
        
-- --     disabledTrackers[player] = true
-- --     TriggerClientEvent( 'chat:addMessage', player, {
-- --         args = { 'Tracker', 'Your tracker has been disabled.' }
-- --     } )
-- -- end )

Citizen.CreateThread( function()
    while true do
        for k, v in ipairs( GetPlayers() ) do

            -- if not disabledTrackers[v] then goto skip end

            local isLeo, isFire = IsLeo( v ), IsFire( v )
            if not isLeo and not isFire then goto skip end

            local p = GetPlayerPed( v )
            local c = GetEntityCoords( p )

            if isLeo then
                leo[tostring( v )] = { name = GetPlayerName( v ), coords = c }
            else
                fire[tostring( v )] = { name = GetPlayerName( v ), coords = c }
            end

            ::skip::
        end

        for k, v in ipairs( GetPlayers() ) do
            local isLeo, isFire = IsLeo( v ), IsFire( v )
            if not isLeo and not isFire then goto skip end

            TriggerClientEvent( 'sample_clockin:UpdateBlips', v, 'leo', leo )
            TriggerClientEvent( 'sample_clockin:UpdateBlips', v, 'fire', fire )

            ::skip::
        end

        Citizen.Wait( CONFIG.BLIP_RESET_TIME )
    end
end )

function RemoveClockinBlip( player )
    TriggerClientEvent( "sample_clockin:RemovePlayerBlip", -1, player )
end

AddEventHandler( 'playerDropped', function()
    local player = source

    leo[player] = nil
    fire[player] = nil

    RemoveClockinBlip( player )
end )

local function DefaultState( player )
    player.state.clockin = player.state.clockin or { isLeo = false, isFire = false }
end

function IsLeo( handle )
    local player = Player( handle )
    DefaultState( player )
    
    return player.state.clockin.isLeo
end
exports( 'IsLeo', IsLeo )

function IsFire( handle )
    local player = Player( handle )
    DefaultState( player )
    
    return player.state.clockin.isFire
end
exports( 'IsFire', IsFire )

--[[RegisterCommand( '911', function( player, args )
	local name = exports.sample_util:GetPlayerName( player )
    for k, v in ipairs( GetPlayers() ) do
        if v ~= player and IsLeo( v ) or IsFire( v ) then
			TriggerClientEvent( 'chat:addMessage', v, {
				args = { '[^1911^r] ' .. name .. ' [ ' .. player .. ' ]', table.concat( args, ' ' ) }
			} )
		end
    end
		
	TriggerClientEvent( 'chat:addMessage', player, {
		args = { '[^1911^0] ' .. name .. '[' .. player .. ']^0', table.concat( args, ' ' ) }
	} )
end )]]--
