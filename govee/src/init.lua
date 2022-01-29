local Driver = require('st.driver')
local caps = require('st.capabilities')
local log = require('log')

-- local imports
local discovery = require('discovery')
local commands = require('commands')
local capdefs = require('capabilitydefs')


local cap_textfield = caps.build_cap_from_json_string(capdefs.textField)
caps["partyvoice23922.textfield"] = cap_textfield

local CONFIG_DEVICE_NETWORK_ID = 'govee-config'

local function validate_api_key(driver, device)
    if driver.datastore.api_key ~= nil and driver.datastore.api_key ~= '' then
        device:emit_event(cap_textfield.text('API Key set'))
    else
        device:emit_event(cap_textfield.text('Set the API Key in Settings'))
    end
end

local function device_init(driver, device)
    if device.device_network_id ~= CONFIG_DEVICE_NETWORK_ID then
        commands.refresh(nil, device)
    else
        validate_api_key(driver, device)
        device:online()
    end
end

local function device_added(driver, device)
    device_init(driver, device)
end

local function info_changed(driver, device)
    if device.device_network_id == CONFIG_DEVICE_NETWORK_ID then
        driver.datastore.api_key = device.preferences.apikey
        log.info("Set API Key to " .. driver.datastore.api_key)
        validate_api_key(driver, device)
    end
end

local function try_create_config_device(driver)
    local metadata = {
        type = 'LAN',
        device_network_id = CONFIG_DEVICE_NETWORK_ID,
        label = 'Govee Config',
        profile = 'config',
        manufacturer = 'Govee',
        model = 'Configuration'
    }
    driver:try_create_device(metadata)
end

--------------------
-- Driver definition
local driver =
  Driver(
    'Govee',
    {
      discovery = discovery.start,
      lifecycle_handlers = {
          init = device_init,
          added = device_added,
          infoChanged = info_changed
      },
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
    for i, device in ipairs(driver:get_devices()) do
        if device.device_network_id ~= CONFIG_DEVICE_NETWORK_ID then
            commands.refresh(driver, device)
        end
    end
end

driver.refresh_loop = driver:call_on_schedule(300, refresh_all)

--------------------
-- Initialize Driver
try_create_config_device(driver)
driver:run()
