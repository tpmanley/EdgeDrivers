local log = require('log')
local mdns = require('mdns')

local tunnel = {}

function tunnel.refresh(driver)
  log.info("Searching for HTTP Tunnel server via mDNS")
  local res = mdns.query('_httptunnel._tcp')
  if res then
    for service_name, service_data in pairs(res) do
      local ip, port = service_data.ipv4[1], service_data.port
      log.info(string.format("Found HTTP Tunnel server %s at %s:%s", service_name, ip, port))
      driver.datastore.http_tunnel = { host = ip, port = port }
      return true
    end
  end
  log.warn("Did not find HTTP Tunnel server (_httptunnel._tcp)")
  return false
end

return tunnel
