# Govee Edge Driver

## API Documentation

This driver was built on API Version 1.4. It should work on newer versions
unless non-backwards compatible changes are introduced. The latest version
of the Govee API documentation is available here:

https://govee-public.s3.amazonaws.com/developer-docs/GoveeAPIReference.pdf

## Models Supported

See the API documentation for all the supported models. This was tested on
H6163 and H6199 but should support other Govee lights as well, including
on/off lights, dimmable lights, RGB lights, and other RGBW lights.

## Prequisite - Get API Key

1. Open the Govee Home mobile app
2. Go to the "My Profile" tab, press the gear icon, press "About us", 
   and press "Apply for API key"
3. Fill out your name and reason (the reason can be "I want to control
   my lights with SmartThings") and press Submit 
4. You will receive an email with your API key to the email address you
   entered when registering a Govee account normally within minutes.

## HTTP Tunnel Setup
This driver needs to talk to the Govee cloud, but the Edge Driver platform
does not currently allow drivers to talk to the external internet. Therefore,
it is necessary to run a proxy server on your local network. The driver
will communicate with the proxy server, and the server will talk to the
internet. The proxy server is acting as an [HTTP Tunnel](https://en.wikipedia.org/wiki/HTTP_tunnel).
The HTTP Tunnel and a mDNS responder have been packaged together using
Docker to make it easy to set up. Note that this only works on Linux due
to the `--net=host` part.

1. `git clone https://github.com/tpmanley/http-tunnel-server && cd http-tunnel-server`
2. `docker image build -t httptunnel .`
3. `docker run -d --net=host --rm --name httptunnel1 httptunnel`
   
## Driver Setup
1. Clone this repository
2. Enter your API key in src/config.lua
3. Package the driver, publish to your channel and install the driver
   on your hub. See the [getting started guide](https://developer-preview.smartthings.com/docs/devices/hub-connected/get-started)
   for more information on the detailed steps.
   
## Running the Driver
After the prior steps have been completed you can discover all your Govee
devices by going to the SmartThings App, go to Add device, and Scan for
nearby devices. If everything is working your a new device will be created
for each Govee device on your network.

## Known Bugs
* Setting the color temperature doesn't seem to work even the API returns success.

