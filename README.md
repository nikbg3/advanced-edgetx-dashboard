# EdgeTX Quad telemetry dashboard

# Addiotions to this FORK are the following features added by me (Nikolay Kolev):
* Battery voltage is moved next to the battery
* Now we show full battery voltage next to the average cell voltage
* Showing CORE temperature
* Checklist when you plug new battery. The checklist is read from the model's checklist file (samples included)
* Audio when checklist is opened or completed
* Model setting files that currently only setup if the model has GPS and based on that GPS mode is shown or ommitted
* Air mode added to settings instead of pre-arm

Advanced lua-based dashboard for the EdgeTX Monochrome LCD Transmitters

![opentx-quad-telemetry](https://i.postimg.cc/Jz1CdwTG/opentx-quad-telemetry.gif)

## Features

* Transmitter battery + Model name + Time
* Battery voltage (graphical and numerical)
* RX signal strength (graphical and icon)
* Flight Timer *(perfect for whooping)*
* Gps
* Settings Menu
* ANIMATED QUAD WHEN ARMED !

### Additional

- Crossfire,  ExpressLRS, Ghost, and FrSky telemetry support
- Works with bigger screens *(Tango2, X9D)*
- Shows avarage battery cells voltage

## Author

* Original script by Andrew Farley - farley@neonsurge(dot)com
* Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard
* Modified Script by Alexey Gamov
* Git : https://github.com/alexey-gamov/opentx-quad-telemetry
* Even more modified Script (this one) by mvaldesshc
* Git : https://github.com/mvaldesshc/advanced-edgetx-dashboard

## Installing

1. Download the scripts `mana.lua`, `saveTable.lua`, `tele.lua`, and `set.lua` script above **(code -> download zip)**.
1. Place **ALL** scripts into your `/SCRIPTS/TELEMETRY` folder on the radio.
#### -OR-

1.Download the release .zip and extract it into your radio sd cart main folder.

#### Bootloader Method

1. Power off your transmitter and power it back on in bootloader mode.
1. Connect a USB cable and open the SD card drive on your computer.
1. Put the script file to appropriate folder.
1. Unplug the USB cable and power cycle your transmitter.

#### Manual method

1. Power off your transmitter.
1. Remove the SD card and plug it into a computer
1. Put the script file to appropriate folder.
1. Reinsert your SD card into the transmitter.
1. Power up your transmitter.

If you copied the files correctly, you can now follow next step and **set up the script as telemetry page**.

## Setting telemetry page

These instructions are for the **X9 Lite**, so please be aware the steps may vary slightly for your device.

1. Hit the <kbd>MENU</kbd> button and select the model for which you would like to enable the script.
1. While on the `MODEL SEL` screen, long-press the <kbd>PAGE</kbd> button to navigate to the `DISPLAY` page.
1. Move the cursor to a free screen and hit <kbd>ENTER</kbd>.
1. Scroll and select the `Script` option and press <kbd>ENTER</kbd>.
1. Move the cursor to the script selection field `---` and hit <kbd>ENTER</kbd>.
1. Select one of the listed telemetry scripts and press <kbd>ENTER</kbd>.
1. Long-press <kbd>EXIT</kbd> to return to your model screen.

## Usage

To **invoke the script**, simply long-press the <kbd>PAGE</kbd> button or shortly press <kbd>TELE</kbd> from the **model screen**.

Shortly press <kbd>EXIT</kbd> or <kbd>RTN</kbd> to display **Transmitter output** info *(for crossfire)* and **Mah and current**.

To acces the **switch configuration**, shortly press the rotary thing. 
To **exit** the configuration page, to cancel, shortly press <kbd>EXIT</kbd> or <kbd>RTN</kbd>.
