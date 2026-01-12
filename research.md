Philips Hue offers a local REST API (v1 and v2) plus a cloud “Remote API,” and there are now several MCP servers and libraries that make it straightforward for Claude Code to discover and control your lights programmatically.[1][2]

Below is a curated map of the official docs, high‑quality technical blogs, libraries, and Claude/MCP-focused projects you can wire into your setup.

***

## Official Hue developer docs

- **Hue Developer Program (root)**
  - Entry point for all Hue APIs (local and remote), SDKs, and examples.[2]
  - Includes sections for the local bridge API, Remote API, motion, entertainment, etc.[2]

- **Local bridge API: v1 and v2**
  - **Get Started guide**: shows discovery of the bridge, link-button auth, and the built-in test web app on the bridge for experimenting with REST calls.[3]
  - **New Hue API (v2)**: describes the newer resource model (rooms/zones, scenes, events, gradients, dynamic scenes) and coexistence with the v1 API.[1]
  - **Unofficial reference**: “Philips Hue API — Unofficial Reference Documentation” gives a very detailed view of typical workflow, system state, endpoints, and payload shapes for v1.[4]

- **Remote API / OAuth2**
  - Developer portal guides on creating a “Remote Hue API app,” registering callback URLs and using OAuth2 for cloud access to bridges not on the local network.[5][6]
  - These flow docs mirror standard authorization-code OAuth2, with Hue-specific parameters and endpoints.[7][5]

***

## Technical blogs and walkthroughs

- **Local API & general hacking**
  - *Hacking Philips Hue – Getting Started* (TechnoChic): hands-on intro to using the bridge’s API debug tool and simple HTTP requests for lights.[8]
  - *AWS & IoT – Philips Hue Lights, Part 2: The API*: step-by-step C# example of creating a user (`POST /api` with `devicetype`), loading base URL and username from config, and sending `GET`/`PUT`/`POST` via `HttpClient`.[9]

- **Remote API & OAuth2 flows**
  - *Remote Authentication and Controlling Philips Hue API using Postman*: shows setting up a Remote Hue API app, configuring OAuth 2.0 in Postman, building auth and token URLs, and whitelisting a device/user.[5]
  - *Philips Hue remote API – Power Platform integration*: demonstrates using Hue’s OAuth 2.0 remote API with Power Platform, including registering an app, copying client id/secret, and generating tokens.[7]
  - Postman’s public *API for Philips Hue* collection and docs: collection of prebuilt requests for discovering the bridge, listing lights, and changing color/brightness/saturation, with documentation integrated in Postman.[10][11]

- **JavaScript-focused**
  - Auth0’s *How to Control Hue Lights with JavaScript*: shows discovering the Hue bridge, authenticating, and sending HTTP requests from JS to change light states via the local API.[12]

- **Community notes on v2**
  - *Philips Hue configuration (API v2)* in HyperHDR and OpenHAB Hue v2 binding docs give practical descriptions of the v2 resource model and show example payloads and dynamic transitions.[13][14]
  - *tigoe/hue-control* notes also highlight that v2 is superseding v1 and compare behavior.[15]

***

## Client libraries and SDKs (good Claude/MCP building blocks)

These are the main open source libraries you’d likely wrap into Claude Code tools or MCP servers.

### General SDK

- **PhilipsHue/HueSDK (official)**
  - Java and Objective‑C SDK with sample apps for Android, Windows, Ubuntu, macOS, iOS, watchOS, tvOS.[16]
  - Encapsulates discovery, authentication, and lamp/group/scene control around the bridge.[16]

### Python

- **studioimaginaire/phue**
  - Popular, full‑featured Python library for Hue; supports lights, groups, schedules, scenes, sensors and is compliant with Hue API 1.0.[17]
  - Installable via `pip install phue`; implemented as a single `phue.py` with procedural and OO usage options.[17]

- **aleroddepaz/pyhue**
  - Python library providing an object‑oriented mapping of the RESTful Hue interface, covering major v1 entities (lights, groups, schedules) and basic color model conversions.[18]
  - Example usage: connect with `pyhue.Bridge('ip','username')` and iterate lights, toggling `on` and `hue` attributes.[18]

- **quentinsf/qhue**
  - Very lightweight Python wrapper that maps the REST API into Python with minimal abstraction, aimed at staying close to raw endpoints.[19]

- **Adafruit_CircuitPython_Hue**
  - CircuitPython helper for Hue, useful if integrating microcontroller workflows or IoT devices that then talk to Claude.[20]

### Go

- **amimof/huego**
  - Extensive Hue client library for Go that supports lights, groups, scenes, sensors, rules, schedules, resourcelinks, capabilities, and configuration.[21]
  - Designed to be clean and extensible, with full package docs on GoDoc.[21]

- **OpenHue Go (community library)**
  - Another Go library focusing on interacting with Hue systems; discussed on r/golang and used in open source projects like `lampy` for bridge discovery and control.[22]

### Node/TypeScript & others

- **node-hue-api & v2 shim**
  - `node-hue-api-v2-shim` docs explain how the library exposes bridge discovery via `http://meethue.com/api/nupnp` and provides higher-level accessors for Hue v1/v2.[23]
  - Good basis for a Node-based MCP server or custom Claude tool wrapper.

