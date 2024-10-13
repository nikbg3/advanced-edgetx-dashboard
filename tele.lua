-- This is the main telemetry screen
local shared = ...
-- Variable used for info screens
txvoltage = getValue(shared.otherSettings.battery.radio)
radio = getGeneralSettings()
local timeNow = getDateTime()
local screeb = 2 -- 1 is fly timer; 2 is for AMP and mAH; and 3 is for GPS.
local hasGPS = true
local checkListText = nil
local isChecklistVisible = false

--Variables used for the rssi display
local lq = 0
local pwr = 0
local rfmd = 0

-- Get telemetry values function
local function getTelemeValues()
    -- Get RSSI
    shared.rssi = (shared.D8 == true or shared.otherSettings.link.frsky) and getRSSI() or
        getValue(shared.otherSettings.link.rssi)
    if shared.rssi < 0 then
        rssiDraw = shared.rssi + 130
    else
        rssiDraw = shared.rssi
    end
    -- Get satcount
    sats = getValue(shared.otherSettings.satcount)

    -- GetRMFD
    rfmd = getValue('RMFD')

    -- Check if GPS telemetry exists and get position
    gps = getFieldInfo('GPS') and getValue('GPS') or false

    -- Get RX signal strength source
    lq = getValue(shared.otherSettings.link.link_quality)

    -- Get current transmitter voltage
    txvoltage = getValue(shared.otherSettings.battery.radio)

    -- Animation helper
    tick = math.fmod(getTime() / 100, 2)

    -- Get quad battery voltage source
    local newVoltage = getValue(shared.otherSettings.battery.voltage)
    if (not shared.isArmed and checkListText ~= nil and (voltage == nil or voltage == 0 or voltage ~= voltage) and newVoltage > 1.0) then
        isChecklistVisible = true
        playFile("chl.wav")
    end
    voltage = newVoltage

    -- Get quad temperature
    temperature = getValue(shared.otherSettings.temp.temp1)

    -- Get quad battery capacity drained value in mAh
    shared.capacity = getValue(shared.otherSettings.battery.used)

    -- Get quad current drain
    current = getValue(shared.otherSettings.battery.amps_meter)

    -- PWR value
    pwr = getValue('TPWR')
    --pwr = getValue('Tmp1')

    -- Get mode input
    acro = getValue(shared.switchSettings.acro.switch)
    angle = getValue(shared.switchSettings.angle.switch)
    horizon = getValue(shared.switchSettings.horizon.switch)
    turtle = getValue(shared.switchSettings.turtle.switch)
    air = getValue(shared.switchSettings.air.switch)
end

-- Here are the draw functions

-- Big and sexy battery graphic with average cell voltage
local function drawVoltageImage(x, y, w)
    local cell = 0
    local batt = 0

    -- Try to calculate cells count from batt voltage or skip if using Cels telemetry
    -- Don't support 5s and 7s: it's dangerous to detect - empty 8s look like an 7s!
    if (type(voltage) == 'table') then
        for i, v in ipairs(voltage) do
            batt = batt + v
            cell = cell + 1
        end

        voltage = batt
    else
        cell = math.ceil(voltage / 4.37)
        cell = cell == (5 or 7) and cell + 1 or cell

        batt = voltage
    end

    -- Set mix-max battery cell value, also detect HV type
    local voltageHigh = batt > 4.22 * cell and 4.35 or 4.2
    local voltageLow = 3.3

    -- Draw battery outline
    lcd.drawLine(x + 2, y + 1, x + w - 2, y + 1, SOLID, 0)
    lcd.drawLine(x, y + 2, x + w - 1, y + 2, SOLID, 0)
    lcd.drawLine(x, y + 2, x, y + 50, SOLID, 0)
    lcd.drawLine(x, y + 50, x + w - 1, y + 50, SOLID, 0)
    lcd.drawLine(x + w, y + 3, x + w, y + 49, SOLID, 0)

    -- Draw battery markers from top to bottom
    lcd.drawLine(x + w / 4 * 3, y + 08, x + w - 1, y + 08, SOLID, 0)
    lcd.drawLine(x + w / 4 * 2, y + 14, x + w - 1, y + 14, SOLID, 0)
    lcd.drawLine(x + w / 4 * 3, y + 20, x + w - 1, y + 20, SOLID, 0)
    lcd.drawLine(x + 1, y + 26, x + w - 1, y + 26, SOLID, 0)
    lcd.drawLine(x + w / 4 * 3, y + 32, x + w - 1, y + 32, SOLID, 0)
    lcd.drawLine(x + w / 4 * 2, y + 38, x + w - 1, y + 38, SOLID, 0)
    lcd.drawLine(x + w / 4 * 3, y + 44, x + w - 1, y + 44, SOLID, 0)

    -- Place voltage text [top, middle, bottom]
    lcd.drawText(x + w + 4, y + 00, string.format('%.2fv', voltageHigh), SMLSIZE)

    local cellVolt = string.format('%.2fv', batt / cell)
    if (cellVolt ~= 'nanv') then -- NaN check
        local fullVolt = string.format('%.2fv', batt)
        lcd.drawText(x + w + 4, y + 19, ' ' .. cellVolt, SMLSIZE + BOLD)
        lcd.drawText(x + w + 4, y + 29, "(" .. fullVolt .. ")", SMLSIZE + BOLD)
    end
    lcd.drawText(x + w + 4, y + 47, string.format('%.2fv', voltageLow), SMLSIZE)

    -- Fill the battery
    for offset = 0, 46, 1 do
        if ((offset * (voltageHigh - voltageLow) / 47) + voltageLow) < tonumber(batt / cell) then
            lcd.drawLine(x + 1, y + 49 - offset, x + w - 1, y + 49 - offset, SOLID, 0)
        end
    end
