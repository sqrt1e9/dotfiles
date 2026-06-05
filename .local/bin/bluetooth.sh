#!/usr/bin/env bash
# Bluetooth manager with rofi
# Fixes: safer bluetoothctl calls, stable scan flow, no eval, no undefined functions.

set -u

# ========= Icons =========
ICON_BT=""
ICON_CONN=""
ICON_PAIR=""
ICON_TRUST=""
ICON_SCAN=""
ICON_PAIRABLE=""
ICON_DISCOVERABLE=""
ICON_FORGET=""
ICON_SLEEP=""

# ========= Colors =========
GREEN='<span color="green">'
YELLOW='<span color="yellow">'
GREY='<span color="grey">'
RED='<span color="red">'
END='</span>'

# ========= Config =========
LOGFILE="$HOME/.local/share/bluetooth-rofi.log"
SCAN_TIME="${SCAN_TIME:-6}"
CONNECT_RETRIES="${CONNECT_RETRIES:-5}"
mkdir -p "$(dirname "$LOGFILE")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }
notify() { command -v notify-send >/dev/null 2>&1 && notify-send "Bluetooth" "$1"; }

rofi_menu() {
    local prompt="$1"
    rofi -dmenu -markup-rows -i -p "$prompt"
}

bt() {
    bluetoothctl "$@" >> "$LOGFILE" 2>&1
}

bt_out() {
    bluetoothctl "$@" 2>/dev/null
}

# ========= Agent setup =========
setup_agent() {
    bt agent on || true
    bt default-agent || true
}

# ========= State checks =========
power_on()        { bt_out show | grep -q "Powered: yes"; }
discovering()     { bt_out show | grep -q "Discovering: yes"; }
pairable_on()     { bt_out show | grep -q "Pairable: yes"; }
discoverable_on() { bt_out show | grep -q "Discoverable: yes"; }

device_info()      { bt_out info "$1"; }
device_connected(){ device_info "$1" | grep -q "Connected: yes"; }
device_paired()   { device_info "$1" | grep -q "Paired: yes"; }
device_trusted()  { device_info "$1" | grep -q "Trusted: yes"; }
device_is_hid()   { device_info "$1" | grep -Eiq "Human Interface Device|Icon: input-"; }

ensure_power_on() {
    if power_on; then
        return 0
    fi

    rfkill list bluetooth 2>/dev/null | grep -q 'Blocked: yes' && rfkill unblock bluetooth && sleep 1
    notify "Powering on..."
    bt power on
    sleep 1

    if ! power_on; then
        notify "Bluetooth power on failed"
        return 1
    fi
}

wait_for_connected() {
    local mac="$1"
    local i

    for ((i = 1; i <= CONNECT_RETRIES; i++)); do
        sleep 1
        device_connected "$mac" && return 0
    done
    return 1
}

# ========= Toggles =========
toggle_power() {
    if power_on; then
        log "Power off"
        notify "Powering off..."
        bt power off
        notify "Power off"
    else
        log "Power on"
        ensure_power_on && notify "Power on"
    fi
}

toggle_scan() {
    ensure_power_on || return

    if discovering; then
        log "Scan off"
        notify "Stopping scan..."
        bt scan off
        notify "Scan off"
    else
        log "Scan on"
        notify "Scanning for ${SCAN_TIME}s..."
        bt scan on &
        sleep "$SCAN_TIME"
        bt scan off
        notify "Scan complete"
    fi
}

toggle_pairable() {
    ensure_power_on || return

    if pairable_on; then
        log "Pairable off"
        bt pairable off
        notify "Pairable off"
    else
        log "Pairable on"
        bt pairable on
        notify "Pairable on"
    fi
}

toggle_discoverable() {
    ensure_power_on || return

    if discoverable_on; then
        log "Discoverable off"
        bt discoverable off
        notify "Discoverable off"
    else
        log "Discoverable on"
        bt discoverable on
        notify "Discoverable on"
    fi
}

toggle_trust_dev() {
    local mac="$1"

    if device_trusted "$mac"; then
        log "Untrust $mac"
        bt untrust "$mac"
        notify "Untrusted"
    else
        log "Trust $mac"
        bt trust "$mac"
        notify "Trusted"
    fi
}

remove_device() {
    local mac="$1"
    log "Remove $mac"
    bt remove "$mac"
    notify "Removed"
}

connect_device() {
    local mac="$1"

    ensure_power_on || return 1
    log "Connect $mac"
    bt connect "$mac"

    if wait_for_connected "$mac"; then
        notify "Connected"
        return 0
    fi

    notify "Connection failed"
    return 1
}

disconnect_device() {
    local mac="$1"

    log "Disconnect $mac"
    bt disconnect "$mac"
    sleep 1

    if device_connected "$mac"; then
        notify "Disconnect failed"
        return 1
    fi

    notify "Disconnected"
}

pair_trust_connect_device() {
    local mac="$1"

    ensure_power_on || return 1
    setup_agent

    log "Pair $mac"
    notify "Pairing..."
    bt pair "$mac"
    sleep 2

    if ! device_paired "$mac"; then
        notify "Pair failed"
        return 1
    fi

    bt trust "$mac"
    notify "Paired + trusted. Connecting..."
    connect_device "$mac"
}

# ========= Smart single-step manager =========
smart_manage_device() {
    local mac="$1"

    ensure_power_on || return

    if ! device_paired "$mac"; then
        pair_trust_connect_device "$mac"
        return
    fi

    if device_connected "$mac"; then
        disconnect_device "$mac"
        return
    fi

    if device_is_hid "$mac"; then
        notify "Wake/move the device, then connecting..."
    else
        notify "Connecting..."
    fi

    connect_device "$mac"
}