***

## Claude Code / MCP-focused Hue projects

These are directly relevant to “let Claude Code control the system and configure it.”

### Model Context Protocol (MCP) servers

- **ThomasRohde/hue-mcp (Python + phue)**
  - MCP server that connects to Philips Hue via the `phue` Python library and exposes lights, groups, scenes, and configuration as MCP resources and tools.[24]
  - Quick start: `pip install phue mcp`, run `python hue_server.py`, then install into Claude Desktop using `mcp install hue_server.py --name "My Hue Lights"`.[24]
  - Provides example prompts like “show me which lights I have available” and describes how the server authenticates to the bridge and exposes structured operations for Claude.[24]

- **rmrfslashbin/hue-mcp (Node/TypeScript)**
  - Modern Node.js MCP server that talks to a Hue Bridge v2 and is designed for AI assistants like Claude to control lighting via natural language.[25]
  - Quick start: clone, `npm install`, run server; then add an `mcpServers` entry in `claude_desktop_config.json` on macOS or Windows pointing to the Node command and args.[25]
  - Implements configuration tooling and resource definitions tailored for Hue v2.[25]

- **ykhli/mcp-light-control (Morse code light MCP)**
  - MCP server that controls Philips Hue lights and uses them to transmit messages in Morse code, intended for Cursor or Claude Desktop.[26]
  - Example MCP config shows how to wire it into Claude, passing `HUE_USERNAME` and `BRIDGE_IP` via `env` for authentication.[26]

### Other AI-oriented examples

- Various blog posts and code like `lampy` in the OpenHue Go thread show patterns that can be adapted for MCP servers or custom Claude tools (bridge discovery, scene management, etc.).[22]

***

## Practical starting points for your Claude integration

For a hands‑on Claude Code / MCP Hue setup, the most relevant resources to start from are:

- **Docs**
  - Get started + New v2 API pages to understand the model and auth.[3][1][2]
  - Unofficial API reference for concrete endpoint behaviors.[4]

- **Libraries**
  - Python: `phue` or `pyhue` if you want a Python MCP server.[18][17]
  - Go: `huego` or OpenHue Go if you prefer Go-based tooling.[22][21]
  - Node: node‑hue‑api / v2 shim for a TypeScript/Node stack.[23]

- **Existing MCP servers**
  - `ThomasRohde/hue-mcp` (Python) and `rmrfslashbin/hue-mcp` (Node) as ready-made or modifiable MCP servers wired for Claude Desktop.[24][25]
  - `mcp-light-control` if you want an example with custom behaviors (like Morse code signaling).[26]

If you want, a next step could be a minimal Claude-focused MCP server skeleton (Python or Node) that wraps the local v2 API and exposes “list lights / set scene / set effect” tools you can drop into Claude Desktop.

[1](https://developers.meethue.com/new-hue-api/)
[2](https://developers.meethue.com)
[3](https://developers.meethue.com/develop/get-started-2/)
[4](https://www.burgestrand.se/hue-api/)
[5](https://gotoguy.blog/2020/05/21/remote-authentication-and-controlling-philips-hue-api-using-postman/)
[6](https://developer.transmitsecurity.com/guides/automated-workflows/integrations/builtin/credentials/philipshue)
[7](https://ashiqf.com/tag/philips-hue-remote-api/)
[8](https://technochic.net/blogs/works-in-progress/hacking-philips-hue-getting-started)
[9](https://davidpallmann.hashnode.dev/aws-iot-philips-hue-lights-part-2-the-api)
[10](https://www.postman.com/postman/program-smart-lights/collection/it5d52v/api-for-philips-hue)
[11](https://www.postman.com/postman/program-smart-lights/documentation/it5d52v/api-for-philips-hue)
[12](https://auth0.com/blog/how-to-control-hue-lights-with-javascript/)
[13](https://github.com/awawa-dev/HyperHDR/discussions/512)
[14](https://www.openhab.org/addons/bindings/hue/doc/readme_v2.html)
[15](https://github.com/tigoe/hue-control)
[16](https://github.com/PhilipsHue/HueSDK)
[17](https://github.com/studioimaginaire/phue)
[18](https://github.com/aleroddepaz/pyhue)
[19](https://github.com/quentinsf/qhue)
[20](https://github.com/adafruit/Adafruit_CircuitPython_Hue)
[21](https://github.com/amimof/huego)
[22](https://www.reddit.com/r/golang/comments/1dw1wq5/openhue_go_is_a_library_written_in_golang_for/)
[23](https://github.com/peter-murray/node-hue-api-v2-shim/blob/master/docs/v2_api.md)
[24](https://github.com/ThomasRohde/hue-mcp)
[25](https://github.com/rmrfslashbin/hue-mcp)
[26](https://github.com/ykhli/mcp-light-control)
[27](https://hueblog.com/2021/07/13/new-api-makes-interaction-with-philips-hue-faster/)
[28](https://stackoverflow.com/questions/77630850/activating-a-scene-for-a-room-or-a-zone-using-philips-hue-api-v2)
[29](https://community.auth0.com/t/custom-social-connections-extension-philips-hue-oauth-2/12178)