end

-- Draw Propellors (quad goes under)
local function drawPropellor(x, y, invert)
    if (not shared.isArmed and not invert) or (shared.isArmed and animation == (invert and 2 or 0)) then
        lcd.drawLine(x + 1, y + 9, x + 9, y + 1, SOLID, FORCE)
        lcd.drawLine(x + 1, y + 10, x + 8, y + 1, SOLID, FORCE)
    elseif (shared.isArmed and animation == 1) then
        lcd.drawLine(x, y + 5, x + 9, y + 5, SOLID, FORCE)
        lcd.drawLine(x, y + 4, x + 9, y + 6, SOLID, FORCE)
    elseif (not shared.isArmed and invert) or (shared.isArmed and animation == (invert and 0 or 2)) then
        lcd.drawLine(x + 1, y + 1, x + 9, y + 9, SOLID, FORCE)
        lcd.drawLine(x + 1, y + 2, x + 10, y + 9, SOLID, FORCE)
    elseif (shared.isArmed and animation == 3) then
        lcd.drawLine(x + 5, y, x + 5, y + 10, SOLID, FORCE)
        lcd.drawLine(x + 6, y, x + 4, y + 10, SOLID, FORCE)
    end
end

-- Draw quad
local function drawQuadcopter(x, y)
    -- A little frame counter to help prop drawing
    animation = math.fmod(math.ceil(tick * 8), 4)

    -- Top left to bottom right
    lcd.drawLine(x + 4, y + 4, x + 26, y + 26, SOLID, FORCE)
    lcd.drawLine(x + 4, y + 5, x + 25, y + 26, SOLID, FORCE)
    lcd.drawLine(x + 5, y + 4, x + 26, y + 25, SOLID, FORCE)

    -- Bottom left to top right
    lcd.drawLine(x + 4, y + 26, x + 26, y + 4, SOLID, FORCE)
    lcd.drawLine(x + 4, y + 25, x + 25, y + 4, SOLID, FORCE)
    lcd.drawLine(x + 5, y + 26, x + 26, y + 5, SOLID, FORCE)

    -- Middle of Quad
    lcd.drawRectangle(x + 11, y + 11, 9, 9, SOLID)
    lcd.drawRectangle(x + 12, y + 12, 7, 7, SOLID)
    lcd.drawRectangle(x + 13, y + 13, 5, 5, SOLID)

    -- Draw propellors [top left, bottom right, top right, bottom left]
    drawPropellor(x, y, false)
    drawPropellor(x + 20, y + 20, false)
    drawPropellor(x + 20, y, true)
    drawPropellor(x, y + 20, true)

    -- ARMED text
    if shared.isArmed then
        lcd.drawText(x + 3, y + 12, 'ARMED', SMLSIZE + BLINK)
    end

    if shared.noConnectionMSG then
        lcd.drawText(x, y + 12, 'NO QUAD', SMLSIZE + BLINK)
    end
