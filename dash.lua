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


-- Atención: La batería que esta a la derecha no va a funcionar bien si usas 5s o 7s.
-- Acá pueden cambiar la configuración de los switches, modos de vuelo, etc.
-- La configuración inicial esta hecha para ELRS.

-- PARA CAMBIAR PAGINA, PUEDES USAR EL BOTON RTN O SIMILAR EN TU RADIO.
local switchSettings = {
	-- No Cambiar
    arm = {switch = 'sf', target = 100, prearm_switch = 'sd', prearmTarget = 100},
    mode = {
	acro = {switch = 'sc', target = 0},
	angle = {switch = 'sc', target = 50},
	horizon = {switch = 'None', target = 0},
	turtle = {switch = 'sc', target = 100}
	},
}
-- Aca ya puedes cambiar las cosas
local otherSettings = {

battery = {voltage = 'VFAS', used = 'Fuel', amps_meter = 'Curr', radio = 'tx-voltage'},

-- Acá va el link quality y el rssi. Puedes cambiar TQly y 1RSS segun el protocolo que uses. No cambies el parametro que dice frsky.
link = {link_quality = 'RQly', rssi = 'RSSI', frsky = false},

-- Acá puedes cambiar los valores de las advertencias, tx_battery_low_percent es un porcentaje.
warnings = {rssi_warning = -95, lq_warning = 50, battery_low = 3.5, tx_battery_low_percent = 20},

-- GPS
satcount = 'Sats'
}

--Variables used for the rssi display
local lq = 0
local rssi = 0
local rssi_blink = false
local pwr = getValue('TPWR')
local rfmd = 'None'

-- Default model name
local modelName = 'Unknown'

-- Variable used to know if it is armed and/or prearmed
local armed = 0
local prearmed = 0
local isPrearmed = false
local isArmed = false
local noConnectionMSG = false
local noPrearm = false

-- Variables used to get the current module
local internalModule = model.getModule(0)
local externalModule = model.getModule(1)
local twoModules = false

-- Variable used for the current time input
local timeNow = getDateTime()

-- Vairables used for the timer
local timer = 2
local timerLeft = 0
local timerMax = 0

-- Variable used for screen changing
local screeb = 0

local warningAccepted1 = false
local warningAccepted2 = false

local function resetTelemetryProtocol() -- Reset telemetry protocol
	otherSettings.link.link_quality = 'RQly'
	otherSettings.link.rssi = 'RSSI'
	otherSettings.battery.used = 'Fuel'
	otherSettings.battery.voltage = 'VFAS'
	otherSettings.link.frsky = true
end

