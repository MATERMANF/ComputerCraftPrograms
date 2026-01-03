-- Libraries
require("fullerton_functions")
-- Code

boilerTemplate = {
    name = "Boiler",
    state = nil,
    output_state = nil,
    timers = {
        state_transition = nil
    }
}



------- Create boiler object
--- Does not have visual component
--- Side table format for redstone relay: { output, starter, water_pump }
function boilerTemplate:create(panel_config, window)
    -- Create new object from template
    local obj = {} 
    --obj.parent = self
    setmetatable(obj, self)
    self.__index = self

    if panel_config.name ~= nil then
        obj.name = panel_config.name
    end

    if panel_config.config ~= nil and panel_config.config.control_config ~= nil and peripheral.isPresent(panel_config.config.control_config.peripheral) then
        obj.attributes = {  -- Setup for boiler controls
            periph = peripheral.wrap(panel_config.config.control_config.peripheral),  -- Route to boiler control redstone relay
            sides = {
                Output = panel_config.config.control_config.outputs[1], -- Connect boiler
                Starter = panel_config.config.control_config.outputs[2], -- Start up boiler
                WaterPump = panel_config.config.control_config.outputs[3] -- Whether or not boiler is running
            }
        }

        if panel_config.config.control_config.inverted ~= nil then
            obj.attributes.inverted = {
                Output = panel_config.config.control_config.inverted[1],
                Starter = panel_config.config.control_config.inverted[2],
                WaterPump = panel_config.config.control_config.inverted[3]
            }
        else
            obj.attributes.inverted = {
                Output = false,
                Starter = false,
                WaterPump = false
            }
        end

        if panel_config.config.maxStress ~= nil then
            obj.attributes.maxStress = panel_config.config.maxStress
        else
            obj.attributes.maxStress = -1
        end

        obj.output_state = xor(obj.attributes.periph.getOutput(obj.attributes.sides.Output), obj.attributes.inverted.Output)

        if xor(obj.attributes.periph.getOutput(obj.attributes.sides.WaterPump),obj.attributes.inverted.WaterPump) then
            obj.state = "on"
        else
            obj:setState("off")
        end

    else
        print("Incorrect/missing config for "..obj.name..", setting nil")
        if panel_config.config ~= nil and panel_config.config.control_config ~= nil then
        print(panel_config.config.control_config.peripheral)
        end
    end

    obj.window = window -- Add window object

    obj.power_on_delay = 100

    return obj

end

------- Handles drawing and updating the screen
function boilerTemplate:update()
    self.window.setBackgroundColor(colors.gray)
    self.window.setTextColor(colors.white)
    self.window.clear()
    self.window.setCursorPos(1,1)
    self.window.write("Gay "..CONST_BOILER_DISP_VER)
    self.window.setCursorPos(1,2)
    self.window.write(self.name)

    self.window.setCursorPos(1,5)
    if self.attributes ~= nil then
        self.window.write("State: ")
        if self.state == "off" then
            self.window.setTextColor(colors.red)
        elseif self.state == "on" then
            self.window.setTextColor(colors.green)
        else
            self.window.setTextColor(colors.yellow)
        end
        self.window.write(self.state)

        self.window.setCursorPos(1,6)
        self.window.setTextColor(colors.white)
        self.window.write("Output: ")
        if self:getOutputEnabled() then
            self.window.setTextColor(colors.green)
            self.window.write("Enabled")
        elseif self.output_state then
            self.window.setTextColor(colors.yellow)
            self.window.write("Enabled")
        else
            self.window.setTextColor(colors.red)
            self.window.write("Disabled")
        end
    else
        self.window.write("No controls!")
    end

end

------- Handles touch inputs
function boilerTemplate:touchHandler(touch_pos)
    if touch_pos[1] <= monSizeX/2 then
        if self:getState() == "off" then
            self:setState("on")
        else
            self:setState("off")
        end
    else
        self:setOutputEnabled(not self.output_state)
    end
end

------- Handles boiler state transitions
--- Valid requests: on, off
function boilerTemplate:setState(request_state)
    if (request_state == "on" or request_state == "starting_1") and self.state == "off" then
        self.state = "starting_1"       -- Sets state to starting_1, where the boiler has starter on
        print("Starting starter maybe? ")
        print(xor(true, self.attributes.inverted.Starter))
        self.attributes.periph.setOutput(self.attributes.sides.Starter, xor(true, self.attributes.inverted.Starter))
        self.timers.state_transition = os.startTimer(10)
    -- The two stages before final output
    elseif request_state == "starting_2" then
        self.state = "starting_2"         -- Sets state to starting_2, water pumps enabled
        self.attributes.periph.setOutput(self.attributes.sides.WaterPump, xor(true, self.attributes.inverted.WaterPump))
        self.timers.state_transition = os.startTimer(90)
    elseif request_state == "starting_3" then
        self.state = "on"
        self.attributes.periph.setOutput(self.attributes.sides.Starter, xor(false, self.attributes.inverted.Starter))
        self:setOutputEnabled(self.output_state)
    elseif request_state == "off" and self.state ~= "off" then
        self.state = "off"
        if self.timers.state_transition ~= nil then
            os.cancelAlarm(self.timers.state_transition)
        end
        self.timers.state_transition = nil
        self.attributes.periph.setOutput(self.attributes.sides.Output, xor(false, self.attributes.inverted.Output))
        self.attributes.periph.setOutput(self.attributes.sides.WaterPump, xor(false, self.attributes.inverted.WaterPump))
        self.attributes.periph.setOutput(self.attributes.sides.Starter, xor(false, self.attributes.inverted.Starter))
        
    end
end

function boilerTemplate:getState()
    return self.state
end

------- Gets boiler output state
function boilerTemplate:getOutputEnabled()
    return xor(self.attributes.periph.getOutput(self.attributes.sides.Output), self.attributes.inverted.Output)
end

------- Sets boiler output state. Boolean input
function boilerTemplate:setOutputEnabled(requestState)
    self.output_state = requestState
    if self:getState() == "on" then -- Only alter actual output signal if boiler is on, so not to break things
        self.attributes.periph.setOutput(self.attributes.sides.Output, xor(requestState, self.attributes.inverted.Output))
    end
end

------- Handles boiler timers
function boilerTemplate:timerHandler(timer_ID)
    print("Checking timer for "..self.name)
    if timer_ID == self.timers.state_transition then
        self.timers.state_transition = nil
        if self:getState() == "starting_1" then
            self:setState("starting_2")
        elseif self:getState() == "starting_2" then
            self:setState("starting_3")
        end
    end
end
