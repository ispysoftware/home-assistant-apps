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

# WebServerRoot/Media is a VOLUME in the base image, so it is a mount point and
# can't itself be replaced by a symlink. Its video and audio subfolders can.
link_dir "$AGENT/Media/WebServerRoot/Media/video" "$REC/video"
link_dir "$AGENT/Media/WebServerRoot/Media/audio" "$REC/audio"

echo "Agent DVR: config in /config, recordings in $REC, models in $DATA/models"

exec "$AGENT/Agent.sh"
