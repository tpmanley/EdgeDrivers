local cosock = require('cosock')
local socket = cosock.asyncify("socket")
local ssl    = cosock.asyncify("ssl")
local ltn12  = require("ltn12")
local http   = cosock.asyncify("socket.http")
local url    = require("socket.url")
local log = require "log"


local try = function(...)
    local args = {...}
    if args[1] == nil then
        log.error("Error trying", socket.skip(1, ...))
        log.error(debug.traceback())
        error(socket.skip(1, ...))
    end
    return ...
end
local _M = {
    _VERSION   = "1.0.1",
    _COPYRIGHT = "LuaSec 1.0.1 - Copyright (C) 2009-2021 PUC-Rio",
    PORT    = 443,
    TIMEOUT =  60,
}

local cfg = {
    protocol = "any",
    options  = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"},
    verify   = "none",
}

local function default_https_port(u)
    return url.build(url.parse(u, {port = _M.PORT}))
end

local function urlstring_totable(url, body, result_table)
    url = {
        url = default_https_port(url),
        method = body and "POST" or "GET",
        sink = ltn12.sink.table(result_table)
    }
    if body then
        url.source = ltn12.source.string(body)
        url.headers = {
            ["content-length"] = #body,
            ["content-type"] = "application/x-www-form-urlencoded",
        }
    end
    return url
end

local function reg(conn)
    local mt = getmetatable(conn.sock).__index
    for name, method in pairs(mt) do
        if type(method) == "function" then
            conn[name] = function (self, ...)
                return method(self.sock, ...)
            end
        end
    end
end

local function tcp(params)
    params = params or {}
    for k, v in pairs(cfg) do
        params[k] = params[k] or v
    end
    params.mode = "client"

    return function()
        local conn = {}
        conn.sock = try(socket.tcp())
        local timeout = getmetatable(conn.sock).__index.settimeout
        function conn:settimeout(...)
            return timeout(self.sock, _M.TIMEOUT)
        end
        function conn:connect(host, port)
            log.trace("calling connect")
            try(self.sock:connect(params.http_tunnel.host, params.http_tunnel.port))
            log.trace("calling send")
            try(self.sock:send("CONNECT " .. host .. ":" .. port .. " HTTP/1.1\r\n"))
            log.trace("calling send again")
            try(self.sock:send("Host: " .. host .. ":" .. port .. "\r\n"))
            log.trace("calking final send")
            try(self.sock:send("\r\n\r\n"))

            log.trace("calling recv")
            local status, err = self.sock:receive()
            log.trace("recved", status, err)
            if err then return nil, err end
            if status ~= "HTTP/1.1 200 OK" then
                return nil, "Connection to tunnel failed with status: " .. status
            end
            log.trace("wrapping")
            self.sock = try(ssl.wrap(self.sock, params))
            self.sock:sni(host)
            self.sock:settimeout(_M.TIMEOUT)
            log.trace("handshaking")
            try(self.sock:dohandshake())
            reg(self, getmetatable(self.sock))
            log.trace("connected")
            return 1
        end
        return conn
    end
end

local function request(url, body)
    local result_table = {}
    local stringrequest = type(url) == "string"
    if stringrequest then
        url = urlstring_totable(url, body, result_table)
    else
        url.url = default_https_port(url.url)
    end
    if http.PROXY or url.proxy then
        return nil, "proxy not supported"
    elseif url.redirect then
        return nil, "redirect not supported"
    elseif url.create then
        return nil, "create function not permitted"
    end
    -- New 'create' function to establish a secure connection
    url.create = tcp(url)
    local res, code, headers, status = http.request(url)
    if res and stringrequest then
        return table.concat(result_table), code, headers, status
    end
    return res, code, headers, status
end

_M.tcp = tcp
_M.request = request

return _M
