local Driver = require('st.driver')
local caps = require('st.capabilities')

-- local imports
local discovery = require('discovery')
local commands = require('commands')

local function device_added(driver, device)
    commands.refresh(nil, device)
end

--------------------
-- Driver definition
local driver =
  Driver(
    'Govee',
    {
      discovery = discovery.start,
      lifecycle_handlers = { added = device_added },
      supported_capabilities = {
        caps.switch,
        caps.switchLevel,
        caps.colorControl,
        caps.colorTemperature,
        caps.refresh
      },
      capability_handlers = {
        [caps.switch.ID] = {
          [caps.switch.commands.on.NAME] = commands.on_off,
          [caps.switch.commands.off.NAME] = commands.on_off
        },
        [caps.switchLevel.ID] = {
          [caps.switchLevel.commands.setLevel.NAME] = commands.set_level
        },
        [caps.colorControl.ID] = {
          [caps.colorControl.commands.setColor.NAME] = commands.set_color
        },
        [caps.colorTemperature.ID] = {
          [caps.colorTemperature.commands.setColorTemperature.NAME] = commands.set_color_temperature
        },
        [caps.refresh.ID] = {
          [caps.refresh.commands.refresh.NAME] = commands.refresh
        }
      }
    }
  )


local function refresh_all(driver)
    for i, device in ipairs(driver.get_devices()) do
        commands.refresh(driver, device)
    end
end

driver.refresh_loop = driver:call_on_schedule(300, refresh_all)

--------------------
-- Initialize Driver
driver:run()