end

local function printLQ(x, y)
    -- Draw lq
    lcd.drawText(x + 2, y + 2, 'LQ' .. ':', SMLSIZE + (lq > shared.otherSettings.warnings.lq_warning and 0 or BLINK))
    lcd.drawText(x + 15, y + 2, tostring(lq), SMLSIZE + (lq > shared.otherSettings.warnings.lq_warning and 0 or BLINK))

    -- Draw simbol
    if lq > 0 then
        lcd.drawLine(x + 35, y + 3, x + 35, y + 3, SOLID, FORCE)
        lcd.drawLine(x + 36, y + 2, x + 40, y + 2, SOLID, FORCE)
        lcd.drawLine(x + 41, y + 3, x + 41, y + 3, SOLID, FORCE)
        lcd.drawLine(x + 36, y + 5, x + 36, y + 5, SOLID, FORCE)
        lcd.drawLine(x + 37, y + 4, x + 39, y + 4, SOLID, FORCE)
        lcd.drawLine(x + 40, y + 5, x + 40, y + 5, SOLID, FORCE)
        lcd.drawLine(x + 38, y + 7, x + 38, y + 7, SOLID, FORCE)
    end
end

-- Draw RSSI Dbm and Lq--
local function drawLink(x, y)
    -- Draw top rectangle
    lcd.drawRectangle(x, y, 44, 10, SOLID)

    --Draw captions and values
    if lq ~= 0 and not wideScreen then
        -- Draw smol bottom rectangle
        lcd.drawRectangle(x, y + 9, 44, 10, SOLID)
        printLQ(x, y + 9)
    else
        -- Draw big bottom rectangle
        lcd.drawRectangle(x, y + 9, 44, 15, SOLID)
        if shared.rssi > 0 or rssiDraw > 0 then
            for t = 2, (shared.rssi > 0 and shared.rssi or rssiDraw) + 2, 2 do
                lcd.drawLine(x + 1 + t / 2.5, y + (20 - t / 10), x + 1 + t / 2.5, y + 22, SOLID, FORCE)
            end
        end
    end

    if wideScreen then
        -- Draw top rectangle
        lcd.drawRectangle(x - 45, y, 44, 10, SOLID)
        -- Draw big bottom rectangle
        lcd.drawRectangle(x - 45, y + 9, 44, 15, SOLID)
        -- Print LQ
        printLQ(x - 45, y)
        -- Draw dots
        for i = 2, 41, 2 do
            for j = 1, 11, 2 do
                lcd.drawLine(x - 44 + i, y + 10 + j, x - 44 + i, y + 10 + j, SOLID, FORCE)
            end
        end

        -- Fill the bar (vertiсally or diagonally), on crsf start from 50 (70 is return back value)
        for i = 2, math.max(lq * 2 - 100 * (lq >= 200 and 5 or 1), 0) + 2, 2 do
            lcd.drawLine(x - 44 + i / 2.5, y + 10, x - 44 + i / 2.5, y + 22, SOLID, FORCE)
        end

        --Last pixel filling
        if lq % 200 >= 99 then
            lcd.drawLine(x + 42, y + 10, x + 42, y + 22, SOLID, FORCE)
        end
    end

    lcd.drawText(x + 2, y + 2, 'RSSI' .. ':',
        SMLSIZE + ((shared.rssi == 0 or shared.rssi < shared.otherSettings.warnings.rssi_warning) and BLINK or 0))
    lcd.drawText(x + 24, y + 2, shared.rssi,
        SMLSIZE + ((shared.rssi == 0 or shared.rssi < shared.otherSettings.warnings.rssi_warning) and BLINK or 0))
end

-- Current quad temperature at the bottom
local function drawTempText(x, y)
    if (temperature == nil) then
        temperature = 0
    end

    lcd.drawText(x + (temperature >= 10 and 14 or 17), y, temperature, MIDSIZE)
    lcd.drawText(x + (temperature >= 10 and 28 or 24), y, '°', MEDSIZE)
end


