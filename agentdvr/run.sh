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

# Default commands and sounds. Agent only copies its defaults into a folder it
# has to create itself, and the links above already exist, while the image's
# Agent.sh moves Content/* up to /AgentDVR and deletes Content. So fill an empty
# folder here, the way Agent would: from Content in a fresh container, from the
# moved copy after a restart. Only when empty, so deleted defaults stay deleted.
seed_dir() {
    local name="$1" dst="$2" src
    [[ -n "$(ls -A "$dst" 2>/dev/null)" ]] && return 0
    for src in "$AGENT/Content/$name" "$AGENT/$name"; do
        if [[ -d "$src" && -n "$(ls -A "$src" 2>/dev/null)" ]]; then
            cp -an "$src/." "$dst/" 2>/dev/null || true
            return 0
        fi
    done
}

seed_dir Commands "$DATA/commands"
seed_dir sounds   "$DATA/sounds"

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

# Supervisor discovery (see "discovery" in config.yaml): Home Assistant then
# offers the Agent DVR integration under Settings > Devices & services. Sent
# once the web UI answers, because the integration connects straight away to
# read the server's ID. 127.0.0.1 works because Home Assistant and this app
# both use host networking. The Supervisor ignores a repeat of the same
# message, so sending it on every start is fine.
announce_discovery() {
    local i
    if [[ -z "${SUPERVISOR_TOKEN:-}" ]]; then
        echo "Agent DVR: no Supervisor token, skipping Home Assistant discovery"
        return 0
    fi
    # First start on a Raspberry Pi can take minutes (AI models, migrations).
    for (( i = 0; i < 120; i++ )); do
        if (exec 3<>/dev/tcp/127.0.0.1/8090) 2>/dev/null; then
            if curl -fsS --max-time 30 -X POST \
                -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
                -H "Content-Type: application/json" \
                -d '{"service":"agent_dvr","config":{"host":"127.0.0.1","port":8090}}' \
                http://supervisor/discovery >/dev/null; then
                echo "Agent DVR: sent discovery information to Home Assistant"
            else
                echo "Agent DVR: discovery message to Home Assistant failed"
            fi
            return 0
        fi
        sleep 5
    done
    echo "Agent DVR: web UI didn't start within 10 minutes, Home Assistant discovery not sent"
}

# In the background: exec below replaces this shell, and the app's init
# process reaps the subshell when it ends.
announce_discovery &

exec "$AGENT/Agent.sh"
