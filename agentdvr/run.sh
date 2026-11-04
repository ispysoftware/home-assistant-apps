#!/usr/bin/env bash
# Home Assistant startup wrapper for the official Agent DVR image.
#
# The Supervisor recreates the container on every update, so anything left in
# the image layer (or in the image's anonymous Docker volumes) is lost. Config
# is already mounted at /AgentDVR/Media/XML by config.yaml; this script moves
# everything else that must survive an update onto persistent storage:
#   /data/...           models, commands, overlays, floorplans, sounds
#   /media/agentdvr/... recordings (video, audio)
# then hands over to the image's own entrypoint.
set -euo pipefail

AGENT=/AgentDVR
DATA=/data
REC=/media/agentdvr

# Replace $1 with a symlink to $2. On the first start after an install or
# update, the image's copy is merged into $2 first without overwriting
# anything already there, so user files win and new defaults still arrive.
link_dir() {
    local src="$1" dst="$2"
    mkdir -p "$dst"
    if [[ -d "$src" && ! -L "$src" ]]; then
        cp -an "$src/." "$dst/" 2>/dev/null || true
        rm -rf "$src"
    fi
    mkdir -p "$(dirname "$src")"
    ln -sfn "$dst" "$src"
}

link_dir "$AGENT/Media/Models"     "$DATA/models"
link_dir "$AGENT/Media/Commands"   "$DATA/commands"
link_dir "$AGENT/Media/Overlays"   "$DATA/overlays"
link_dir "$AGENT/Media/Floorplans" "$DATA/floorplans"
link_dir "$AGENT/Media/sounds"     "$DATA/sounds"

# Recordings. The Supervisor doesn't create the base image's anonymous VOLUME
# here, so the folder is normally plain and the whole thing is linked to
# /media/agentdvr. Agent versions whose storage check follows symlinks then
# show no storage warning. If some setup does mount it, a mount point
# can't be replaced, so fall back to linking its video and audio subfolders.
MEDIA="$AGENT/Media/WebServerRoot/Media"
if awk -v p="$MEDIA" '$2 == p { found = 1 } END { exit !found }' /proc/mounts; then
    link_dir "$MEDIA/video" "$REC/video"
    link_dir "$MEDIA/audio" "$REC/audio"
else
    link_dir "$MEDIA" "$REC"
fi

# Home Assistant's ingress proxy (Supervisor 172.30.32.2, reached from HA core
# 172.30.32.1) adds X-Forwarded-For. Trusting it lets Agent see the real
# browser address: local browsers count as local, remote ones (HA remote
# access) still need Agent's remote-access license. Read by Agent versions
# that support AGENT_TRUSTED_PROXIES; older ones ignore it.
export AGENT_TRUSTED_PROXIES="172.30.32.1 172.30.32.2"

# The web UI port is fixed: the sidebar panel (ingress_port), the watchdog and
# the Agent DVR integration all use 8090. If 8090 is busy at startup Agent falls
# back to a random port and saves it, which would leave the panel stuck on
# "starting" for good; the environment wins over that saved port.
export AGENTDVR_WEBUI_PORT=8090

# With host networking another app (or a second copy of this one) can already
# hold 8090. Agent would then fall back to a random port while the panel, the
# watchdog and the integration kept talking to whatever owns 8090 - so stop
# with a plain message instead. (bash's /dev/tcp: connects only if something
# is listening.)
if (exec 3<>/dev/tcp/127.0.0.1/8090) 2>/dev/null; then
    echo "ERROR: Port 8090 is already in use by another app or service on this machine."
    echo "Agent DVR needs it for its web interface and the Home Assistant sidebar panel."
    echo "Stop the other one (or the other copy of Agent DVR), then start Agent DVR again."
    exit 1
fi

echo "Agent DVR: config in the app config folder, recordings in $REC, models in $DATA/models"

exec "$AGENT/Agent.sh"
