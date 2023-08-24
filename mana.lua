--------------------------------------------------------------------------------
-- Original script by Andrew Farley - farley@neosurge(dot)com
-- Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard
--
-- Optimization and modding by Alexey Gamov - dev@alexey-gamov(dot)ru
-- Git: https://github.com/alexey-gamov/opentx-quad-telemetry
--
-- saveTable.lua (the script that saves the settings) by I shems (in rcgroups)
-- Repo: https://www.rcgroups.com/forums/showthread.php?3129894-Easy-way-to-save-and-load-a-table-in-OpenTX-lua-scripts
--
-- Settings screen, etc, by mvaldesshc - mvaldesshc@gmail(dot)com
-- Git: https://github.com/mvaldesshc/advanced-edgetx-dashboard
--------------------------------------------------------------------------------

-- This is the manager script
-- Here will be the added variables
-- Screen Manager
local shared = {}
shared.screens = {
    "/SCRIPTS/TELEMETRY/tele.lua",
    "/SCRIPTS/TELEMETRY/set.lua"
}

local screen = 1

-- Vairables used for the timer
local timer = 1
shared.timerLeft = 0
shared.timerMax = 0
local armed = 0
local prearmed = 0
shared.modelName = 'Unknown'

-- No modificar / don't modify
shared.switchSettigs = {
    arm = {switch = 'sf', target = 100},
    prearm = {switch = 'sd', target = 100},
    acro = {switch = 'sc', target = 0},
    angle = {switch = 'sc', target = 50},
    horizon = {switch = 'None', target = 0},
    turtle = {switch = 'sc', target = 100}
}

-- Various variables
local internalModule = model.getModule(0)
local externalModule = model.getModule(1)

-- Timer stuff
shared.isPrearmed = false
shared.isArmed = false
shared.noConnectionMSG = false
shared.noPrearm = false

-- Screen Manager
function shared.changeScreen(delta)
    shared.current = shared.current + delta
    if shared.current > 2 then
        shared.current = 2
    elseif shared.current < 1 then
        shared.current = 1
    end
    local chunk = loadScript(shared.screens[shared.current])
    chunk(shared, otherSettings)
end

-- Telemetry sources, etc.
shared.otherSettings = {

    battery = {voltage = 'VFAS', used = 'Fuel', amps_meter = 'Curr', radio = 'tx-voltage'},

    -- Acá va el link quality y el rssi. Puedes cambiar TQly y 1RSS segun el protocolo que uses. No cambies el parametro que dice frsky.
    link = {link_quality = 'RQly', rssi = 'RSSI', frsky = false},

    -- Acá puedes cambiar los valores de las advertencias, tx_battery_low_percent es un porcentaje.
    warnings = {rssi_warning = -95, lq_warning = 50, battery_low = 3.5, tx_battery_low_percent = 20},

    -- GPS
    satcount = 'Sats'
}

--Reset telemetry protocol
local function resetTelemetryProtocol() -- Reset telemetry protocol
    shared.otherSettings.link.rssi = 'RSSI'
    shared.otherSettings.battery.used = 'Fuel'
    shared.otherSettings.battery.voltage = 'VFAS'
    shared.otherSettings.link.frsky = true
end

-- Get telemetry protocol parameters
local function getTelemeParameters()
    if shared.crsf == true then --For ELRS and CRSF
        shared.otherSettings.link.rssi = '1RSS'
        shared.otherSettings.battery.voltage = 'RxBt'
        shared.otherSettings.battery.used = 'Capa'
        shared.otherSettings.link.frsky = false
    end
    if shared.ghost == true then --For GHOST
        shared.otherSettings.link.rssi = 'RSSI'
        shared.otherSettings.battery.voltage = 'RxBt'
        shared.otherSettings.link.frsky = false
    end
    if (externalModule.Type == 6 or externalModule.Type == 2) and (externalModule.subType == 1 or (internalModule.protocol == 3 or externalModule.protocol == 3)) then
        shared.otherSettings.link.rssi = 'RSSI'
        if getValue('A1') ~= 0 then
            shared.otherSettings.battery.voltage = 'A1'
        else
            shared.otherSettings.battery.voltage = 'A0'
        end
        shared.D8 = true
    else
        shared.D8 = false
    end
    if not shared.crsf and not shared.ghost and not shared.D8 then
        resetTelemetryProtocol()
    end