-- Draw mode name
local function drawModeTitle(x, y)
    -- FM
    if (turtle + 1024) / 20.48 == shared.switchSettings.turtle.target and shared.switchSettings.turtle.switch ~= 'None' then
        modeText = 'Turtle'
    elseif (angle + 1024) / 20.48 == shared.switchSettings.angle.target and shared.switchSettings.angle.switch ~= 'None' then
        modeText = 'Angle'
    elseif (horizon + 1024) / 20.48 == shared.switchSettings.horizon.target and shared.switchSettings.horizon.switch ~= 'None' then
        modeText = 'Horizon'
    elseif (air + 1024) / 20.48 == shared.switchSettings.air.target and shared.switchSettings.air.switch ~= 'None' then
        modeText = 'Air'
    elseif (acro + 1024) / 20.48 == shared.switchSettings.acro.target and shared.switchSettings.acro.switch ~= 'None' then
        modeText = 'Acro'
    else
        modeText = 'Acro'
    end

    -- Set up text in top middle of the screen
    lcd.drawText(x - #modeText * 2.5, y, modeText, SMLSIZE)
end
-- Current time with icon
local function drawTime(x, y)
    -- local timeNow = getDateTime()

    -- Clock icon
    lcd.drawLine(x + 1, y + 0, x + 4, y + 0, SOLID, FORCE)
    lcd.drawLine(x + 0, y + 1, x + 0, y + 4, SOLID, FORCE)
    lcd.drawLine(x + 5, y + 1, x + 5, y + 4, SOLID, FORCE)
    lcd.drawLine(x + 2, y + 2, x + 2, y + 3, SOLID, FORCE)
    lcd.drawLine(x + 2, y + 3, x + 3, y + 3, SOLID, FORCE)
    lcd.drawLine(x + 1, y + 5, x + 4, y + 5, SOLID, FORCE)

    -- Time as text, blink on tick
    lcd.drawText(x + 08, y, string.format('%02.0f%s', timeNow.hour, math.ceil(tick) == 1 and '' or ':'), SMLSIZE)
    lcd.drawText(x + 20, y, string.format('%02.0f', timeNow.min), SMLSIZE)
end

-- Tx voltage icon with % indication
local function drawTransmitterVoltage(x, y, w)
    local percent = math.min(math.max(math.ceil((txvoltage - radio.battMin) * 100 / (radio.battMax - radio.battMin)), 0),
        100)
    local filling = math.ceil(percent / 100 * (w - 1) + 0.2)

    -- Battery outline
    lcd.drawRectangle(x, y, w + 1, 6, SOLID)
    lcd.drawLine(x + w + 1, y + 1, x + w + 1, y + 4, SOLID, FORCE)

    -- Battery percentage (after battery)
    lcd.drawText(x + w + 4, y, percent .. '%', SMLSIZE + (percent > 20 and 0 or BLINK))

    -- Fill the battery
    lcd.drawRectangle(x, y + 1, filling, 4, SOLID)
    lcd.drawRectangle(x, y + 2, filling, 2, SOLID)
end

--Flight timer counts from black to white
local function drawFlightTimer(x, y)
    -- Draw main border
    lcd.drawRectangle(x, y, 44, 10)
    lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

    -- Draw caption and timer text
    lcd.drawText(x + 2, y + 2, 'Fly Timer', SMLSIZE)
    lcd.drawTimer(x + 2, y + 11, math.abs(shared.timerLeft), DBLSIZE + (shared.timerLeft >= 0 and 0 or BLINK))

    -- Fill the background
    for offset = 1, shared.timerLeft / shared.timerMax * 42, 1 do
        lcd.drawLine(x + offset, y + 10, x + offset, y + 27, SOLID, 0)
    end
end

local function drawPosition(x, y)
    local sats = getValue(shared.otherSettings.satcount)

    -- Draw main border
    lcd.drawRectangle(x, y, 44, 10)
    lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

    -- Draw caption and GPS coordinates
    lcd.drawText(x + 2, y + 2, 'GPS', SMLSIZE)
    lcd.drawText(x + 4, y + 12, string.sub(string.format('%09.6f', pos.lat), 0, 8), SMLSIZE)
    lcd.drawText(x + 4, y + 20, string.sub(string.format('%09.6f', pos.lon), 0, 8), SMLSIZE)

    -- Blink if telemetry is lost
    if pos.lost then
        lcd.drawFilledRectangle(x + 1, y + 10, 42, math.ceil(tick) ~= 1 and 18 or 0)
    elseif sats ~= 0 then
        -- Draw sats count if telemetry source exists
        lcd.drawText(x + 36 - #tostring(sats) * 5, y + 2, sats, SMLSIZE + (sats >= 3 and 0 or BLINK))

        -- Show satellite icon
        lcd.drawLine(x + 40, y + 6, x + 37, y + 3, SOLID, FORCE)
        lcd.drawLine(x + 40, y + 2, x + 36, y + 6, SOLID, FORCE)
        lcd.drawLine(x + 40, y + 3, x + 37, y + 6, SOLID, FORCE)
        lcd.drawLine(x + 40, y + 4, x + 38, y + 6, SOLID, FORCE)
        lcd.drawLine(x + 39, y + 7, x + 41, y + 7, SOLID, FORCE)
    end
end

local function drawOutput(x, y)
    local grid = { { '4', '50', '150' }, { '25', '50', '100', '100hz', '150', '200', '250', '333hz', '500', 'D250', 'D500', 'F500', 'F1000' } }

    -- Draw main border
    lcd.drawRectangle(x, y, 44, 10)

    -- Prepare final values for display
    local fmd = grid[shared.elrs and 2 or 1][getValue('RFMD')]
    if fmd == nil then
        fmd = 'Err'
    end

    -- Draw caption and blanks
    lcd.drawText(x + 2, y + 2, 'Output', SMLSIZE)
    full = rfmd == 4 or rfmd == 8

    -- Draw bottom rectangle
    lcd.drawRectangle(x, y + 9, 44, (full and 20 or 18), SOLID)

    if pwr ~= 0 and not shared.ghost then
        mwOffset = (full or rfmd == 13) and 1 or 0
        lcd.drawText(x + ((full and 23) or 28), y + ((full and 20) or 18), (full and 'Full') or 'hz', SMLSIZE)
        lcd.drawText(x + 5 - mwOffset, y + 18, 'mw', SMLSIZE)

        -- Small touch to fix overlapping 'hz'
        lcd.drawPoint(x + 28, y + 17, SOLID, FORCE)

        -- Draw output values
        lcd.drawText(x + 11 - mwOffset - #tostring(pwr) * 2.5, y + 11, tostring(pwr), SMLSIZE)
        lcd.drawText(x + 34 - #fmd * 3 - mwOffset, y + 11, fmd, SMLSIZE)
    elseif pwr == 0 then
        -- Draw No Module
        lcd.drawText(x + 18, y + 11, 'No', SMLSIZE + BLINK)
        lcd.drawText(x + 12, y + 18, 'Quad', SMLSIZE + BLINK)
    elseif shared.ghost then
        if rfmd == ('Race250' or 'Pure Race') then
            fmd = '250'
        elseif rfmd == 'Race' then
            fmd = 'RACE'
        elseif rfmd == 'Normal' then
            fmd = 'NRM'
        elseif rfmd == 'Long Range' then
            fmd = 'LR'
        else
            fmd = 'Nil'
        end

        -- Draw mw and hz text
        lcd.drawText(x + 7, y + 16, 'mw', SMLSIZE)
        lcd.drawText(x + 28, y + 16, 'hz', SMLSIZE)

        -- Small touch to fix overlaping 'hz'
        lcd.drawPoint(x + 28, y + 17, SOLID, FORCE)

        -- Draw Values
        lcd.drawText(x + 13 - #tostring(pwr) * 2.5, y + 11, tostring(pwr), SMLSIZE)
        lcd.drawText(x + 34 - #fmd * 3, y + 11, fmd, SMLSIZE)
    end
    -- Draw icon
    lcd.drawLine(x + 35, y + 6, x + 35, y + 7, SOLID, FORCE)
    lcd.drawLine(x + 37, y + 5, x + 37, y + 7, SOLID, FORCE)
    lcd.drawLine(x + 39, y + 4, x + 39, y + 7, SOLID, FORCE)
    lcd.drawLine(x + 41, y + 3, x + 41, y + 7, SOLID, FORCE)
end

-- Draw mah and curr
local function drawCurrAndMah(x, y)
    -- Draw same rectangle as timer
    lcd.drawRectangle(x, y, 44, 10)
    lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

    -- Draw mah
    local mah = shared.mah
    if (mah == nil) then
        mah = 0
    end

    lcd.drawText(x + 16 - #tostring(mah) * 3, y + 13, mah, MIDSIZE)
    lcd.drawText(x + 16 + #tostring(mah) * 4, y + 12, 'm', SMLSIZE)
    lcd.drawText(x + 16 + #tostring(mah) * 4, y + 18, 'ah', SMLSIZE)

    -- Draw current
    lcd.drawText(x + 2, y + 2, 'AMP' .. ':', SMLSIZE)
    lcd.drawText(x + 21, y + 2, current, SMLSIZE)
end

local function showChecklist()
    lcd.clear()
    lcd.resetBacklightTimeout()
    lcd.drawText(1, 1, 'Checklist', INVERS)

    local vPos = 11
    for line in string.gmatch(checkListText, '([^\n]+)\n') do
        lcd.drawRectangle(1, vPos, 7, 7)
        lcd.drawText(15, vPos, line)
        vPos = vPos + 10
    end
end

function shared.run(event)
    lcd.clear()

    if (shared.isArmed) then
        isChecklistVisible = false
    end

    -- Change screen if RETURN button is pressed
    if event == EVT_EXIT_BREAK then
        if (isChecklistVisible) then
            isChecklistVisible = false
            playFile('chlsc.wav')
        else
            if screeb == 2 and not shared.crsf then
                screeb = (hasGPS and 4 or 1)
            else
                screeb = screeb + 1
            end
            if screeb > 4 then
                screeb = 1
            end
        end
    end

    -- Get telemetry values
    getTelemeValues()

    -- Show checlist if new battery instead of telemetry
    if (isChecklistVisible) then
        showChecklist()
        return
    end

    -- Draw model name centered at the upper top of the screen
    lcd.drawText(screen.w / 2 - #shared.modelName * 2.5, 0, shared.modelName, SMLSIZE)

    -- Draw a horizontal line seperating the header
    lcd.drawLine(0, 7, screen.w - 1, 7, SOLID, FORCE)

    if event == EVT_ROT_BREAK then
        shared.changeScreen(1)
    end

    -- Draw time in top right corner
    drawTime(screen.w - 29, 0)

    -- Draw battery percent
    drawTransmitterVoltage(0, 0, screen.w / 10)

    drawModeTitle(screen.w / 2 - (wideScreen and 23 or 0), screen.h / 4 - 7)

    -- Draw sexy quadcopter animated in center
    drawQuadcopter(screen.w / 2 - (wideScreen and 40 or 17), screen.h / 2 - 14)

    -- Draw voltage battery graphic in left side
    drawVoltageImage(3, screen.h / 2 - 22, screen.w / 10)

    -- Draw LQ and RSSI stuff
    drawLink(screen.w - 44, (screen.h - 8) / 4 - 5)

    -- Draw Current temperature at bottom middle
    drawTempText(screen.w / 2 - (wideScreen and 44 or 21), screen.h - (screen.h - 8) / 4 + 1)

    -- Draw flight timer, output and mah/curr
    if screeb == 1 then
        drawData = drawFlightTimer
    elseif screeb == 2 then
        drawData = drawCurrAndMah
    elseif screeb == 3 then
        drawData = drawOutput
    elseif screeb == 4 then
        drawData = drawPosition
    end
    drawData(screen.w - 44, (screen.h - 8) / 4 * 3 - 8)
end

local function loadChecklist()
    local fn = '/MODELS/' .. shared.modelName .. '.txt'
    local f = io.open(fn)
    if f == nil then
        return
    end

    checkListText = io.read(f, 2048)

    io.close(f)
end

function shared.init()
    screen = { w = LCD_W, h = LCD_H }
    wideScreen = screen.w == 212 and true or false
    loadChecklist()

    hasGPS = false
    local f = io.open('/MODELS/' .. shared.modelName .. '_sett.txt')
    if f ~= nil then
        local t = io.read(f, 1024)
        local hasGpsText = string.match(t, 'hasgps:(.+)')
        hasGPS = (hasGpsText == '1')
        io.close(f)
    end

    screeb = (hasGPS and 4 or 2)

    -- Store GPS coordinates
    pos = { lat = 0, lon = 0 }
end
