local log = require('log')
local json = require('dkjson')
local cosock = require('cosock')
local http = cosock.asyncify('httptunnel')
local ltn12 = require('ltn12')
local url = require('socket.url')

local goveeapi = {}

local function send_v1_request(driver, method, endpoint, json_body)
  log.debug(string.format("Sending %s %s", method, endpoint))

  local response_body = {}
  local request = {
    http_tunnel = driver.datastore.http_tunnel,
    method = method,
    url = "https://developer-api.govee.com/v1" .. endpoint,
    sink = ltn12.sink.table(response_body),
    headers = {
      ['Govee-API-Key'] = driver.datastore.api_key
    }
  }
  if json_body then
    request.source = ltn12.source.string(json_body)
    request.headers['Content-Type'] = 'application/json'
    request.headers['Content-Length'] = string.len(json_body)
  end

  local _, code = http.request(request)

  response_body = table.concat(response_body)

  if code == 200 then
    local obj, _pos, decode_err = json.decode(response_body)
    if obj then
      return true, obj
    else
      return false, decode_err
    end
  end
  return false, "API call returned error status: " .. code .. ", Message:" .. response_body
end


function goveeapi.send_device_command(device, cmd, value)
  local json_body = json.encode({
    device = device.device_network_id,
    model = device.model,
    cmd = {
      name = cmd,
      value = value
    }
  })

  return send_v1_request(device.driver, 'PUT', '/devices/control', json_body)
end

function goveeapi.get_device_state(device)
  local query_params = string.format("device=%s&model=%s",
          url.escape(device.device_network_id),
          url.escape(device.model))
  local status, response = send_v1_request(device.driver, 'GET', '/devices/state?' .. query_params, nil)
  if status then
    return true, response.data
  else
    return false, response
  end
end

function goveeapi.get_device_list(driver)
  local status, response = send_v1_request(driver, 'GET', '/devices', nil)
  if status then
    return true, response.data.devices or {}
  else
    return false, response
  end
end

return goveeapi
