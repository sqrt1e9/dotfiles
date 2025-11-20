#!/usr/bin/env bash
# Bluetooth manager with rofi (HID-aware + actions menu + robust status)

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

# ========= Colors (for markup) =========
GREEN='<span color="green">'
YELLOW='<span color="yellow">'
GREY='<span color="grey">'
RED='<span color="red">'
END='</span>'

# ========= rofi config =========
ROFI_COMMON='rofi -dmenu -markup-rows -i'
ROFI_DEVICES="$ROFI_COMMON -p Bluetooth"
ROFI_GENERIC="$ROFI_COMMON"

# ========= Logging / notify =========
LOGFILE="$HOME/.local/share/bluetooth-rofi.log"
mkdir -p "$(dirname "$LOGFILE")"

log()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"; }
notify() { notify-send "Bluetooth" "$1"; }

# ========= Agent setup =========
bluetoothctl agent on >/dev/null 2>&1
bluetoothctl default-agent >/dev/null 2>&1

# ========= State checks =========
power_on()        { bluetoothctl show | grep -q "Powered: yes"; }
discovering()     { bluetoothctl show | grep -q "Discovering: yes"; }
pairable_on()     { bluetoothctl show | grep -q "Pairable: yes"; }
discoverable_on() { bluetoothctl show | grep -q "Discoverable: yes"; }
device_connected(){ bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"; }
device_paired()   { bluetoothctl info "$1" 2>/dev/null | grep -q "Paired: yes"; }
device_trusted()  { bluetoothctl info "$1" 2>/dev/null | grep -q "Trusted: yes"; }
device_is_hid()   { bluetoothctl info "$1" 2>/dev/null | grep -q "Human Interface Device"; }

# ========= Toggles =========
toggle_power() {
    if power_on; then
        log "Power off"; notify "Powering Off..."
        bluetoothctl power off
        notify "Power Off"
    else
        # Unblock rfkill if needed
        rfkill list bluetooth 2>/dev/null | grep -q 'Blocked: yes' && rfkill unblock bluetooth && sleep 2
        log "Power on"; notify "Powering On..."
        bluetoothctl power on
        notify "Power On"
    fi
}

toggle_scan() {
    if discovering; then
        log "Scan off"; notify "Stopping scan..."
        bluetoothctl scan off
        notify "Scan Off"
    else
        log "Scan on"; notify "Scanning..."
        SCAN_TIME=8
        bluetoothctl --timeout "$SCAN_TIME" scan on >>"$LOGFILE" 2>&1 &
    fi
}

toggle_pairable() {
    if pairable_on; then
        log "Pairable off"; notify "Pairable Off"
        bluetoothctl pairable off
    else
        log "Pairable on"; notify "Pairable On"
        bluetoothctl pairable on
    fi
}

toggle_discoverable() {
    if discoverable_on; then
        log "Discoverable off"; notify "Discoverable Off"
        bluetoothctl discoverable off
    else
        log "Discoverable on"; notify "Discoverable On"
        bluetoothctl discoverable on
    fi
}

toggle_connection() {
    mac="$1"

    # Special handling for HID devices (keyboards/mice often auto-sleep)
    if device_is_hid "$mac"; then
        if device_connected "$mac"; then
            notify "HID device disconnects when idle"
        else
            notify "Move/click device to reconnect"
            bluetoothctl connect "$mac" >>"$LOGFILE" 2>&1
        fi
        return
    fi

    if device_connected "$mac"; then
        log "Disconnecting $mac"; notify "Disconnecting..."
        bluetoothctl disconnect "$mac" >>"$LOGFILE" 2>&1
        sleep 2
        if device_connected "$mac"; then
            notify "Disconnect failed"
        else
            notify "Disconnected"
        fi
    else
        log "Connecting $mac"; notify "Connecting..."
        bluetoothctl connect "$mac" >>"$LOGFILE" 2>&1
        for _ in 1 2 3; do
            sleep 2
            if device_connected "$mac"; then
                notify "Connected"
                return
            fi
        done
        notify "Connection failed"
    fi
}

toggle_paired_dev() {
    mac="$1"
    if device_paired "$mac"; then
        log "Removing $mac"; notify "Removing..."
        bluetoothctl remove "$mac" >>"$LOGFILE" 2>&1
        notify "Removed"
    else
        log "Pairing $mac"; notify "Pairing..."
        bluetoothctl pair "$mac" >>"$LOGFILE" 2>&1
        sleep 3
        if device_paired "$mac"; then
            bluetoothctl trust "$mac" >/dev/null 2>&1
            notify "Paired + Trusted"
        else
            notify "Pair failed"
        fi
    fi
}

toggle_trust_dev() {
    mac="$1"
    if device_trusted "$mac"; then
        log "Untrust $mac"; notify "Untrusting..."
        bluetoothctl untrust "$mac" >>"$LOGFILE" 2>&1
        notify "Untrusted"
    else
        log "Trust $mac"; notify "Trusting..."
        bluetoothctl trust "$mac" >>"$LOGFILE" 2>&1
        notify "Trusted"
    fi
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

    items="$pwr\n$scn\n$prb\n$dsc\n$forget\n$back"
    choice="$(echo -e "$items" | eval "$ROFI_GENERIC")" || return

    case "$choice" in
        *"Power"*)        toggle_power ;;
        *"Scan"*)         toggle_scan ;;
        *"Pairable"*)     toggle_pairable ;;
        *"Discoverable"*) toggle_discoverable ;;
        *"Forget All"*)
            if echo -e "No\nYes" | eval "$ROFI_GENERIC -p 'Forget all devices?'" | grep -q Yes; then
                bluetoothctl devices | awk '!seen[$2]++ {print $2}' | while read -r mac; do
                    bluetoothctl remove "$mac"
                done
                notify "All devices removed"
            fi ;;
        *"Back"*) run_scan_and_show; return ;;
    esac
    actions_menu
}