-- GET ALL NECESSARY VALUE --
local function getTelemeValues()
	if crsf == true then --For ELRS and CRSF 
		otherSettings.link.link_quality = 'RQLY'
		otherSettings.link.rssi = '1RSS'
		otherSettings.battery.voltage = 'RxBt'
		otherSettings.battery.used = 'Capa'
		otherSettings.link.frsky = false
	end
	if ghost == true then --For GHOST
		otherSettings.link.link_quality = 'RQly'
		otherSettings.link.rssi = 'RSSI'
		otherSettings.battery.voltage = 'RxBt'
		otherSettings.link.frsky = false
	end
	if (externalModule.Type == 6 or externalModule.Type == 2) and (externalModule.subType == 1 or (internalModule.protocol == 3 or externalModule.protocol == 3)) then
		otherSettings.link.rssi = 'RSSI'
		if getValue('A1') ~= 0 then
			otherSettings.battery.voltage = 'A1'
		else
			otherSettings.battery.voltage = 'A0'
		end
		D8 = true
	else
		D8 = false
	end
	if not crsf and not ghost and not D8 then
		resetTelemetryProtocol()
	end

    -- Get RSSI
	rssi = (D8 == true or otherSettings.link.frsky) and getRSSI() or getValue(otherSettings.link.rssi)
	if rssi < 0 then
		rssiDraw = rssi + 130
	else
		rssiDraw = rssi
	end
	-- Get satcount
	sats = getValue(otherSettings.satcount)

	-- GetRMFD
	rfmd = getValue('RMFD')

	-- Check if GPS telemetry exists and get position
	gps = getFieldInfo('GPS') and getValue('GPS') or false

	-- Get RX signal strength source
	lq = getValue(otherSettings.link.link_quality)
	--lq = getRSSI()
    -- Get current transmitter voltage
    txvoltage = getValue(otherSettings.battery.radio)

    -- Animation helper
	tick = math.fmod(getTime() / 100, 2)

	-- Get quad battery voltage source
	voltage = getValue(otherSettings.battery.voltage)

	-- Get quad battery capacity drained value in mAh
	capacity = getValue(otherSettings.battery.used)

	-- Get quad current drain
	current = getValue(otherSettings.battery.amps_meter)

	-- ARM switch source
	armed = getValue(switchSettings.arm.switch)

	-- PWR value
	pwr = getValue('TPWR')

	-- PREARM switch source
	prearmed = getValue(switchSettings.arm.prearm_switch)

    -- Get mode input
    -- mode = getValue(settings.mode.switch)
	acro = getValue(switchSettings.mode.acro.switch)
	angle = getValue(switchSettings.mode.angle.switch)
	horizon = getValue(switchSettings.mode.horizon.switch)
	turtle = getValue(switchSettings.mode.turtle.switch)

    internalModule = model.getModule(0)
	externalModule = model.getModule(1)

	if (externalModule.Type ~= 0 and internalModule.Type == 0) or (externalModule.Type == 0 and internalModule.Type ~= 0) then
		warningAccepted = false
	end

	-- Differentiate what exact long-range module is used
	if crsf and elrs == nil then
		local shift, command, data = 3, crossfireTelemetryPop()

		if command == 0x29 and data[2] == 0xEE then
			while data[shift] ~= 0 do
				shift = shift + 1
			end

			elrs = (data[shift + 1] == 0x45 and data[shift + 2] == 0x4c and data[shift + 3] == 0x52 and data[shift + 4] == 0x53)
		elseif math.ceil(tick) == 1 then
			crossfireTelemetryPush(0x28, {0x00, 0xEA})
		end
	end
end



-- Sexy tx voltage icon with % indication
local function drawTransmitterVoltage(x, y, w)
	local percent = math.min(math.max(math.ceil((txvoltage - radio.battMin) * 100 / (radio.battMax - radio.battMin)), 0), 100)
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

-- Big and sexy battery graphic with average cell voltage
local function drawVoltageImage(x, y, w)
	local batt, cell = 0, 0

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
	lcd.drawText(x + w + 4, y + 24, string.format('%.2fv', (voltageHigh - voltageLow) / 2 + voltageLow), SMLSIZE)
	lcd.drawText(x + w + 4, y + 47, string.format('%.2fv', voltageLow), SMLSIZE)

	-- Fill the battery
	for offset = 0, 46, 1 do
		if ((offset * (voltageHigh - voltageLow) / 47) + voltageLow) < tonumber(batt / cell) then
			lcd.drawLine(x + 1, y + 49 - offset, x + w - 1, y + 49 - offset, SOLID, 0)
		end
	end
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