# ========= Menus =========
actions_menu() {
    local pwr scn prb dsc forget back items choice

    if power_on;        then pwr="$GREEN$ICON_BT$END Power";          else pwr="$GREY$ICON_BT$END Power"; fi
    if discovering;     then scn="$GREEN$ICON_SCAN$END Scan";         else scn="$GREY$ICON_SCAN$END Scan"; fi
    if pairable_on;     then prb="$GREEN$ICON_PAIRABLE$END Pairable"; else prb="$GREY$ICON_PAIRABLE$END Pairable"; fi
    if discoverable_on; then dsc="$GREEN$ICON_DISCOVERABLE$END Discoverable"; else dsc="$GREY$ICON_DISCOVERABLE$END Discoverable"; fi

    forget="$RED$ICON_FORGET$END Forget All"
    back="$YELLOW$ICON_BT$END Back"

    items="$pwr
$scn
$prb
$dsc
$forget
$back"
    choice="$(printf '%b\n' "$items" | rofi_menu "Bluetooth")" || return

    case "$choice" in
        *"Power"*)        toggle_power ;;
        *"Scan"*)         toggle_scan ;;
        *"Pairable"*)     toggle_pairable ;;
        *"Discoverable"*) toggle_discoverable ;;
        *"Forget All"*)
            if printf 'No\nYes\n' | rofi_menu "Forget all devices?" | grep -q '^Yes$'; then
                bt_out devices | awk '!seen[$2]++ {print $2}' | while read -r mac; do
                    bt remove "$mac"
                done
                notify "All devices removed"
            fi ;;
        *"Back"*) show_devices; return ;;
    esac

    actions_menu
}

device_menu() {
    local mac="$1"
    local name="$2"
    local connected paired trusted forget back items choice

    if device_connected "$mac"; then
        connected="$GREEN$ICON_CONN$END Connected"
    elif device_is_hid "$mac" && device_paired "$mac"; then
        connected="$YELLOW$ICON_SLEEP$END Sleeping / Connect"
    else
        connected="$GREY$ICON_CONN$END Connect"
    fi

    if device_paired "$mac"; then paired="$GREEN$ICON_PAIR$END Paired"; else paired="$GREY$ICON_PAIR$END Pair"; fi
    if device_trusted "$mac"; then trusted="$GREEN$ICON_TRUST$END Trusted"; else trusted="$GREY$ICON_TRUST$END Trust"; fi

    forget="$RED$ICON_FORGET$END Forget"
    back="$YELLOW$ICON_BT$END Back"

    items="$connected
$paired
$trusted
$forget
$back"
    choice="$(printf '%b\n' "$items" | rofi_menu "$name")" || { show_devices; return; }

    case "$choice" in
        *"Connected"*) disconnect_device "$mac" ;;
        *"Connect"*|*"Sleeping"*) connect_device "$mac" ;;
        *"Pair"*) pair_trust_connect_device "$mac" ;;
        *"Paired"*) remove_device "$mac" ;;
        *"Trust"*|*"Trusted"*) toggle_trust_dev "$mac" ;;
        *"Forget"*) remove_device "$mac" ;;
        *"Back"*) show_devices; return ;;
    esac
}

show_devices() {
    local rows choice mac alias

    ensure_power_on || return

    rows="$({
        bt_out devices Paired
        bt_out devices
    } | awk '!seen[$2]++' | while read -r line; do
        mac="$(echo "$line" | awk '{print $2}')"
        alias="$(echo "$line" | cut -d ' ' -f 3-)"
        [ -z "$alias" ] && alias="$mac"

        if device_connected "$mac"; then
            printf '%s %s [%s]\n' "$GREEN$ICON_BT$END" "$alias" "$mac"
        elif device_is_hid "$mac" && device_paired "$mac"; then
            printf '%s %s [%s]\n' "$YELLOW$ICON_SLEEP$END" "$alias" "$mac"
        else
            printf '%s %s [%s]\n' "$GREY$ICON_BT$END" "$alias" "$mac"
        fi
    done)"

    [ -z "$rows" ] && rows="(no devices)"
    choice="$(printf '%b\n' "$rows" | rofi_menu "Bluetooth")" || return

    [ "$choice" = "(no devices)" ] && return

    mac="$(echo "$choice" | sed -n 's/.*\[\([0-9A-Fa-f:]*\)\].*/\1/p')"
    alias="$(echo "$choice" | sed -E 's/<[^>]+>//g; s/^[^ ]+ //; s/ \[[0-9A-Fa-f:]+\]$//')"

    [ -n "$mac" ] && smart_manage_device "$mac"
}

run_scan_and_show() {
    ensure_power_on || return
    setup_agent

    notify "Scanning for ${SCAN_TIME}s..."
    log "Scan before show_devices"
    bt scan on &
    sleep "$SCAN_TIME"
    bt scan off
    show_devices
}

print_status() {
    if ! power_on; then
        echo "$ICON_BT"
        return
    fi

    if bt_out devices Connected | grep -q .; then
        echo "${GREEN}${ICON_BT}${END}"
    else
        echo "${GREY}${ICON_BT}${END}"
    fi
}

case "${1:-}" in
    --status)  print_status ;;
    --actions) actions_menu ;;
    *)         run_scan_and_show ;;
esac
