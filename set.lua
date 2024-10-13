-- This is the settings screen
local shared = ...
local hovered = 1 -- Main select (arm, etc)
local selected = 0
local subHovered = 1 -- Switch or value
local subSelected = 0
local isSubMenu = false -- Determin if it is in the switch select menu
local subMenuHovered = 1

switchNameValue = { 'arm', 'acro', 'angle', 'horizon', 'turtle', 'air' }

function writeSwitch(func) -- arreglar
    shared.switchSettings[switchNameValue[func]]['switch'] =  names.possibleSwitches[subMenuHovered]
    names.switches[selected] = names.possibleSwitches[subMenuHovered]
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function writeValue(func)
    shared.switchSettings[switchNameValue[func]]['target'] = (getValue(shared.switchSettings[switchNameValue[func]]['switch']) + 1024) / 20.48
    names.targets[func] = (getValue(shared.switchSettings[switchNameValue[func]]['switch']) + 1024) / 20.48
    loadfile("/SCRIPTS/TELEMETRY/saveTable.lua")(shared.switchSettings, "/SCRIPTS/TELEMETRY/savedData.txt")
end

function menuLogic(event)
    if event == EVT_ENTER_BREAK then
        if selected == 0 and not isSub and not isSubMenu then-- if it is hovering the main main menu
            selected = hovered
        elseif selected ~= 0 and subHovered == 1 and not isSubMenu then
            isSubMenu = true
        elseif isSubMenu then
            writeSwitch(selected)
            isSubMenu = false
        elseif subHovered == 2 and subSelected == 0 then
            subSelected = 2
        elseif subSelected == 2 then
            writeValue(selected)
            subSelected = 0
            subHovered = 2
        end
    end
    if event == EVT_ROT_RIGHT then
        if selected == 0 then
            hovered = hovered +1
            if hovered > 6 then
                hovered = 6
            end
        elseif not isSubMenu then
            subHovered = 2
        else
            subMenuHovered = subMenuHovered + 1
            if subMenuHovered > 9 then
                subMenuHovered = 9
            end
        end
    end
    if event == EVT_ROT_LEFT then
        if selected == 0 then -- for main selection
            hovered = hovered - 1
            if hovered < 1 then
                hovered = 1
            end
        elseif not isSubMenu and subSelected == 0 then-- for sub selection
            subHovered = 1
        else -- For sub menu
            subMenuHovered = subMenuHovered - 1
            if subMenuHovered < 1 then
                subMenuHovered = 1
            end
        end
    end
    if event == EVT_EXIT_BREAK then
        if not isSubMenu and selected ~= 0 and subSelected ~= 2 then
            subHovered = 1
            selected = 0
        elseif selected == 0 then
            shared.changeScreen(-1)
        elseif subSelected == 2then
            subSelected = 0
        elseif isSubMenu then
            isSubMenu = false
        end

    end
end

valuesIndex = { [0] = 'Up', [25] = 'Up-Mid', [50] = 'Mid', [75] = 'Mid-Dn', [100] = 'Dn' }

names = {
    names = { 'ARM SWITCH = ', 'ACRO SWITCH = ', 'ANGLE SWITCH =', 'HRZN SWITCH = ', 'TURTLE SWITCH =', 'AIR SWITCH =' },
    switches = {
        shared.switchSettings.arm.switch,
        shared.switchSettings.acro.switch,
        shared.switchSettings.angle.switch,
        shared.switchSettings.horizon.switch,
        shared.switchSettings.turtle.switch,
        shared.switchSettings.air.switch
    },
    possibleSwitches = { 'sa', 'sc', 'se', 'sg', 'sb', 'sd', 'sf', 'sh', 'None' },
    targets = {
        shared.switchSettings.arm.target,
        shared.switchSettings.acro.target,
        shared.switchSettings.angle.target,
        shared.switchSettings.horizon.target,
        shared.switchSettings.turtle.target,
        shared.switchSettings.air.target

    },
}

function mainMenu()
    -- Draw title
    lcd.drawText(screen.w / 2 - #'CONFIG' * 2.5, 2, 'CONFIG', SMLSIZE + INVERS)
    for i = 18, 54, 9 do
        lcd.drawLine(1, i, screen.w - 2, i, SOLID, 0)
    end
    for idx, item in pairs(names.names) do
        offset = (idx + 1) * 9 - 7
        lcd.drawText(2, offset, item, SMLSIZE + ((hovered == idx and INVERS) or 0) + (((hovered == idx and selected == idx) and BLINK) or 0))
        lcd.drawText(screen.w - 48, offset, string.upper(names.switches[idx]), SMLSIZE + ((selected == idx and subHovered == 1) and INVERS or 0))
        lcd.drawText(screen.w - 23, offset, valuesIndex[((selected == idx and subSelected == 2) and (getValue(names.switches[idx]) + 1024) / 20.48) or names.targets[idx]], SMLSIZE + ((selected == idx and subHovered == 2) and INVERS or 0) + ((selected == idx and subSelected == 2) and BLINK or 0))
    end
end

function subMenu(func)
    lcd.drawText(screen.w / 2 - #'SELECT SWITCH' * 2.5, 2, 'SELECT SWITCH', SMLSIZE + INVERS)
    for idx, switch in pairs (names.possibleSwitches) do
        -- Change x
        if idx < 5 then
            xoffset = screen.w / 2 - 33
            yoffset = idx * 9 + 2
        elseif idx < 9 then
            yoffset = idx * 9 - 34
            xoffset = screen.w / 2 + 19
        elseif idx == 9 then
            xoffset = screen.w / 2 - #'None' * 2.5
            yoffset = 47
        end
        lcd.drawText(xoffset, yoffset, string.upper(switch), SMLSIZE + (subMenuHovered == idx and INVERS or 0))
    end
end

function shared.run(event)
    lcd.clear()

    menuLogic(event)

    -- Draw main rectangle
    lcd.drawRectangle(0, 0, screen.w, screen.h)

    -- Draw title and rectangle
    lcd.drawFilledRectangle(1, 1, screen.w - 2, 9)
    if isSubMenu == true then
        subMenu(selected)
    else
        mainMenu()
    end
end