device_menu() {
    local device="$1"
    local name mac choice connected paired trusted items

    name="$(echo "$device" | cut -d ' ' -f 3-)"
    mac="$(echo  "$device" | cut -d ' ' -f 2)"

    if device_connected "$mac"; then
        connected="$GREEN$ICON_CONN$END Connected"
    elif device_is_hid "$mac" && device_paired "$mac"; then
        connected="$YELLOW$ICON_SLEEP$END Sleeping"
    else
        connected="$GREY$ICON_CONN$END Connected"
    fi

    if device_paired "$mac"; then
        paired="$GREEN$ICON_PAIR$END Paired"
    else
        paired="$GREY$ICON_PAIR$END Paired"
    fi

    if device_trusted "$mac"; then
        trusted="$GREEN$ICON_TRUST$END Trusted"
    else
        trusted="$GREY$ICON_TRUST$END Trusted"
    fi

    items="$connected\n$paired\n$trusted"
    choice="$(echo -e "$items" | eval "$ROFI_GENERIC -p '$name'")" || { run_scan_and_show; return; }

    case "$choice" in
        *"Connected"*) toggle_connection "$mac" ;;
        *"Paired"*)    toggle_paired_dev "$mac" ;;
        *"Trusted"*)   toggle_trust_dev "$mac" ;;
    esac
    run_scan_and_show
}

show_devices() {
    local rows choice mac alias

    rows=$(bluetoothctl devices | awk '!seen[$2]++' | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        alias=$(echo "$line" | cut -d ' ' -f 3-)
        [ -z "$alias" ] && alias="$mac"

        if device_connected "$mac"; then
            printf "%s %s [%s]\n" "$GREEN$ICON_BT$END" "$alias" "$mac"
        elif device_is_hid "$mac" && device_paired "$mac"; then
            printf "%s %s [%s]\n" "$YELLOW$ICON_BT$END" "$alias" "$mac"
        else
            printf "%s %s [%s]\n" "$GREY$ICON_BT$END" "$alias" "$mac"
        fi
    done)

    [ -z "$rows" ] && rows="(no devices)"
    choice="$(echo "$rows" | eval "$ROFI_DEVICES")" || return

    mac=$(echo "$choice" | sed -n 's/.*\[\(.*\)\].*/\1/p')
    [ -n "$mac" ] && device_menu "$(bluetoothctl devices | awk '!seen[$2]++' | grep "$mac" | head -n1)"
}

# ========= Scan wrapper =========
run_scan_and_show() {
    notify "Scanning for devices..."
    SCAN_TIME=8
    bluetoothctl --timeout "$SCAN_TIME" scan on >>"$LOGFILE" 2>&1 &
    sleep 2
    show_devices
}

# ========= Status (simplified + robust) =========
print_status() {
    # If Bluetooth is off
    if ! power_on; then
        # Plain icon (no color)
        echo ""
        return
    fi

    # Any connected device at all?
    if bluetoothctl devices Connected 2>/dev/null | grep -q .; then
        # Green BT icon
        echo "${GREEN}${ICON_BT}${END}"
    else
        # Grey BT icon
        echo "${GREY}${ICON_BT}${END}"
    fi
}

# ========= Entry =========
case "${1:-}" in
    --status)  print_status ;;
    --actions) actions_menu ;;
    *)         run_scan_and_show ;;
esac

