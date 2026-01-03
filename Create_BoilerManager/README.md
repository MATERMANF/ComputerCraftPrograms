# Boiler Control for Create Mod

> [!NOTE]
> Additionally requires the [Fullerton Functions](https://github.com/MATERMANF/ComputerCraftPrograms/blob/Create_BoilerManager/fullerton_functions.lua) library file

This serves as a simple boiler manager and controller for boilers using the Create mod
Handles starting and stopping the boiler, monitoring, enabling/disabling output, as well as has a built-in watchdog.
When the program starts (from computer power off or otherwise), will automatically detect the on/off state of the boiler, as well as the output state (if the boiler is running)
This was designed to be modular to many different engine types, but only the boiler is configured. Also, touchscreen controls have only been implemented for one boiler. Tough luck, might fix later.
Assumes it is connected to an advanced monitor

## Starting Sequence
### 1. Turn on the starter
We assume the boiler has to be "bootstrapped" - that is, we assume that the boiler pumps its own fuel and water. So, this step attaches the initial rotational input (for example, a water wheel) to begin feeding lava and water to the boiler as this may take some time. This step also disabled the output of the boiler, 
as cold-starting the boiler while connected to a stress network may overstress the starter and result in a failed start
(In my example, the starter clutch is also tied to the lava pump speed. When the starter is on, the pump runs much faster, and afterward the pump runs slower so as not to waste lava. I'm no longer convinced however that lava was wasted, so you may not need to incorporate this)
### 2. Turn on the water pump
Due to the weak stress output of the water wheel, the water to the boiler was supplied by one single water pump. Once the boiler has received its water and begun adding stress to the system, we can connect the boiler to the primary water pump array at much higher speed. This will allow our boiler to reach higher output levels once fully fueled
### 3. Disable the starter and enable boiler output
When stage three initiates, the boiler should be receiving water from the primary water pumps, and all blaze burners should be fully-fueled. At this point, we are all good to disconnect the starter (which may or may not slow the lava pump to minimal viable speed), and finally restore the output state. 
The reason I say "restore" is you may not want your boiler output to be enabled automatically, so it will remember your choice. You can toggle the output on the monitor.

## Controls
- The left side of the monitor's touch screen toggles the boiler's state on or off.
- The right side of the monitor's touch screen toggles the boiler's output on or off.
> If the output is toggled off while the boiler is starting, the boiler will not automatically enable the output.

> [!NOTE]
> When the boiler is turned off, the output is also automatically disabled to prevent the SU network backfeeding power into it

## Display
Will display the total stress used and provided to the attached SU network, as well as the estimated maximum stress of all configured boilers.
Will also display the numerical count for how many boilers are actually on as compared to how many are configured. The intent is that at a future date it will automatically enable additional boilers as consumed stress approaches the max currently available, but this is not possible at the moment.
> [!WARNING]
> note, again, only fully supports for one boiler. This is a limitation of the touchscreen code (and watchdog code due to wanting a rough working version), as there is no way to turn on a second attached boiler, though it may be configured. Might get fixed in the future
