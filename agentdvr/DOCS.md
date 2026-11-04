# Agent DVR

Agent DVR is free video surveillance software for IP, ONVIF and USB cameras. It records locally, detects people, vehicles and animals with built-in AI, and sends alerts. This app runs it on your Home Assistant machine.

## Installation

1. Install the app and start it. The first start can take a minute or two, especially on a Raspberry Pi.
2. Turn on **Show in sidebar** on the app's page, then click **Agent DVR** in Home Assistant's sidebar. **Open Web UI** opens the same view.
3. Add your cameras: click **Edit**, then **New Device**. **ONVIF** finds most cameras on your network automatically. For anything else, the [camera database](https://www.ispyconnect.com/cameras) has connection URLs for thousands of models.

You can also open Agent DVR directly at `http://<your-home-assistant-ip>:8090`, for example in Agent DVR's own mobile app or a browser on another device. Use the machine's IP address, not `localhost`.

## Connect it to Home Assistant

There are two ways, and they work together.

**Automatic, over MQTT.** If you use Home Assistant's **Mosquitto broker** app (with the MQTT integration that Home Assistant offers to set up for it), Agent DVR connects to it by itself and turns on Home Assistant discovery. Your cameras and microphones, including any you already had, then appear in Home Assistant as a device with motion, alert, connected and recording sensors, switches to arm, enable or disable it, and a snapshot of the camera that updates on motion and alerts, with no setup. Install Mosquitto before Agent DVR, or restart Agent DVR after installing it. If you've already set up a different MQTT broker in Agent DVR, it's left as it is. See [Home Assistant in the user guide](https://www.ispyconnect.com/docs/agent/mqtt#home-assistant).

Renaming cameras or the server in Agent DVR updates Home Assistant automatically. If you uninstall the app, its devices stay in Home Assistant: delete them under **Settings > Devices & services > MQTT**.

**The Agent DVR integration** adds your cameras' live video, an alarm panel and recording actions:

1. Go to **Settings > Devices & services > Add integration** and choose **Agent DVR**.
2. Enter host `127.0.0.1` and port `8090`.

See the [integration documentation](https://www.home-assistant.io/integrations/agent_dvr/) for details.

## Where things are stored

| What | Where |
|------|-------|
| Settings (cameras, users, storage) | The app's config folder. In the Samba or SSH apps, look under `addon_configs` for the folder ending in `_agentdvr` |
| Recordings | `/media/agentdvr`, also visible in Home Assistant's **Media** panel |
| AI models, custom commands, overlays, floorplans, sounds | The app's private data folder |

Turn on automatic clean-up of old recordings, or add more storage locations, in **Server Settings > Storage** inside Agent DVR. Network storage that you've added to Home Assistant under **Settings > System > Storage** appears under `/media` and can be used as a storage location.

## Backups

Home Assistant backups of this app include your settings. They don't include recordings, which live in `/media`, or AI models, which Agent DVR downloads again when needed.

## Hardware acceleration

Intel and AMD GPUs are passed through to the app automatically. Turn on GPU decoding in each camera's settings in Agent DVR.

## Networking

The app uses host networking, so these ports must be free on your Home Assistant machine:

- `8090` TCP: web UI
- `3478` UDP and TCP: WebRTC connection setup
- `50000-50100` UDP: WebRTC live video

## Remote access

Agent DVR is free for personal, local use. Viewing it from outside your home network is remote access, which needs an Agent DVR subscription. See [pricing](https://www.ispyconnect.com/buy), then activate your license in **Server Settings > Licensing**.

This includes opening the Agent DVR sidebar panel through Home Assistant's own remote access (Home Assistant Cloud / Nabu Casa, or a tunnel or reverse proxy app): without a subscription the panel explains this instead of opening Agent DVR. With one, live video works best through Agent DVR's own remote access at [ispyconnect.com](https://www.ispyconnect.com) or its mobile apps, since Home Assistant's remote access only carries the web page, not the video stream.

## Moving from a standalone Docker install

1. Stop your existing Agent DVR container.
2. Install this app and start it once, then stop it.
3. Copy the contents of your old config volume (mapped to `/AgentDVR/Media/XML`) into the app's config folder, replacing what's there.
4. Copy old recordings into `/media/agentdvr`, keeping the `video` and `audio` folders.
5. Start the app.

## Support

- Logs: the app's **Log** tab, or `http://<your-home-assistant-ip>:8090/logs.html`
- User guide: https://www.ispyconnect.com/docs/agent/about
- Community: https://www.reddit.com/r/ispyconnect/
- Issues with this app: https://github.com/ispysoftware/home-assistant-apps/issues
