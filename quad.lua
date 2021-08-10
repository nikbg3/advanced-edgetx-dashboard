----------------------------------------------------------
-- Original script by Andrew Farley - farley@neonsurge(dot)com
-- Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard
----------------------------------------------------------

------- DRAW FUNCTIONS -------

-- Sexy tx voltage icon with % left on battery
local function drawTransmitterVoltage(x, y)
	-- Battery Outline
	local batteryWidth = 17
	lcd.drawRectangle(x, y, batteryWidth + 2, 6, SOLID)
	lcd.drawLine(x + batteryWidth + 2, y + 1, x + batteryWidth + 2, y + 4, SOLID, FORCE)

	-- Battery Percentage (after battery)
	local batteryPercent = math.ceil((txvoltage - transmitter.battMin) * 100 / (transmitter.battMax - transmitter.battMin))
	batteryPercent = batteryPercent <= 0 and 0 or (batteryPercent > 100 and 100 or batteryPercent)
	lcd.drawText(x + batteryWidth + 5, y, batteryPercent.."%", (batteryPercent < 20 and SMLSIZE + BLINK or SMLSIZE))

	-- Filled in battery
	local batteryFill = math.ceil((batteryPercent / 100) * batteryWidth)
	lcd.drawRectangle(x, y + 1, batteryFill + 1, 4, SOLID)
	lcd.drawRectangle(x, y + 2, batteryFill + 1, 2, SOLID)
end

-- Current time with icon
local function drawTime(x, y)
	local timeNow = getDateTime()

	local min = string.format("%02.0f", timeNow.min)
	local hour = string.format("%02.0f", timeNow.hour) .. (math.ceil(math.fmod(getTime() / 100, 2)) == 1 and ":" or "")

	-- Time as text
	lcd.drawText(x, y, hour, SMLSIZE)
	lcd.drawText(x + 12, y, min, SMLSIZE)

	-- Clock icon
	lcd.drawLine(x - 7, y + 0, x - 4, y + 0, SOLID, FORCE)
	lcd.drawLine(x - 8, y + 1, x - 8, y + 4, SOLID, FORCE)
	lcd.drawLine(x - 3, y + 1, x - 3, y + 4, SOLID, FORCE)
	lcd.drawLine(x - 6, y + 2, x - 6, y + 3, SOLID, FORCE)
	lcd.drawLine(x - 6, y + 3, x - 5, y + 3, SOLID, FORCE)
	lcd.drawLine(x - 7, y + 5, x - 4, y + 5, SOLID, FORCE)
end

-- Big and sexy battery graphic
local function drawVoltageImage(x, y)
	local voltageLow = 3.3
	local voltageHigh = 4.35
	local batteryWidth = 12

	-- Draw our battery outline
	lcd.drawLine(x + 2, y + 1, x + batteryWidth - 2, y + 1, SOLID, 0)
	lcd.drawLine(x, y + 2, x + batteryWidth - 1, y + 2, SOLID, 0)
	lcd.drawLine(x, y + 2, x, y + 50, SOLID, 0)
	lcd.drawLine(x, y + 50, x + batteryWidth - 1, y + 50, SOLID, 0)
	lcd.drawLine(x + batteryWidth, y + 3, x + batteryWidth, y + 49, SOLID, 0)

	-- Draw battery markers from top to bottom
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 4), y + 8, x + batteryWidth - 1, y + 8, SOLID, 0)
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 2), y + 14, x + batteryWidth - 1, y + 14, SOLID, 0)
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 4), y + 20, x + batteryWidth - 1, y + 20, SOLID, 0)
	lcd.drawLine(x + 1, y + 26, x + batteryWidth - 1, y + 26, SOLID, 0)
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 4), y + 32, x + batteryWidth - 1, y + 32, SOLID, 0)
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 2), y + 38, x + batteryWidth - 1, y + 38, SOLID, 0)
	lcd.drawLine(x + batteryWidth - math.ceil(batteryWidth / 4), y + 44, x + batteryWidth - 1, y + 44, SOLID, 0)

	-- Place voltage text [top, middle, bottom]
	lcd.drawText(x + batteryWidth + 4, y + 0, voltageHigh.."v", SMLSIZE)
	lcd.drawText(x + batteryWidth + 4, y + 24, string.format("%.2f", (voltageHigh - voltageLow) / 2 + voltageLow).."v", SMLSIZE)
	lcd.drawText(x + batteryWidth + 4, y + 47, voltageLow.."v", SMLSIZE)

	-- Now draw how full our voltage is...
	for offset = 0, 46, 1 do
		if ((offset * (voltageHigh - voltageLow) / 47) + voltageLow) < tonumber(voltage) then
			lcd.drawLine(x + 1, y + 49 - offset, x + batteryWidth - 1, y + 49 - offset, SOLID, 0)
		end
	end
