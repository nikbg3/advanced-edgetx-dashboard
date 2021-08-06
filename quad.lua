----------------------------------------------------------
-- Written by Farley Farley
-- farley <at> neonsurge __dot__ com
-- From: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard
-- Please feel free to submit issues, feedback, etc.
----------------------------------------------------------


------- GLOBALS -------
-- I'm using 8 NiMH Batteries in my QX7, which is 1.1v low, and ~1.325v high
local lowVoltage = 8.8
local currentVoltage = 10.6
local highVoltage = 10.6
-- For an X-Lite you will need...
local lowVoltage = 6.6
local currentVoltage = 8.4
local highVoltage = 8.4
-- For our timer tracking
local timerLeft = 0
local maxTimerValue = 0
-- For armed drawing
local armed = 0
-- For mode drawing
local mode = 0
-- Animation increment
local animationIncrement = 0
-- is off trying to go on...
local isArmed = 0
-- Our global to get our current rssi
local rssi = 0
-- Global for quad voltage
local voltage = 0
-- For debugging / development
local lastMessage = "None"
local lastNumberMessage = "0"


------- HELPERS -------

-- Animated Quadcopter propellor (zero coords for top left)
local function drawPropellor(x, y, invert)
	local animation = animationIncrement

	if invert == true then
		animation = (animation - 3) * -1 + 3
		animation = animation - (animation > 3 and 4 or 0)
	end

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

-- A sexy helper to draw a 30x30 quadcopter (since X7 can not draw bitmap)
local function drawQuadcopter(x, y)
  	-- A little animation / frame counter to help us with various animations
	animationIncrement = math.fmod(math.ceil(math.fmod(getTime() / 100, 2) * 8), 4)

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


-- Sexy tx voltage helper
local function drawTransmitterVoltage(x, y, value)
	local batteryPercent = math.ceil(((((highVoltage - value) / (highVoltage - lowVoltage)) - 1) * -1) * 100)

	batteryPercent = batteryPercent < 0 and 0 or (batteryPercent > 100 and 100 or batteryPercent)

	-- Battery Outline
	lcd.drawRectangle(x, y, x + 12, y + 6, SOLID)
	lcd.drawLine(x + 12, y + 1, x + 12, y + 4, SOLID, FORCE)

	-- Battery Percentage (after battery)
	lcd.drawText(x + 15, y, batteryPercent.."%", (batteryPercent < 20 and SMLSIZE + BLINK or SMLSIZE))

	-- Filled in battery
	local pixels = math.ceil((batteryPercent / 100) * 10)

	lcd.drawFilledRectangle(x + 1, y + 1, pixels, 4, SOLID)
	lcd.drawRectangle(x + 1, y + 1, pixels, 4, SOLID)
end


local function drawFlightTimer(x, y)
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawText(x + 2, y + 2, "Fly Timer", SMLSIZE)	
	lcd.drawTimer(x + 2, y + 11, math.abs(timerLeft), (timerLeft >= 0 and DBLSIZE or DBLSIZE + BLINK))

	for offset = 0, timerLeft / maxTimerValue * 42, 1
	do
		lcd.drawLine(x + offset, y + 10, x + offset, y + 28, SOLID, 0)
	end

	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)
end


local function drawTime(x, y)
	local timeNow = getDateTime()

	local min = string.format("%02.0f", timeNow.min)
	local hour = string.format("%02.0f", timeNow.hour) .. (math.ceil(math.fmod(getTime() / 100, 2)) == 1 and ":" or "")

	lcd.drawText(x, y, hour, SMLSIZE)
	lcd.drawText(x + 12, y, min, SMLSIZE)

	lcd.drawLine(x - 7, y + 0, x - 4, y + 0, SOLID, FORCE)
	lcd.drawLine(x - 8, y + 1, x - 8, y + 4, SOLID, FORCE)
	lcd.drawLine(x - 3, y + 1, x - 3, y + 4, SOLID, FORCE)
	lcd.drawLine(x - 6, y + 2, x - 6, y + 3, SOLID, FORCE)
	lcd.drawLine(x - 6, y + 3, x - 5, y + 3, SOLID, FORCE)
	lcd.drawLine(x - 7, y + 5, x - 4, y + 5, SOLID, FORCE)
end

