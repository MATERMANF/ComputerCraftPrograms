-- Libraries
require("fullerton_functions")
-- Code

controlsTemplate = {
    name = "Control_Panel",
    boilers = {},   -- Format: { boiler_obj, max_stress }
    meter = nil,
    units = "SU",
    maxStress = 0,
    lastBoilerCheck_Lower = nil,
    timers = {
    }
}

------- Create boiler object
--- Does not have visual component
--- Side table format for redstone relay: { output, starter, water_pump }
function controlsTemplate:create(panel_config, window)
    -- Create new object from template
    local obj = {} 
    --obj.parent = self
    setmetatable(obj, self)
    self.__index = self

    if panel_config.name ~= nil then
        obj.name = panel_config.name
    end

    if panel_config.config ~= nil and peripheral.isPresent(panel_config.config.stress_meter) then
        obj.meter = peripheral.wrap(panel_config.config.stress_meter)  -- Route to stressometer for network

        if panel_config.config.units ~= nil then
            obj.units = panel_config.config.units
        end

    else
        print("Incorrect/missing config for "..obj.name..", setting nil")
        if panel_config.config ~= nil and panel_config.config.control_config ~= nil then
        print(panel_config.config.control_config.peripheral)
        end
    end

    obj.lastBoilerCheck_Lower = os.epoch()

    obj.window = window -- Add window object

    return obj

end

--  Add a boiler to the controller
-- Format: { boiler obj, max_stress }
function controlsTemplate:addBoiler(obj)   -- Add boiler to controls

    table.insert(self.boilers, obj)
    if obj.attributes.maxStress ~= -1 then
        self.maxStress = self.maxStress + obj.attributes.maxStress
    end

end

function controlsTemplate:getStress()
    if self.meter ~= nil then
        return self.meter.getStress()
    else
        return -1
    end
end

function controlsTemplate:getStressCapacity()
    if self.meter ~= nil then
        return self.meter.getStressCapacity()
    else
        return -1
    end
end


------- Handles drawing and updating the screen
function controlsTemplate:update()
    self.window.setBackgroundColor(colors.gray)
    self.window.setTextColor(colors.white)
    self.window.clear()
    self.window.setCursorPos(1,1)
    self.window.write("Gay ")
    self.window.setCursorPos(1,2)
    self.window.write(self.name)

    self.window.setCursorPos(1,5)

    self.window.write("Stress:")
    
    local stress = self:getStress()
    local maxStress = self:getStressCapacity()

    if stress / maxStress < .33 then
        self.window.setTextColor(colors.green)
    elseif stress/maxStress < .66 then
        self.window.setTextColor(colors.yellow)
    else
        if stress/maxStress > .8 then
            os.queueEvent("checkBoilers")
        end
        self.window.setTextColor(colors.red)
    end
    self.window.write(getNumberString(stress))
    self.window.setTextColor(colors.white)
    self.window.write("/")
    if maxStress / self.maxStress < .33 then
        self.window.setTextColor(colors.green)
    elseif maxStress/maxStress < .66 then
        self.window.setTextColor(colors.yellow)
    else
        self.window.setTextColor(colors.red)
    end
    self.window.write(getNumberString(maxStress))
    self.window.setTextColor(colors.white)
    self.window.write("/")
    self.window.write(getNumberString(self.maxStress))
    self.window.write(self.units)

    self.window.setCursorPos(1,6)
    self.window.setTextColor(colors.white)
    self.window.write("Engines: ")

    -- Get number of online boilers
    local numBoilOnline = 0
    for _,x in ipairs(self.boilers) do
        if x.state == "on" then
            numBoilOnline = numBoilOnline + 1
        end
    end
    self.window.write(numBoilOnline)
    self.window.write("/")
    self.window.setTextColor(colors.green)
    self.window.write(#self.boilers)
    self.window.setTextColor(colors.white)
    

end

function controlsTemplate:updateBoilers()

end

------- Handles touch inputs
function controlsTemplate:touchHandler(touch_pos)
    -- do nothing
end


------- Handles boiler timers
function controlsTemplate:timerHandler(timer_ID)
    print("Checking timer for "..self.name)
    -- No timers
end
