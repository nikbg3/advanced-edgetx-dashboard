# OpenTX Quad telemetry dashboard

A simple lua-based dashboard for the OpenTX Monochrome LCD Transmitters

![opentx-quad-telemetry](https://i.postimg.cc/QM64DBPC/opentx-quad-telemetry.png)

## Features

* Transmitter battery status + Model name + Current time
* Battery voltage (*graphical and numerical)*
* RSSI signal strength *(graphical and icon)*
* Flight Timer - perfect for whooping
* ANIMATED QUAD WHEN ARMED !

### Plans

- Taranis X9D LCD support
- Crossfire LQ status
- GPS and telemetry screens
- Settings menu

## Author

* Original script by Andrew Farley - farley@neonsurge(dot)com
* Video: [Farleys Lua Dashboard - by DroneRacer101](http://www.youtube.com/watch?v=ijMYaCudgWI)
* Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard

## Installing

Download the `quad.lua` script above and drag it to your radio.

You should place this into your `/SCRIPTS/TELEMETRY` folder.

### Bootloader Method

1. Power off your transmitter and power it back on in boot loader mode.
1. Connect a USB cable and open the SD card drive on your computer.
1. Download and copy the the scripts to appropriate location on your SD card.
1. Unplug the USB cable and power cycle your transmitter.

### Manual method *(varies, based on the model of your transmitter)*

1. Power off your transmitter.
1. Remove the SD card and plug it into a computer
1. Download and copy the the scripts to appropriate location on your SD card.
1. Reinsert your SD card into the transmitter
1. Power up your transmitter.

If you copied the files correctly, you can now go into the **telemetry screen setup page** and set up the script as telemetry page.

## Adding the script as a telemetry page
  
Setting up the script as a telemetry page will enable access at the press of a button.

These instructions are for the **X-Lite**. The **Q7** will also work but the instructions will be a bit different.

1. Hold the circular eraser `D-Pad` on the right side of the controller to the right until the `Model Selection` menu comes up.
1. Press the `eraser` to the left briefly to rotate to page **13/13** *(top right)*
1. Press the `eraser` to the bottom position to select the **first screen** *(which should say none)*
1. Press down on the `eraser` so the **None** is flashing
1. Press right on the `eraser` repeatedly until it goes to **Script**, then press down on the `eraser` to confirm.
1. Press right on the `eraser` to select which script, then press down on the `eraser` should bring up a menu, and **quad** should be in there, select it and press down on the `eraser`.
1. Press the `bottom button` to back out to the **main menu**.
1. From now on, while on the main menu with this model, simply move the `eraser` to the bottom position for about 2 seconds and it will activate your **first telemetry screen**!