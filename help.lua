-------------------------------------------------------------
-- Original script by Alexey Gamov - dev@alexey-gamov(dot)ru
-- Git: https://github.com/alexey-gamov/opentx-quad-telemetry
-------------------------------------------------------------

-- Set up desired text to show on screen before using script
-- Total lines to show for tango2 is 9, for others is 6 only

local help = {
	[1] = 'SA: ARM (disarm)',
	[2] = 'SB: Acro/Angle/Horizon',
	[3] = 'SF: PreARM',
	[4] = 'SC: OSD profile (1-2-3)',
	[5] = 'SD: Beeper finder',
	[6] = 'SE: Flip over after crash',
	[8] = 'Check battery voltage and',
	[9] = 'VTX antenna before flight!'
}

local function run(event)
	lcd.clear()

	-- Draw caption text and fill it
	lcd.drawText(1, 1, "Assigned radio switches", SMLSIZE)
	lcd.drawFilledRectangle(0, 0, LCD_W, 9)

	-- Place toggle switch icon at right corner
	lcd.drawLine(LCD_W - 7, 2, LCD_W - 7, 2, SOLID, 0)
	lcd.drawLine(LCD_W - 7, 4, LCD_W - 7, 4, SOLID, 0)
	lcd.drawLine(LCD_W - 6, 6, LCD_W - 4, 6, SOLID, 0)
	lcd.drawLine(LCD_W - 5, 5, LCD_W - 5, 2, SOLID, 0)
	lcd.drawLine(LCD_W - 3, 2, LCD_W - 3, 2, SOLID, 0)
	lcd.drawLine(LCD_W - 3, 4, LCD_W - 3, 4, SOLID, 0)

	-- Go thru defined array and put lines on screen
	for line, text in pairs(help) do
		local src = string.lower(string.sub(text, 0, 2))
		local pos = getFieldInfo(src) and getValue(src) + 1024 or 0

		lcd.drawText(1, line * 9 + (LCD_H == 96 and 5 or 2), text, SMLSIZE + (pos > 0 and INVERS or 0))
	end
end

return { run = run }