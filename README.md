# Agent DVR for Home Assistant

Run [Agent DVR](https://www.ispyconnect.com/) on your Home Assistant machine: free local video surveillance with AI object detection, recording and alerts for IP, ONVIF and USB cameras.

[![Add this repository to your Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fispysoftware%2Fhome-assistant-apps)

Or add it manually: in Home Assistant open the app store (**Settings > Apps**, called **Add-ons** in older versions), open the menu in the top right, choose **Repositories** and add:

```
https://github.com/ispysoftware/home-assistant-apps
```

Then install **Agent DVR** from the store.

Requires Home Assistant OS or a Supervised install, on amd64 or aarch64 (64-bit Raspberry Pi 4/5).

## Apps

| App | Description |
|-----|-------------|
| [Agent DVR](agentdvr) | Video surveillance with AI detection, recording and alerts |

Once it's running, add the official [Agent DVR integration](https://www.home-assistant.io/integrations/agent_dvr/) to control your cameras from Home Assistant.