end

local function init()
    shared.crsf = crossfireTelemetryPush() ~= nil
    shared.ghost = ghostTelemetryPush() ~= nil

    shared.screenSize = {w = LCD_W, h = LCD_H}
    shared.current = 0
    shared.changeScreen(0)
    -- Model name from the radio
    shared.modelName = model.getInfo()['name']
    shared.saveSettigs = loadScript("/SCRIPTS/TELEMETRY/saveTable.lua")

    -- Get settings
    if loadfile("/SCRIPTS/TELEMETRY/savedData.txt") then
        shared.switchSettings = loadfile("/SCRIPTS/TELEMETRY/savedData.txt")()
    else
        loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettigs, "/SCRIPTS/TELEMETRY/savedData.txt")
        shared.switchSettings = loadfile("/SCRIPTS/TELEMETRY/savedData.txt")()
    end
    shared.timerMax = 0

    shared.init()
    getTelemeParameters()
end

local function run(event)
    shared.run(event)

    -- Differentiate what exact long-range module is used
    if shared.crsf and shared.elrs == nil then
        local shift, command, data = 3, crossfireTelemetryPop()

        if command == 0x29 and data[2] == 0xEE then
            while data[shift] ~= 0 do
                shift = shift + 1
            end

            shared.elrs = (data[shift + 1] == 0x45 and data[shift + 2] == 0x4c and data[shift + 3] == 0x52 and data[shift + 4] == 0x53)
        elseif math.ceil(tick) == 1 then
            crossfireTelemetryPush(0x28, {0x00, 0xEA})
        end
    end

    -- PREARM switch source
    prearmed = getValue(shared.switchSettings.prearm.switch)

    -- ARM switch source
    armed = getValue(shared.switchSettings.arm.switch)

    if (armed + 1024) / 20.48 == shared.switchSettings.arm.target and shared.rssi == 0 and shared.switchSettings.arm.switch ~= 'None' then
        shared.noConnectionMSG = true
    else
        shared.noConnectionMSG = false
    end

    if (armed + 1024) / 20.48 == shared.switchSettings.arm.target and shared.rssi ~= 0 and (shared.isPrearmed or shared.isArmed) and shared.switchSettings.arm.switch ~= 'None' then
        shared.isArmed = true
    elseif (armed + 1024) / 20.48 == shared.switchSettings.arm.target and shared.rssi ~= 0 and not shared.isPrearmed then
        shared.isArmed = false
        shared.noPrearm = true
    else
        shared.isArmed = false
        shared.noPrearm = false
    end

    -- Check if quad is armed by a switch
    if ((prearmed + 1024) / 20.48 == shared.switchSettings.prearm.target) and not ((armed + 1024) / 20.48 == shared.switchSettigs.arm.target and not shared.isArmed) or (shared.switchSettings.prearm.switch == 'None') then
        shared.isPrearmed = true
    else
        shared.isPrearmed = false
    end
end


local function background()
    local timerName = timer - 1

    -- Follow ARM state if timer is not configured
    if model.getTimer(timerName).mode <= 1 then
        model.setTimer(timerName, {mode = shared.isArmed == true and 1 or 0})
    end

    -- Get seconds left in model timer
    shared.timerLeft = model.getTimer(timerName).value
    shared.timerMax = math.max(shared.timerLeft, shared.timerMax)

    -- Store last capacity drained value
    shared.mah = shared.capacity

    -- Check if GPS data coming
    if type(gps) == 'table' then
        pos = gps
    elseif pos.lat ~= 0 then
        pos.lost = true
    end

    -- Track current time
    shared.timeNow = getDateTime()
end


return { run = run, init = init, background = background}