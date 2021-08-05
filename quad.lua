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
local function drawPropellor(start_x, start_y, invert)
  local animationIncrementLocal = animationIncrement
  if invert == true then
    animationIncrementLocal = (animationIncrementLocal - 3) * -1
    animationIncrementLocal = animationIncrementLocal + 3
    if animationIncrementLocal > 3 then
      animationIncrementLocal = animationIncrementLocal - 4
    end
  end
  
  -- Animated Quadcopter propellors
  if ((isArmed == 0 or isArmed == 2) and invert == false) or (isArmed == 1 and animationIncrementLocal == 0) then
    -- Top left Propellor
    lcd.drawLine(start_x + 1, start_y + 9, start_x + 9, start_y + 1, SOLID, FORCE)
    lcd.drawLine(start_x + 1, start_y + 10, start_x + 8, start_y + 1, SOLID, FORCE)
  elseif isArmed == 1 and animationIncrementLocal == 1 then
    -- Top left Propellor
    lcd.drawLine(start_x, start_y + 5, start_x + 9, start_y + 5, SOLID, FORCE)
    lcd.drawLine(start_x, start_y + 4, start_x + 9, start_y + 6, SOLID, FORCE)
  elseif ((isArmed == 0 or isArmed == 2) and invert == true) or (isArmed == 1 and animationIncrementLocal == 2) then
    -- Top left Propellor
    lcd.drawLine(start_x + 1, start_y + 1, start_x + 9, start_y + 9, SOLID, FORCE)
    lcd.drawLine(start_x + 1, start_y + 2, start_x + 10, start_y + 9, SOLID, FORCE)
  elseif isArmed == 1 and animationIncrementLocal == 3 then
    -- Top left Propellor
    lcd.drawLine(start_x + 5, start_y, start_x + 5, start_y + 10, SOLID, FORCE)
    lcd.drawLine(start_x + 6, start_y, start_x + 4, start_y + 10, SOLID, FORCE)
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
	local batteryWidth = 17
	local batteryPercent = math.ceil(((((highVoltage - value) / (highVoltage - lowVoltage)) - 1) * -1) * 100)

	batteryPercent = batteryPercent < 0 and 0 or (batteryPercent > 100 and 100 or batteryPercent)

	-- Battery Outline
	lcd.drawRectangle(x, y, x + batteryWidth + 2, y + 6, SOLID)
	lcd.drawLine(x + batteryWidth + 2, y + 1, x + batteryWidth + 2, y + 4, SOLID, FORCE)

	-- Battery Percentage (after battery)
	lcd.drawText(x + batteryWidth + 5, y, batteryPercent.."%", (batteryPercent < 20 and SMLSIZE + BLINK or SMLSIZE))

	-- Filled in battery
	local pixels = math.ceil((batteryPercent / 100) * batteryWidth)

	if pixels == 1 then
		lcd.drawLine(x + pixels, y + 1, x + pixels, y + 4, SOLID, FORCE)
	end

	if pixels > 1 then
		lcd.drawRectangle(x + 1, y + 1, x + pixels, y + 4)
	end

	if pixels > 2 then
		lcd.drawRectangle(x + 2, y + 2, x + pixels - 1, 2)
		lcd.drawLine(x + pixels, y + 2, x + pixels, y + 3, SOLID, FORCE)
	end
end


local function drawFlightTimer(start_x, start_y)
  local timerWidth = 44
  local timerHeight = 20
  local myWidth = 0
  local percentageLeft = 0
  
  lcd.drawRectangle( start_x, start_y, timerWidth, 10 )
  lcd.drawText( start_x + 2, start_y + 2, "Fly Timer", SMLSIZE )
  lcd.drawRectangle( start_x, start_y + 10, timerWidth, timerHeight )

  if timerLeft < 0 then
    lcd.drawRectangle( start_x + 2, start_y + 20, 3, 2 )
    lcd.drawText( start_x + 2 + 3, start_y + 12, (timerLeft * -1).."s", DBLSIZE + BLINK )
  else
    lcd.drawTimer( start_x + 2, start_y + 12, timerLeft, DBLSIZE )
  end 
  
  percentageLeft = (timerLeft / maxTimerValue)
  local offset = 0
  while offset < (timerWidth - 2) do
    if (percentageLeft * (timerWidth - 2)) > offset then
      -- print("Percent left: "..percentageLeft.." width: "..myWidth.." offset: "..offset.." timerHeight: "..timerHeight)
      lcd.drawLine( start_x + 1 + offset, start_y + 11, start_x + 1 + offset, start_y + 9 + timerHeight - 1, SOLID, 0)
    end
    offset = offset + 1
  end
  
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

local function drawVoltageImage(start_x, start_y)
  
  -- Define the battery width (so we can adjust it later)
  local batteryWidth = 12 

  -- Draw our battery outline
  lcd.drawLine(start_x + 2, start_y + 1, start_x + batteryWidth - 2, start_y + 1, SOLID, 0)
  lcd.drawLine(start_x, start_y + 2, start_x + batteryWidth - 1, start_y + 2, SOLID, 0)
  lcd.drawLine(start_x, start_y + 2, start_x, start_y + 50, SOLID, 0)
  lcd.drawLine(start_x, start_y + 50, start_x + batteryWidth - 1, start_y + 50, SOLID, 0)
  lcd.drawLine(start_x + batteryWidth, start_y + 3, start_x + batteryWidth, start_y + 49, SOLID, 0)

  -- top one eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 8, start_x + batteryWidth - 1, start_y + 8, SOLID, 0)
  -- top quarter line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 2), start_y + 14, start_x + batteryWidth - 1, start_y + 14, SOLID, 0)
  -- third eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 20, start_x + batteryWidth - 1, start_y + 20, SOLID, 0)
  -- Middle line
  lcd.drawLine(start_x + 1, start_y + 26, start_x + batteryWidth - 1, start_y + 26, SOLID, 0)
  -- five eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 32, start_x + batteryWidth - 1, start_y + 32, SOLID, 0)
  -- bottom quarter line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 2), start_y + 38, start_x + batteryWidth - 1, start_y + 38, SOLID, 0)
  -- seven eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 44, start_x + batteryWidth - 1, start_y + 44, SOLID, 0)
  
  -- Voltage top
  lcd.drawText(start_x + batteryWidth + 4, start_y + 0, "4.35v", SMLSIZE)
  -- Voltage middle
  lcd.drawText(start_x + batteryWidth + 4, start_y + 24, "3.82v", SMLSIZE)
  -- Voltage bottom
  lcd.drawText(start_x + batteryWidth + 4, start_y + 47, "3.3v", SMLSIZE)
  
  -- Now draw how full our voltage is...
  local voltage = getValue('VFAS')
  voltageLow = 3.3
  voltageHigh = 4.35
  voltageIncrement = ((voltageHigh - voltageLow) / 47)
  
  local offset = 0  -- Start from the bottom up
  while offset < 47 do
    if ((offset * voltageIncrement) + voltageLow) < tonumber(voltage) then
      lcd.drawLine( start_x + 1, start_y + 49 - offset, start_x + batteryWidth - 1, start_y + 49 - offset, SOLID, 0)
    end
    offset = offset + 1
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