#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-}"
CONFIG="$HOME/.config/swaync/config.json"

case "$PROFILE" in
  performance|balanced|power-saver) ;;
  *)
    exit 1
    ;;
esac

powerprofilesctl set "$PROFILE"

python3 - "$CONFIG" "$PROFILE" <<'PY'
import json, sys

config_path = sys.argv[1]
selected = sys.argv[2]

with open(config_path, "r", encoding="utf-8") as f:
    data = json.load(f)

actions = data["widget-config"]["buttons-grid#powermodes"]["actions"]

mapping = {
    0: "performance",
    1: "balanced",
    2: "power-saver",
}

for i, action in enumerate(actions):
    action["active"] = (mapping[i] == selected)

with open(config_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
PY

swaync-client --reload-config
swaync-client -cp
sleep 0.5
swaync-client -t
