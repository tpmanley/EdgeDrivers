local caps = require('st.capabilities')
local utils = require('st.utils')
local log = require('log')
local goveeapi = require('goveeapi')

local command_handler = {}

-- A non-numeric code means the request never got a response (tunnel or network
-- failure), so the device can't be reached from the hub.
local function handle_command_failure(device, what, msg, code)
  log.error(string.format("Failed to %s: %s", what, tostring(msg)))
  if type(code) ~= 'number' then
    device:offline()
  end
end

------------------
-- Refresh command
function command_handler.refresh(_, device)
  local success, data, code = goveeapi.get_device_state(device)

  if success then
    for _, prop in ipairs(data.properties) do
      if prop.online ~= nil then
        -- The Govee API has been seen to report this as either a boolean or a string
        if tostring(prop.online) == "true" then
          device:online()
        else
          log.info(string.format("Govee reports %s is not connected, marking offline", device.label))
          device:offline()
        end
      elseif prop.brightness then
        device:emit_event(caps.switchLevel.level(prop.brightness))
        if prop.brightness == 0 then
          device:emit_event(caps.switch.switch.off())
        end
      elseif prop.powerState == "off" then
        device:emit_event(caps.switch.switch.off())
      elseif prop.powerState == "on" then
        device:emit_event(caps.switch.switch.on())
      elseif prop.color then
        local hue, sta = utils.rgb_to_hsl(prop.color.r, prop.color.g, prop.color.b)
        device:emit_event(caps.colorControl.saturation(sta))
        device:emit_event(caps.colorControl.hue(hue))
      elseif prop.colorTem and prop.colorTem > 0 then
        -- Govee may report 0 while the light is in color mode
        device:emit_event(caps.colorTemperature.colorTemperature(prop.colorTem))
      end
    end
  elseif code == 429 then
    -- Rate limited; this says nothing about whether the device is reachable
    log.warn('Rate limited while getting device state: ' .. tostring(data))
  elseif type(code) == 'number' then
    -- The Govee cloud answered with an error, so the device may still be reachable
    log.error('Failed to get device state: ' .. tostring(data))
  else
    log.error('Failed to get device state, marking offline: ' .. tostring(data))
    device:offline()
  end
end

----------------
-- Switch command
function command_handler.on_off(_, device, command)
  local on_off = command.command

  local success, msg, code = goveeapi.send_device_command(device, 'turn', on_off)

  if success then
    device:online()
    if on_off == 'off' then
      return device:emit_event(caps.switch.switch.off())
    end
    return device:emit_event(caps.switch.switch.on())
  else
    handle_command_failure(device, "turn switch on or off", msg, code)
  end
end

-----------------------
-- Switch level command
function command_handler.set_level(_, device, command)
  local lvl = command.args.level

  local success, msg, code = goveeapi.send_device_command(device, 'brightness', lvl)

  if success then
    device:online()
    if lvl == 0 then
      device:emit_event(caps.switch.switch.off())
    else
      device:emit_event(caps.switch.switch.on())
    end
    device:emit_event(caps.switchLevel.level(lvl))
    return
  else
    handle_command_failure(device, "set brightness", msg, code)
  end
end

------------------------
-- Color control command
function command_handler.set_color(_, device, command)
  local red, green, blue = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)

  local success, msg, code = goveeapi.send_device_command(device, 'color', {r=red, g=green, b=blue})

  if success then
    device:online()
    local hue, sta = utils.rgb_to_hsl(red, green, blue)
    device:emit_event(caps.switch.switch.on())
    device:emit_event(caps.colorControl.saturation(sta))
    device:emit_event(caps.colorControl.hue(hue))
    return
  else
    handle_command_failure(device, "set color", msg, code)
  end
end

------------------------
-- Color temperature command
function command_handler.set_color_temperature(_, device, command)
  local temp = command.args.temperature
  local success, msg, code = goveeapi.send_device_command(device, 'colorTem', temp)

  if success then
    device:online()
    return device:emit_event(caps.colorTemperature.colorTemperature(temp))
  else
    handle_command_failure(device, "set color temperature", msg, code)
  end
end

return command_handler
