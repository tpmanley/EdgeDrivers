local Driver = require('st.driver')
local caps = require('st.capabilities')
local socket = require('socket')


local function start_discovery(driver, device)
    cats = {"RemoteController",
            "Siren",
            "CurbPowerMeter",
            "Vent",
            "Switch",
            "GenericSensor",
            "SmartPlug",
            "MultiFunctionalSensor",
            "LeakSensor",
            "ContactSensor",
            "MotionSensor",
            "LightSensor",
            "Thermostat",
            "SmartLock",
            "PresenceSensor",
            "WaterValve",
            "Light",
            "Blind",
            "SmokeDetector",
            "GarageDoor",
            "Fan",
            "Bridges",
            "NetworkAudio"}
    for i, cat in ipairs(cats) do
        local metadata = {
            type = 'LAN',
            device_network_id = "icontest" .. i,
            label = "IconTest-" .. cat,
            profile = cat,
            manufacturer = 'SmartThings',
            model = cat
        }
        driver:try_create_device(metadata)
        socket.sleep(1)
    end

end

local function device_added(driver, device)
    device:emit_event(caps.switch.switch.off())
end

local function command_on_off(_, device, command)
    local on_off = command.command

    if on_off == 'off' then
        return device:emit_event(caps.switch.switch.off())
    end
    return device:emit_event(caps.switch.switch.on())

end

--------------------
-- Driver definition
local driver =
  Driver(
    'Icon Test',
    {
      discovery = start_discovery,
      lifecycle_handlers = { added = device_added },
      supported_capabilities = {
        caps.switch
      },
      capability_handlers = {
        [caps.switch.ID] = {
          [caps.switch.commands.on.NAME] = command_on_off,
          [caps.switch.commands.off.NAME] = command_on_off
        }
      }
    }
  )

--------------------
-- Initialize Driver
driver:run()
