local log = require('log')
local goveeapi = require("goveeapi")
local mdns = require('mdns')


local function find_httptunnel_server()
  local service = '_httptunnel._tcp'
  local res = mdns.query(service)
  if (res) then
    for service_name, service_data in pairs(res) do
      local ip, port = service_data.ipv4[1], service_data.port
      return true, service_name, ip, port
    end
  end

  return false, "Did not find " .. service
end


local function get_profile(dev)
  local function arrayEqual(a1, a2)
    -- Check length, or else the loop isn't valid.
    if #a1 ~= #a2 then
      return false
    end

    -- Check each element.
    for i1, v1 in ipairs(a1) do
      if v1 ~= a2[i1] then
        return false
      end
    end

    return true
  end

  if arrayEqual(dev.supportCmds, {"turn", "brightness", "color", "colorTem"}) then
    return "rgbw-light"
  elseif arrayEqual(dev.supportCmds, {"turn", "brightness", "color"}) then
    return "rgb-light"
  elseif arrayEqual(dev.supportCmds, {"turn", "brightness"}) then
    return "dimmable-light"
  elseif arrayEqual(dev.supportCmds, {"turn"}) then
    return "onoff-light"
  end

end


local function try_create_device(driver, dev)
  -- device metadata table
  local metadata = {
    type = 'LAN',
    device_network_id = dev.device,
    label = dev.deviceName,
    profile = get_profile(dev),
    manufacturer = 'Govee',
    model = dev.model
  }
  return driver:try_create_device(metadata)
end


local disco = {}

function disco.start(driver, opts, cons)
  log.info("Searching for HTTP Tunnel server")
  local status, host, ip, port = find_httptunnel_server()
  if not status then
    log.warn("Did not find the HTTP Tunnel server so skipping device discovery")
    return
  end

  log.info(string.format("Found %s at %s:%s", host, ip, port))
  driver.datastore.http_tunnel = { host = ip, port = port }

  log.info("Getting device list")
  local status, data = goveeapi.get_device_list(driver)
  if not status then
    log.warn("Failed to get device list: " .. data)
    return
  end

  for i,dev in ipairs(data) do
    log.info("Setting up device " .. dev.deviceName)
    try_create_device(driver, dev)
  end

  log.info("Discovery is complete")
end

return disco