-- Current flying mode
local function drawModeTitle(x, y)
    -- FM
	if (acro+ 1024) / 20.48 == switchSettings.mode.acro.target and switchSettings.mode.acro.switch ~= 'None' then
		modeText = 'Acro'
	elseif (angle + 1024) / 20.48 == switchSettings.mode.angle.target and switchSettings.mode.angle.switch ~= 'None' then
		modeText = 'Angle'
	elseif (horizon + 1024) / 20.48 == switchSettings.mode.horizon.target and switchSettings.mode.horizon.switch ~= 'None' then
		modeText = 'Horizon'
	elseif (turtle + 1024) / 20.48 == switchSettings.mode.turtle.target and switchSettings.mode.turtle.switch ~= 'None' then
		modeText = 'Turtle'
	elseif modeText == nil then
		modeText = 'Acro'
	end
    -- Check if quad is armed by a switch
	if (prearmed + 1024) / 20.48 == switchSettings.arm.prearmTarget or switchSettings.arm.prearm_switch == 'None' then
		isPrearmed = true
	else
		isPrearmed = false
	end

	if (armed + 1024) / 20.48 == switchSettings.arm.target and rssi ~= 0 and (isPrearmed or isArmed) and switchSettings.arm.switch ~= 'None' then
		isArmed = true
	else
		isArmed = false
	end

	if (armed + 1024) / 20.48 == switchSettings.arm.target and rssi == 0 and switchSettings.arm.switch ~= 'None' then
		noConnectionMSG = true
	else
		noConnectionMSG = false
	end

    -- Set up text in top middle of the screen
	lcd.drawText(x - #modeText * 2.5, y, modeText, SMLSIZE)
end

--Flight timer counts from black to white
local function drawFlightTimer(x, y)
	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

	-- Draw caption and timer text
	lcd.drawText(x + 2, y + 2, 'Fly Timer', SMLSIZE)
	lcd.drawTimer(x + 2, y + 11, math.abs(timerLeft), DBLSIZE + (timerLeft >= 0 and 0 or BLINK))

	-- Fill the background
	for offset = 1, timerLeft / timerMax * 42, 1 do
		lcd.drawLine(x + offset, y + 10, x + offset, y + 27, SOLID, 0)
	end
end

local function drawPropellor(x, y, invert)
	if (not isArmed and not invert) or (isArmed and animation == (invert and 2 or 0)) then
		lcd.drawLine(x + 1, y + 9, x + 9, y + 1, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 10, x + 8, y + 1, SOLID, FORCE)
	elseif (isArmed and animation == 1) then
		lcd.drawLine(x, y + 5, x + 9, y + 5, SOLID, FORCE)
		lcd.drawLine(x, y + 4, x + 9, y + 6, SOLID, FORCE)
	elseif (not isArmed and invert) or (isArmed and animation == (invert and 0 or 2)) then
		lcd.drawLine(x + 1, y + 1, x + 9, y + 9, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 2, x + 10, y + 9, SOLID, FORCE)
	elseif (isArmed and animation == 3) then
		lcd.drawLine(x + 5, y, x + 5, y + 10, SOLID, FORCE)
		lcd.drawLine(x + 6, y, x + 4, y + 10, SOLID, FORCE)
	end
end

-- A sexy helper to draw a 30x30 quadcopter
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
  if isArmed then
	lcd.drawText(x + 3, y + 12, 'ARMED', SMLSIZE + BLINK)
  end

  if noConnectionMSG then
	lcd.drawText(x, y + 12, 'NO QUAD', SMLSIZE + BLINK)
  end

  if noPrearm then
	lcd.drawText(x + 1, y + 12, 'NO PREARM', SMLSIZE + BLINK)
  end
end

-- Current quad battery voltage at the bottom
local function drawVoltageText(x, y)
	lcd.drawText(x + (voltage >= 10 and 4 or 7), y, string.format('%.2f', voltage), MIDSIZE)
	lcd.drawText(x + (voltage >= 10 and 35 or 31), y + 4, 'v', MEDSIZE)
end

-- Draw mah and curr
local function drawCurrAndMah(x, y)
	-- Draw same rectangle as timer
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

	-- Draw mah
	lcd.drawText(x + 16 - #tostring(mah) * 3, y + 13, mah, MIDSIZE)
	lcd.drawText(x + 16 + #tostring(mah) * 4, y + 12, 'm', SMLSIZE)
	lcd.drawText(x + 16 + #tostring(mah) * 4, y + 18, 'ah', SMLSIZE)

	-- Draw current
	lcd.drawText(x + 2, y + 2, 'AMP' .. ':', SMLSIZE)
	lcd.drawText(x + 21, y + 2, current, SMLSIZE)
end

local function printLQ(x, y)
	-- Draw lq
	lcd.drawText(x + 2, y + 2, 'LQ' .. ':', SMLSIZE + (lq > otherSettings.warnings.lq_warning and 0 or BLINK))
	lcd.drawText(x + 15, y + 2, tostring(lq), SMLSIZE + (lq > otherSettings.warnings.lq_warning and 0 or BLINK))

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
	if lq ~= 0  and not wideScreen then
		-- Draw smol bottom rectangle
		lcd.drawRectangle(x, y + 9, 44, 10, SOLID)
		printLQ(x, y + 9)

	else
		-- Draw big bottom rectangle
		lcd.drawRectangle(x, y + 9, 44, 15, SOLID)
		if rssi > 0 or rssiDraw > 0 then
			for t = 2, (rssi > 0 and rssi or rssiDraw) + 2, 2 do
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

	lcd.drawText(x + 2, y + 2, 'RSSI' .. ':', SMLSIZE + (not rssi_blink and 0 or BLINK))
	lcd.drawText(x + 24, y + 2, rssi, SMLSIZE + (rssi_blink and BLINK or 0))

    -- RSSI BLINK LOGIC EZ
    if rssi ==  0 or rssi < otherSettings.warnings.rssi_warning then
        rssi_blink = true
    else
        rssi_blink = false
    end


end

-- Transmitter output power and frequency
local function drawOutput(x, y)
	local grid = {{'4', '50', '150'}, {'4', '25', '50', '100', '150', '200', '250', '500', '1000'}}


	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)

	-- Prepare final values for display
	local fmd = grid[elrs and 2 or 1][getValue('RFMD')]

	-- Draw caption and blanks
	lcd.drawText(x + 2, y + 2, 'Output', SMLSIZE)

	-- Draw bottom rectangle
	lcd.drawRectangle(x, y + 9, 44, (pwr ~= 0 and 15 or 18), SOLID)

	if pwr ~= 0 and not ghost then
		-- Draw mw and hz text
		lcd.drawText(x + 7, y + 16, 'mw', SMLSIZE)
		lcd.drawText(x + 28, y + 16, 'hz', SMLSIZE)

		-- Small touch to fix overlaping 'hz'
		lcd.drawPoint(x + 28, y + 17, SOLID, FORCE)

		-- Draw output values
		lcd.drawText(x + 13 - #pwr * 2.5, y + 11, pwr, SMLSIZE)
		lcd.drawText(x + 34 - #fmd * 3, y + 11, fmd, SMLSIZE)

	elseif pwr == 0 then
		-- Draw No Module
		lcd.drawText(x + 18, y + 11, 'No', SMLSIZE + BLINK)
		lcd.drawText(x + 12, y + 18, 'Quad', SMLSIZE + BLINK)
	elseif ghost then
		if rfmd == ('Race250' or 'Pure Race') then
			fmd = '250'
		elseif rfmd == 'Race' then
			fmd = '166'
		elseif rfmd == 'Normal' then
			fmd = '55'
		elseif rfmd == 'Long Range' then
			fmd = '15'
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

-- Current GPS position and sat count
local function drawPosition(x, y)
	local sats = getValue(otherSettings.satcount)

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


local function background()
	local timerName = timer - 1

	-- Follow ARM state if timer is not configured
	if model.getTimer(timerName).mode <= 1 then
		model.setTimer(timerName, {mode = isArmed and 1 or 0})
	end

	-- Get seconds left in model timer
	timerLeft = model.getTimer(timerName).value
	timerMax = math.max(timerLeft, timerMax)

    -- Store last capacity drained value
	mah = capacity

	-- Check if GPS data coming
	if type(gps) == 'table' then
		pos = gps
	elseif pos.lat ~= 0 then
		pos.lost = true
	end

	-- Track current time
	timeNow = getDateTime()
end

local t = 0
local i = 1
local selectedMain = 0
local numOrSwitch

local function UpAndDown(value)
	local returnValue
	if value == 0 then
		returnValue = 'Up'
	elseif value == 25 then
		returnValue = 'Up-Mid'
	elseif value == 50 then
		returnValue = 'Mid'
	elseif value == 75 then
		returnValue = 'Mid-Dn'
	elseif value == 100 then
		returnValue = 'Dn'
	else
		returnValue = 'Unk'
	end
	return(returnValue)
end

local subMenu = false
local menu = false
local selectedSwitchNumber = 0
local selectedSub = 0

local function getSwitchPos(switch, oldTarget)
	newTarget = getValue(switch)
	newTarget = (newTarget + 1024) / 20.48
	if newTarget ~= oldTarget then
		return newTarget
	else
		return oldTarget
	end

end

local isEditing = false
local selecSwitch = 'None'

-- Draw Menu
local function drawMenu(event)
	-- Draw title
	lcd.drawFilledRectangle(1, 1, screen.w - 2, 9)

	if event == (EVT_ROT_RIGHT or EVT_MINUS_FIRST) and selectedMain == 0 then
		i = i + 1
	end
	if event == (EVT_ROT_RIGHT or EVT_MINUS_FIRST) and selectedMain ~= 0 then
		t = t + 1
	end
	if event == (EVT_ROT_LEFT or EVT_PLUS_FIRST) and selectedMain == 0 then
		i = i - 1
	end
	if event == (EVT_ROT_LEFT or EVT_PLUS_FIRST) and selectedMain ~= 0 then
		t = t - 1
	end
	if t < 1 then
		t = 2
	end
	if t > 2 then
		t = 1
	end
	if i < 1 then
		i = 1
	end
	if i > 6 then
		i = 6
	end

	-- selectedMain sifnifica cual de las funciones (arm, etc), esta seleccionada
	-- i es como la que esta "hovered"
	-- t es la que esta subseleccionada
	-- Parameter being selected

	if selectedMain ~= 0 and event == (EVT_ROT_BREAK or EVT_ENTER_BREAK) then
		if subMenu == false then
			if t == 1 then
				subMenu = true
				selectedSub = i
				selectedSwitchNumber = 1
				numOrSwitch = 0
			elseif t == 2 then
				numOrSwitch = 1
				subMenu = false
			end
		elseif subMenu == true then
			t = 1
			selectedSub = i
			if selectedSub == 1 then
				switchSettings.arm.switch = selecSwitch
			elseif selectedSub == 2 then
				switchSettings.arm.prearm_switch = selecSwitch
			elseif selectedSub == 3 then
				switchSettings.mode.acro.switch = selecSwitch
			elseif selectedSub == 4 then
				switchSettings.mode.angle.switch = selecSwitch
			elseif selectedSub == 5 then
				switchSettings.mode.horizon.switch = selecSwitch
			elseif selectedSub == 6 then
				switchSettings.mode.turtle.switch = selecSwitch
			end
			subMenu = false
			saveSettings(switchSettings, "/SCRIPTS/TELEMETRY/savedData")
		end
		menu = true
	end

	-- Draw switches
	if event == (EVT_ROT_BREAK or EVT_ENTER_BREAK) and selectedMain == 0 then
		selectedMain = i
		t = 1
	end

	if selectedMain == 0 and event == EVT_EXIT_BREAK then
		menu = false
		t = 1
	end

	if selectedMain ~= 0 and event == EVT_EXIT_BREAK and isEditing == false then
		selectedMain = 0
		menu = true
		t = 1
	end
	if subMenu == true and event == EVT_EXIT_BREAK then
		subMenu = false
		selectedMain = i
	end

	if isEditing and event == (EVT_ROT_BREAK or EVT_ENTER_BREAK) or event == EVT_EXIT_BREAK and selectedMain ~= 0 then
		saveSettings(switchSettings, "/SCRIPTS/TELEMETRY/savedData")
		numOrSwitch = 0
		selectedMain = i
		isEditing = false
	end
	if not isEditing and numOrSwitch == 1 and selectedMain ~= 0 and event == (EVT_ROT_BREAK or EVT_ENTER_BREAK) then
		isEditing = true
	end

	-- Main Menu
	if subMenu == false then
		-- Draw title
		lcd.drawText(screen.w / 2 - #'CONFIG' * 2.5, 2, 'CONFIG', SMLSIZE + INVERS)

		--ARM SWITCH
		local armTargetValue = UpAndDown(switchSettings.arm.target)
			lcd.drawText(2, 11, 'ARM SWITCH = ', SMLSIZE + (selectedMain ~= 1 and (i == 1 and INVERS or 0) or 0))
			lcd.drawLine(1, 18, screen.w - 2, 18, SOLID, 0)
		if i == 1 and t == 1 and selectedMain == 1 then
			lcd.drawText(80, 11, string.upper(switchSettings.arm.switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 11, string.upper(switchSettings.arm.switch), SMLSIZE)
		end
		if i == 1 and t == 2 and selectedMain == 1 then
			lcd.drawText(105, 11, armTargetValue, SMLSIZE + INVERS + (isEditing == true and BLINK or 0))
		else
			lcd.drawText(105, 11, armTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 1 and isEditing then
			switchSettings.arm.target = getSwitchPos(switchSettings.arm.switch, switchSettings.arm.target)
		end

		-- PREARM SWITCH
		local prearmTargetValue = UpAndDown(switchSettings.arm.prearmTarget)
		lcd.drawText(2, 20, 'PREARM SWITCH = ', SMLSIZE + (selectedMain ~= 2 and (i == 2 and INVERS or 0) or 0))
		lcd.drawLine(1, 27, screen.w - 2, 27, SOLID, 0)
		if i == 2 and t == 1 and selectedMain == 2 then
			lcd.drawText(80, 20, string.upper(switchSettings.arm.prearm_switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 20, string.upper(switchSettings.arm.prearm_switch), SMLSIZE)
		end
		if i == 2 and t == 2 and selectedMain == 2 then
			lcd.drawText(105, 20, prearmTargetValue, SMLSIZE + INVERS + (isEditing and BLINK or 0))
		else
			lcd.drawText(105, 20, prearmTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 2 and isEditing then
			switchSettings.arm.prearmTarget = getSwitchPos(switchSettings.arm.prearm_switch, switchSettings.arm.prearmTarget)
		end

		-- ACRO MODE SWITCH
		local acroTargetValue = UpAndDown(switchSettings.mode.acro.target)
		lcd.drawText(2, 29, 'ACRO SWITCH = ', SMLSIZE + (selectedMain ~= 3 and (i == 3 and INVERS or 0) or 0))
		lcd.drawLine(1, 36, screen.w - 2, 36, SOLID, 0)
		if i == 3 and t == 1 and selectedMain == 3 then
			lcd.drawText(80, 29, string.upper(switchSettings.mode.acro.switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 29, string.upper(switchSettings.mode.acro.switch), SMLSIZE)
		end
		if i == 3 and t == 2 and selectedMain == 3 then
			lcd.drawText(105, 29, acroTargetValue, SMLSIZE + INVERS + (isEditing and BLINK or 0))
		else
			lcd.drawText(105, 29, acroTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 3 and isEditing then
			switchSettings.mode.acro.target = getSwitchPos(switchSettings.mode.acro.switch, switchSettings.mode.acro.target)
		end

		-- ANGLE MODE SWITCH
		local angleTargetValue = UpAndDown(switchSettings.mode.angle.target)
		lcd.drawText(2, 38, 'ANGLE SWITCH = ', SMLSIZE + (selectedMain ~= 4 and (i == 4 and INVERS or 0) or 0))
		lcd.drawLine(1, 45, screen.w - 2, 45, SOLID, 0)
		if i == 4 and t == 1 and selectedMain == 4 then
			lcd.drawText(80, 38, string.upper(switchSettings.mode.angle.switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 38, string.upper(switchSettings.mode.angle.switch), SMLSIZE)
		end
		if i == 4 and t == 2 and selectedMain == 4 then
			lcd.drawText(105, 38, angleTargetValue, SMLSIZE + INVERS + (isEditing and BLINK or 0))
		else
			lcd.drawText(105, 38, angleTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 4 and isEditing then
			switchSettings.mode.angle.target = getSwitchPos(switchSettings.mode.acro.switch, switchSettings.mode.angle.target)
		end

		-- HORIZON MODE SWITCH
		local horizonTargetValue = UpAndDown(switchSettings.mode.horizon.target)
		lcd.drawText(2, 47, 'HRZN SWITCH = ', SMLSIZE + (selectedMain ~= 5 and (i == 5 and INVERS or 0) or 0))
		lcd.drawLine(1, 54, screen.w - 2, 54, SOLID, 0)
		if i == 5 and t == 1 and selectedMain == 5 then
			lcd.drawText(80, 47, string.upper(switchSettings.mode.horizon.switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 47, string.upper(switchSettings.mode.horizon.switch), SMLSIZE)
		end
		if i == 5 and t == 2 and selectedMain == 5 then
			lcd.drawText(105, 47, horizonTargetValue, SMLSIZE + INVERS + (isEditing and BLINK or 0))
		else
			lcd.drawText(105, 47, horizonTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 5 and isEditing then
			switchSettings.mode.horizon.target = getSwitchPos(switchSettings.mode.horizon.switch, switchSettings.mode.horizon.target)
		end

		-- TURTLE MODE SWITCH
		local turtleTargetValue = UpAndDown(switchSettings.mode.turtle.target)
		lcd.drawText(2, 56, 'TUTRLE SWITCH = ', SMLSIZE + (selectedMain ~= 6 and (i == 6 and INVERS or 0) or 0))
		lcd.drawLine(1, 63, screen.w - 2, 63, SOLID, 0)
		if i == 6 and t == 1 and selectedMain == 6 then
			lcd.drawText(80, 56, string.upper(switchSettings.mode.turtle.switch), SMLSIZE + INVERS)
		else
			lcd.drawText(80, 56, string.upper(switchSettings.mode.turtle.switch), SMLSIZE)
		end
		if i == 6 and t == 2 and selectedMain == 6 then
			lcd.drawText(105, 56, turtleTargetValue, SMLSIZE + INVERS + (isEditing and BLINK or 0))
		else
			lcd.drawText(105, 56, turtleTargetValue, SMLSIZE)
		end
		if numOrSwitch == 1 and i == 6 and isEditing then
			switchSettings.mode.turtle.target = getSwitchPos(switchSettings.mode.turtle.switch, switchSettings.mode.turtle.target)
		end
	end

	-- Sub Menu
	if subMenu == true then
		-- Draw title
		lcd.drawText(screen.w / 2 - #'SELECT SWITCH' * 2.5, 2, 'SELECT SWITCH', SMLSIZE + INVERS)
		if event == (EVT_ROT_RIGHT or EVT_MINUS_FIRST) then
			selectedSwitchNumber = selectedSwitchNumber + 1
		end
		if event == (EVT_ROT_LEFT or EVT_PLUS_FIRST) then
			selectedSwitchNumber = selectedSwitchNumber - 1
		end
		if selectedSwitchNumber < 1 then
			selectedSwitchNumber = 1
		end
		if selectedSwitchNumber > 9 then
			selectedSwitchNumber = 9
		end

		--- DRAW SWITCHES ---
		-- SA
		if selectedSwitchNumber == 1 then
			selecSwitch = "sa"
			lcd.drawText(screen.w / 2 - 33, 11, 'SA', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 - 33, 11, 'SA', SMLSIZE)
		end

		-- SB
		if selectedSwitchNumber == 2 then
			selecSwitch = "sb"
			lcd.drawText(screen.w / 2 + 19, 11, 'SB', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 + 19, 11, 'SB', SMLSIZE)
		end

		-- SC
		if selectedSwitchNumber == 3 then
			selecSwitch = "sc"
			lcd.drawText(screen.w / 2 - 33, 20, 'SC', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 - 33, 20, 'SC', SMLSIZE)
		end

		-- SD
		if selectedSwitchNumber == 4 then
			selecSwitch = 'sd'
			lcd.drawText(screen.w / 2 + 19, 20, 'SD', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 + 19, 20, 'SD', SMLSIZE)
		end

		-- SE
		if selectedSwitchNumber == 5 then
			selecSwitch = 'se'
			lcd.drawText(screen.w / 2 - 33, 29, 'SE', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 - 33, 29, 'SE', SMLSIZE)
		end

		-- SF
		if selectedSwitchNumber == 6 then
			selecSwitch = 'sf'
			lcd.drawText(screen.w / 2 + 19, 29, 'SF', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 + 19, 29, 'SF', SMLSIZE)
		end

		-- SG
		if selectedSwitchNumber == 7 then
			selecSwitch = 'sg'
			lcd.drawText(screen.w / 2 - 33, 38, 'SG', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 - 33, 38, 'SG', SMLSIZE)
		end

		-- SH
		if selectedSwitchNumber == 8 then
			selecSwitch = 'sh'
			lcd.drawText(screen.w / 2 + 19, 38, 'SH', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 + 19, 38, 'SH', SMLSIZE)
		end

		-- None
		if selectedSwitchNumber == 9 then
			selecSwitch = 'None'
			lcd.drawText(screen.w / 2 - #'None' * 2.5, 47, 'None', SMLSIZE + INVERS)
		else
			lcd.drawText(screen.w / 2 - #'None' * 2.5, 47, 'None', SMLSIZE)
		end
	end
	-- Draw Main rectangle
	lcd.drawRectangle(0, 0, screen.w, screen.h, SOLID)
end


local function drawNormal(event)

    -- Draw LQ and RSSI stuff
    drawLink(screen.w - 44, (screen.h - 8) / 4 - 5)

    -- Draw tx voltage in upper left corner
    drawTransmitterVoltage(0, 0, screen.w / 10)

    -- Draw model name centered at the upper top of the screen
	lcd.drawText(screen.w / 2 - #modelName * 2.5, 0, modelName, SMLSIZE)

	-- Draw a horizontal line seperating the header
	lcd.drawLine(0, 7, screen.w - 1, 7, SOLID, FORCE)

    -- Draw time in top right courner
	drawTime(screen.w - 29, 0)

    -- Draw fly mode centered above sexy quad
	drawModeTitle(screen.w / 2 - (wideScreen and 23 or 0), screen.h / 4 - 7)

    -- Draw sexy quadcopter animated in center
	drawQuadcopter(screen.w / 2 - (wideScreen and 40 or 17),  screen.h / 2 - 14)

    -- Draw flight timer, output and mah/curr
	if screeb == 2 then
		drawData = drawCurrAndMah
	elseif screeb == 0 then
		drawData = drawFlightTimer
	elseif screeb == 1 then
		drawData = drawOutput
	else
		drawData = drawPosition
	end
    drawData(screen.w - 44, (screen.h - 8) / 4 * 3 - 8)

    -- Draw battery capacity drained or current voltage at bottom middle
	drawVoltageText(screen.w / 2 - (wideScreen and 44 or 21), screen.h - (screen.h - 8) / 4 + 1)

    -- Change screen if PAGE button is pressed
    if event == EVT_EXIT_BREAK then
		if lq == 1 and screeb == 0 then
			screeb = 2
		else
			screeb = screeb + 1
		end
		if screeb == 4 then
			screeb = 0
		end
		if screeb == 1 and ghost == false and crsf == false then
			screeb = 2
		end
    end

	-- Draw voltage battery graphic in left side
	drawVoltageImage(3, screen.h / 2 - 22, screen.w / 10)
end

local function run(event)
    -- Gather all necessary data
    getTelemeValues()

	-- Detect current Module
	internalModule = model.getModule(0)
	externalModule = model.getModule(1)

    -- Begin drawing
    lcd.clear()

	if menu == false then
		drawScreen = drawNormal
	end
	if menu == true then
		drawScreen = drawMenu
	end

	drawScreen(event)

	if event == (EVT_ROT_BREAK or EVT_ENTER_BREAK) then
		menu = true
	end

	if internalModule.Type ~= 0 and externalModule.Type ~= 0 and warningAccepted1 == false then
		warningAccepted1 = popupWarning('Dual Modules', event)
		if warningAccepted1 == "CANCEL" then
			warningAccepted1 = true
		else
			warningAccepted1 = false
		end
	end
	if internalModule.Type == 0 and externalModule.Type == 0 and warningAccepted2 == false then
		warningAccepted2 = popupConfirmation('No Module', event)
		if warningAccepted2 == "CANCEL" then
			warningAccepted2 = true
		else
			warningAccepted2 = false
		end
	end
end

local function init()

	crsf = crossfireTelemetryPush() ~= nil
	ghost = ghostTelemetryPush() ~= nil

	saveSettings = loadScript("/SCRIPTS/TELEMETRY/saveTable.lua")

    -- Model name from the radio
    modelName = model.getInfo()['name']

	-- Radio battery min-max range
	radio = getGeneralSettings()

    -- Screen size for positioning
	screen = {w = LCD_W, h = LCD_H}
	wideScreen = screen.w == 212 and true or false

    -- Timer tracking
	timerMax = 0

	-- Store GPS coordinates
	pos = {lat = 0, lon = 0}

	-- Get settings
	if loadfile("/SCRIPTS/TELEMETRY/savedData") then
		switchSettings = loadfile("/SCRIPTS/TELEMETRY/savedData")()
	end
end

return { init = init, run = run, background = background }