local function drawRSSI(x, y)
	lcd.drawRectangle(x, y, 44, 10)

	lcd.drawText(x + 2, y + 2, "RSSI:", SMLSIZE)
	lcd.drawText(x + 24, y + 2, rssi, (rssi < 50 and SMLSIZE + BLINK or SMLSIZE))

	lcd.drawRectangle(x, y + 9, 44, 15, SOLID)

	if rssi > 0 then
		for i = 2, rssi + 2, 2
		do
			lcd.drawLine(x + 1 + i / 2.5, y + 20 - i / 10, x + 1 + i / 2.5, y + 22, SOLID, FORCE)
		end

		if rssi == 99 then
			lcd.drawLine(x + 42, y + 10, x + 42, y + 22, SOLID, FORCE)
		end

		lcd.drawLine(x + 35, y + 3, x + 35, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 2, x + 40, y + 2, SOLID, FORCE)
		lcd.drawLine(x + 41, y + 3, x + 41, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 5, x + 36, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 37, y + 4, x + 39, y + 4, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 5, x + 40, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 38, y + 7, x + 38, y + 7, SOLID, FORCE)
	end
end


local function drawVoltageText(x, y)
	lcd.drawText(x + (tonumber(voltage) >= 10 and 0 or 7), y, string.format("%.2f", voltage), MIDSIZE)
	lcd.drawText(x + 31, y + 4, 'v', MEDSIZE)
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

local function gatherInput(event)
  
  -- Get our RSSI
  rssi = getRSSI()

  -- Get the seconds left in our timer
  timerLeft = getValue('timer1')
  -- And set our max timer if it's bigger than our current max timer
  if timerLeft > maxTimerValue then
    maxTimerValue = timerLeft
  end

  -- Get our current transmitter voltage
  currentVoltage = getValue('tx-voltage')
  
   -- Our quad battery
  voltage = getValue('VFAS')
  -- local voltage = getValue('Cels') -- For miniwhoop seems more accurate

  -- Armed / Disarm / Buzzer switch
  armed = getValue('sa')

  -- Our "mode" switch
  mode = getValue('sb')

  -- Do some event handling to figure out what button(s) were pressed  :)
  if event > 0 then
    lastNumberMessage = event
  end
  
  if event == 131 then
    lastMessage = "Page Button HELD"
    killEvents(131)
  end
  if event == 99 then
    lastMessage = "Page Button Pressed"
    killEvents(99)
  end
  if event == 97 then
    lastMessage = "Exit Button Pressed"
    killEvents(97)
  end

  if event == 96 then
    lastMessage = "Menu Button Pressed"
    killEvents(96)
  end
  
  if event == EVT_ROT_RIGHT then
    lastMessage = "Navigate Right Pressed"
    killEvents(EVT_ROT_RIGHT)
  end
  if event == EVT_ROT_LEFT then
    lastMessage = "Navigate Left Pressed"
    killEvents(EVT_ROT_LEFT)
  end
  if event == 98 then
    lastMessage = "Navigate Button Pressed"
    killEvents(98)
  end

end

local function drawModeTitle()
	local modeText = "Unknown"

	if mode < -512 then
		modeText = "Acro"
	elseif mode > -100 and mode < 100 then
		modeText = "Angle"
	elseif mode > 512 then
		modeText = "Horizon"
	end

	lcd.drawText(64 - math.ceil((#modeText * 5) / 2), 9, modeText, SMLSIZE)
end

-- Called when script is lauched
local function run(event)
	-- Gather input from the user
	gatherInput(event)

	-- Now begin drawing...
	lcd.clear()

	-- Draw our sexy voltage in upper left courner
	drawTransmitterVoltage(0, 0, currentVoltage)

	-- Draw our model name centered at the upper top of the screen
	lcd.drawText(64 - math.ceil((#modelName * 5) / 2), 0, modelName, SMLSIZE)

	-- Draw Time in top right courner
	drawTime(107, 0)

	-- Draw a horizontal line seperating the header
	lcd.drawLine(0, 7, 128, 7, SOLID, FORCE)

	-- Draw voltage battery graphic in left size
	drawVoltageImage(3, 10)

	-- Check if we just armed...
	if armed > 512 then
		isArmed = 1
	elseif armed < 512 and isArmed == 1 then
		isArmed = 0
	else
		isArmed = 0
	end

	-- Draw our mode centered above sexy quad
	drawModeTitle()

	-- Draw our sexy quadcopter animated (if armed) from scratch in center
	drawQuadcopter(47, 16)

	-- Draw Voltage at bottom middle
	drawVoltageText(45, 50)

	-- Draw RSSI at right top
	drawRSSI(84, 9)

	-- Draw our flight timer at right bottom
	drawFlightTimer(84, 34)

	return 0
end


-- Called once when model is loaded
local function init_func()
	local modeldata = model.getInfo()

	-- The model name from the handset
	modelName = (modeldata and modeldata['name'] or "Unknown")
end


return { run = run, init = init_func }