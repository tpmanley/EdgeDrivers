local caps = require('st.capabilities')
local utils = require('st.utils')
local log = require('log')
local goveeapi = require('goveeapi')

local command_handler = {}

------------------
-- Refresh command
function command_handler.refresh(_, device)
  local success, data = goveeapi.get_device_state(device)

  if success then
    for _, prop in ipairs(data.properties) do
      if prop.online == "true" then
        device:online()
      elseif prop.offline == "false" then
        device.offline()
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
        local calc_r = 255 - prop.color.r
        local calc_g = 255 - prop.color.g
        local calc_b = 255 - prop.color.b
        local hue, sta = utils.rgb_to_hsl(calc_r, calc_g, calc_b)
        device:emit_event(caps.colorControl.saturation(sta))
        device:emit_event(caps.colorControl.hue(hue))
      elseif prop.colorTemp then
        device:emit_event(caps.colorTemperature.colorTemperature(prop.colorTemp))
      end
    end
  else
    log.error('Failed to get device state: ' .. data)
    device:offline()
  end
end

----------------
-- Switch command
function command_handler.on_off(_, device, command)
  local on_off = command.command

  local success, msg = goveeapi.send_device_command(device, 'turn', on_off)

  if success then
    if on_off == 'off' then
      return device:emit_event(caps.switch.switch.off())
    end
    return device:emit_event(caps.switch.switch.on())
  else
    log.error("Failed to turn switch on or off: " .. msg)
  end
end

-----------------------
-- Switch level command
function command_handler.set_level(_, device, command)
  local lvl = command.args.level

  local success, msg = goveeapi.send_device_command(device, 'brightness', lvl)

  if success then
    if lvl == 0 then
      device:emit_event(caps.switch.switch.off())
    else
      device:emit_event(caps.switch.switch.on())
    end
    device:emit_event(caps.switchLevel.level(lvl))
    return
  else
    log.error("Failed to set brightness: " .. msg)
  end
end

------------------------
-- Color control command
function command_handler.set_color(_, device, command)
  local red, green, blue = utils.hsl_to_rgb(command.args.color.hue, command.args.color.saturation)

  local success, msg = goveeapi.send_device_command(device, 'color', {r=red, g=green, b=blue})

  if success then
    local hue, sta = utils.rgb_to_hsl(red, green, blue)
    device:emit_event(caps.switch.switch.on())
    device:emit_event(caps.colorControl.saturation(sta))
    device:emit_event(caps.colorControl.hue(hue))
    return
  else
    log.error("Failed to set color: " .. msg)
  end
end

------------------------
-- Color temperature command
function command_handler.set_color_temperature(_, device, command)
  local temp = command.args.temperature
  local success, msg = goveeapi.send_device_command(device, 'colorTem', temp)

  if success then
    return device:emit_event(caps.colorTemperature.colorTemperature(temp))
  else
    log.error("Failed to set color temperature: " .. msg)
  end
end

return command_handler
