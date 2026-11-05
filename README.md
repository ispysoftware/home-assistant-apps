# Agent DVR for Home Assistant

Run [Agent DVR](https://www.ispyconnect.com/) on your Home Assistant machine: local video surveillance with AI object detection, recording and alerts for IP, ONVIF and USB cameras. Free for personal local use; some features need a license.

[![Open Agent DVR in your Home Assistant](https://my.home-assistant.io/badges/supervisor_app.svg)](https://my.home-assistant.io/redirect/supervisor_app/?app=a910219e_agentdvr&repository_url=https%3A%2F%2Fgithub.com%2Fispysoftware%2Fhome-assistant-apps)

This adds the repository if it's missing and opens the Agent DVR app, ready to install.

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
