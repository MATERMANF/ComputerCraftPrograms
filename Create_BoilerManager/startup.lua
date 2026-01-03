-------- LIBRARIES
local CONST_BOILER_CONTROLS_VER = 1       -- Which iteration of the boiler controller to use
local Boiler = require("boiler_Template_"..CONST_BOILER_CONTROLS_VER)
local control = require("controls_template_1")

-------- CONFIG OPTIONS
local CONST_AUTOCYCLE = false
local CONST_AUTO_ON_TIME = 8
local CONST_AUTO_OFF_TIME = 3

local CONST_UPDATEINTERVAL = 20 -- seconds
local CONST_MONSIDE = "left"

CONST_BOILER_DISP_VER = 1       -- Which iteration of the boiler screen to display, might just put this in config

local CONST_HEADER_SIZE = 1/4
local CONST_FOOTER_SIZE = 1/8

local CONST_PANEL_ORDER = {
    {
        name="Boiler 1",
        type="boiler",
        config={
            control_config = {
                peripheral = "redstone_relay_2",
                outputs = {"top", "left", "right"}, -- Output enable, Starter enable, Water Pump enable
                inverted = {true, false, true}      -- If input should be inverted (like for a clutch)
            },
            maxStress = 98304
        }
    },
    {
        name="Controls",
        type="controls",
        config= {
            stress_meter = "Create_Stressometer_1"
        }
--    },
--    {
--        name="Boiler 2",
--        type="boiler",
--        config={
--            control_config = nil
--        }
    }
}

-------------------- END CONFIG
----------BEGIN CODE

panels = {} -- Control panels

powerOn_alarm = nil
powerOff_alarm = nil

------- Create/Resize all windows
--- objects - list of objects that need a window
--- header_size - % of screen should be header
--- footer_size - % of screen should be header
--- 
--- returns: wins - list of window objects
local function createWindows(objects, header_size, footer_size)
    local wins = {}
    for i = 0,#objects do
        wins[1+i] = window.create(mon, 1+math.ceil(i*(monSizeX/#objects)), 1+math.ceil(monSizeY*header_size), math.ceil(monSizeX/#objects), math.floor(monSizeY*(1-header_size) - monSizeY*footer_size))
    end

    if header_size ~= 0 then
        wins.header = window.create(mon, 1, 1, monSizeX, math.ceil(monSizeY*header_size))
    end
    if footer_size ~= 0 then
        wins.footer = window.create(mon, 1, math.ceil(monSizeY*(1-footer_size)), monSizeX, footer_size)
    end

    return wins
end

-------- Determine Click location
local function buttonHandler(pos)
    
end

------- Update everything on the screen
local function refresh()
    for _,x in ipairs(panels) do
        x:update()
    end
    if panels.footer ~= nil then
        panels.footer.setTextColor(colors.white)
        panels.footer.setCursorPos(1,3)
        panels.footer.write("Toggle Boiler")
        panels.footer.setCursorPos(1,15)
        panels.footer.write("Toggle Output")
    end
end

local function powerOff_handler()
    if panels[1]:getState() == "on" then
        panels[1]:setState("off")
        local time = os.epoch("local")
        time = math.floor(time/(72000*60*60)%24 + 0.5)  -- Find closest hour
        local deltaTime = CONST_AUTO_ON_TIME - time
        powerOn_alarm = os.startTimer(deltaTime*60*60)
    end
end

local function powerOn_handler()
    panels[1]:setState("on")
    local time = os.epoch("local")
    time = math.floor(time/(72000*60*60)%24 + 0.5)  -- Find closest hour
    local deltaTime = CONST_AUTO_OFF_TIME + math.max(0, 24 - time)
    powerOff_alarm = os.startTimer(deltaTime*60*60)
end

------- MAIN PROGRAM Setup --------

mon = peripheral.wrap(CONST_MONSIDE)  -- Find monitor
-- Initialize Monitor
mon.clear()
mon.setTextScale(.5)
monSizeX, monSizeY = mon.getSize()

-- Create list of window objects for each panel, includes header & footer
local temp_windows = createWindows(CONST_PANEL_ORDER, CONST_HEADER_SIZE, CONST_FOOTER_SIZE)

local controller_obj = nil

-- Create object for each panel type
for i = 1,#CONST_PANEL_ORDER do
    if CONST_PANEL_ORDER[i].type == "boiler" then
        table.insert(panels, boilerTemplate:create(CONST_PANEL_ORDER[i], temp_windows[i]))
    elseif CONST_PANEL_ORDER[i].type == "controls" then
        table.insert(panels, controlsTemplate:create(CONST_PANEL_ORDER[i], temp_windows[i]))
        if controller_obj == nil then
            controller_obj = panels[i]
        else
            error("Multiple controller panels set. Not currently supported.")
        end
    end
end

if controller_obj ~= nil then
    for i = 1, #panels-1 do
        if panels[i] ~= controller_obj then
            controller_obj:addBoiler(panels[i])
        end
    end
end

print("Number of panels: "..#panels)

refresh()

if CONST_AUTOCYCLE ~= true then
    local time = os.epoch("local")
    time = math.floor(time/(72000*60*60)%24 + 0.5)  -- Find closest hour
    local deltaTime = CONST_AUTO_OFF_TIME + math.max(0, 24 - time)
    powerOff_alarm = os.startTimer(deltaTime*60*60)
end

time = nil
deltaTime = nil

------- MAIN LOOP
while true do

    local refreshScreen_timer = os.startTimer(CONST_UPDATEINTERVAL)

    local event = {os.pullEvent()}  -- Check for events
    print("Event: "..event[1])
    if event[1] == "timer" then     -- If event was a timer, let each panel see if it should react
        if event[2] == powerOn_alarm then
            powerOn_handler()
        elseif event[2] == powerOff_alarm then
            powerOff_handler()
        elseif event[2] == refreshScreen_timer then
            print("Refresh time")
            refresh()
        -- wins.footer.setTextColor(colors.white)
        -- wins.footer.setCursorPos(1,3)
        -- wins.footer.write("Toggle Boiler")
        -- wins.footer.setCursorPos(1,15)
        -- wins.footer.write("Toggle Output")
        elseif event[2] == engineCheck_confirm then -- Check that engine restored correctly
            temp_windows.header.clear()
            if panels[1]:getState() == "off" then
                --temp_windows.header.print("Err: Boiler Restart Fail")
                print("Err: Engine not turned on correctly. Critical Error")
            end
                engineCheck_confirm = nil
        else
            for _,x in ipairs(panels) do
                x:timerHandler(event[2])    -- Pass timer id
            end
            refresh()
        end
    elseif event[1] == "monitor_touch" then
        if event[2] == CONST_MONSIDE then
            print("Handling monitor "..event[2])
            panels[1]:touchHandler({event[3],event[4]})
        end
        --print("Bad side "..event[2])
        refresh()
    else
        print("Unhandled event: "..event[1])
    end

    --Check engine and stress status (currently just if boiler is online)
    if panels[1]:getState() == "on" and panels[1]:getOutputEnabled() and panels[2]:getStressCapacity() == 0 then
        sleep(2)
        if panels[1]:getState() == "on" and panels[1]:getOutputEnabled() and panels[2]:getStressCapacity() == 0 then
            print("Err: Restoring boiler...")
            panels[1]:setState("off")
            
            panels[1]:setState("on")
            local engineCheck_confirm = os.startTimer(panels[1].power_on_delay + 30)
        end
    end
    
end