end

-- Current flying mode (predefined)
local function drawModeTitle()
	-- Define modes and show according to switch position
	local modeList = {[1] = "Acro", [2] = "Angle", [3] = "Horizon"}
	local modeText = modeList[(mode + 1024) / 20.48 / 50 + 1] or "Unknown"

	-- Set up text in top middle of the screen
	lcd.drawText(screen.w / 2 - math.ceil((#modeText * 5) / 2), 9, modeText, SMLSIZE)
end

-- Animated Quadcopter propellor (zero coords for top left)
local function drawPropellor(x, y, invert)
	local animation = animationIncrement

	-- Must spin opposite side if inverted
	if invert == true then
		animation = (animation - 3) * -1 + 3
		animation = animation - (animation > 3 and 4 or 0)
	end

	-- Prop phase accoring to step and ARM state
	if (isArmed == 0 and invert == false) or (isArmed == 1 and animation == 0) then
		lcd.drawLine(x + 1, y + 9, x + 9, y + 1, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 10, x + 8, y + 1, SOLID, FORCE)
	elseif isArmed == 1 and animation == 1 then
		lcd.drawLine(x, y + 5, x + 9, y + 5, SOLID, FORCE)
		lcd.drawLine(x, y + 4, x + 9, y + 6, SOLID, FORCE)
	elseif (isArmed == 0 and invert == true) or (isArmed == 1 and animation == 2) then
		lcd.drawLine(x + 1, y + 1, x + 9, y + 9, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 2, x + 10, y + 9, SOLID, FORCE)
	elseif isArmed == 1 and animation == 3 then
		lcd.drawLine(x + 5, y, x + 5, y + 10, SOLID, FORCE)
		lcd.drawLine(x + 6, y, x + 4, y + 10, SOLID, FORCE)
	end
end

-- A sexy helper to draw a 30x30 quadcopter
local function drawQuadcopter(x, y)
  	-- A little animation / frame counter to help us with various animations
	animationIncrement = math.fmod(math.ceil(math.fmod(getTime() / 100, 2) * 8), 4)

	-- Check if we just armed...
	isArmed = ((armed + 1024) / 20.48 == 100 and 1 or 0)

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
	if isArmed == 1 then
		lcd.drawText(x + 3, y + 12, "ARMED", SMLSIZE + BLINK)
	end
end

-- Current quad battery volatage at the bottom
local function drawVoltageText(x, y)
	lcd.drawText(x + (tonumber(voltage) >= 10 and 4 or 7), y, string.format("%.2f", voltage), MIDSIZE)
	lcd.drawText(x + (tonumber(voltage) >= 10 and 35 or 31), y + 4, 'v', MEDSIZE)
end

-- RSSI value and graph
local function drawRSSI(x, y)
	-- Draw main frame and title
	lcd.drawRectangle(x, y, 44, 10)

	lcd.drawText(x + 2, y + 2, "RSSI:", SMLSIZE)
	lcd.drawText(x + 24, y + 2, rssi, (rssi < 50 and SMLSIZE + BLINK or SMLSIZE))

	lcd.drawRectangle(x, y + 9, 44, 15, SOLID)

	if rssi > 0 then
		-- Fill the bar
		for i = 2, rssi + 2, 2 do
			lcd.drawLine(x + 1 + i / 2.5, y + 20 - i / 10, x + 1 + i / 2.5, y + 22, SOLID, FORCE)
		end

		-- Last pixel filling
		if rssi >= 99 then
			lcd.drawLine(x + 42, y + 10, x + 42, y + 22, SOLID, FORCE)
		end

		-- RSSI icon visible if value > 0
		lcd.drawLine(x + 35, y + 3, x + 35, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 2, x + 40, y + 2, SOLID, FORCE)
		lcd.drawLine(x + 41, y + 3, x + 41, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 5, x + 36, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 37, y + 4, x + 39, y + 4, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 5, x + 40, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 38, y + 7, x + 38, y + 7, SOLID, FORCE)
	end
end

-- Flight timer counts from black to white
local function drawFlightTimer(x, y)
	-- Draw main frame and title
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawText(x + 2, y + 2, "Fly Timer", SMLSIZE)	
	lcd.drawTimer(x + 2, y + 11, math.abs(timerLeft), (timerLeft >= 0 and DBLSIZE or DBLSIZE + BLINK))

	-- Fill the background
	for offset = 0, timerLeft / timerMax * 42, 1 do
		lcd.drawLine(x + offset, y + 10, x + offset, y + 28, SOLID, 0)
	end

	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)
end

------- MAIN FUNCTIONS -------

local function gatherInput(event)
	-- Get our RSSI
	rssi = getRSSI()

	-- Get the seconds left in our timer
	timerLeft = getValue('timer1')

	-- And set our max timer if it's bigger than our current max timer
	if timerLeft > timerMax then
		timerMax = timerLeft
	end

	-- Get our current transmitter voltage
	txvoltage = getValue('tx-voltage')

	-- Our quad battery ? 'Cels' or 'RxBt' - For miniwhoop seems more accurate
	voltage = getValue('VFAS') 

	-- Armed / Disarm / Buzzer switch
	armed = getValue('sd') 

	-- Our "mode" switch
	mode = getValue('sb')
end

local function run(event)
	-- Gather input from the user
	gatherInput(event)

	-- Now begin drawing...
	lcd.clear()

	-- Draw our sexy voltage in upper left courner
	drawTransmitterVoltage(0, 0)

	-- Draw our model name centered at the upper top of the screen
	lcd.drawText(screen.w / 2 - math.ceil((#modelName * 5) / 2), 0, modelName, SMLSIZE)

	-- Draw Time in top right courner
	drawTime(screen.w - 21, 0)

	-- Draw a horizontal line seperating the header
	lcd.drawLine(0, 7, screen.w - 1, 7, SOLID, FORCE)

	-- Draw voltage battery graphic in left size
	drawVoltageImage(3, screen.h / 2 - 22)

	-- Draw our mode centered above sexy quad
	drawModeTitle()

	-- Draw our sexy quadcopter animated (if armed) from scratch in center
	drawQuadcopter(screen.w / 2 - 17,  screen.h / 2 - 15)

	-- Draw Voltage at bottom middle
	drawVoltageText(screen.w / 2 - 21, screen.h - 14)

	-- Draw RSSI at right top
	drawRSSI(screen.w - 44, 9)

	-- Draw our flight timer at right bottom
	drawFlightTimer(screen.w - 44, screen.h - 30)

	return 0
end

local function init_func()
	local modeldata = model.getInfo()

	-- For our timer tracking
	timerMax = 0

	-- The model name from the handset
	modelName = (modeldata and modeldata['name'] or "Unknown")

	-- Read battery max-min range from radio settings
	transmitter = getGeneralSettings()

	-- Screen size for positioning
	screen = {w = LCD_W, h = LCD_H}
end

return { run = run, init = init_func }