#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="bluetooth"
rp_module_desc="Configure Bluetooth Devices"
rp_module_section="config"

function _update_hook_bluetooth() {
    # fix config location
    [[ -f "$configdir/bluetooth.cfg" ]] && mv "$configdir/bluetooth.cfg" "$configdir/all/bluetooth.cfg"
}

function _get_connect_mode() {
    # get bluetooth config
    iniConfig "=" '"' "$configdir/all/bluetooth.cfg"
    iniGet "connect_mode"
    if [[ -n "$ini_value" ]]; then
        echo "$ini_value"
    else
        echo "default"
    fi
}

function depends_bluetooth() {
    local depends=(bluetooth python-dbus python-gobject)
    if [[ "$__os_id" == "Raspbian" ]]; then
        depends+=(pi-bluetooth raspberrypi-sys-mods)
    fi
    getDepends "${depends[@]}"
}

function get_script_bluetooth() {
    name="$1"
    name="/retropie/scriptmodules/supplementary/bluetooth/$name"
    echo "$name"
}

function _slowecho_bluetooth() {
    local line

    IFS=$'\n'
    for line in $(echo -e "${1}"); do
        echo -e "$line"
        sleep 1
    done
    unset IFS
}

function bluez_cmd_bluetooth() {
    # create a named pipe & fd for input for bluetoothctl
    local fifo="$(mktemp -u)"
    mkfifo "$fifo"
    exec 3<>"$fifo"
    local line
    while true; do
        _slowecho_bluetooth "$1" >&3
        # collect output for specified amount of time, then echo it
        while read -r line; do
            printf '%s\n' "$line"
            # (slow) reply to any optional challenges
            if [[ -n "$3" && "$line" =~ $3 ]]; then
                _slowecho_bluetooth "$4" >&3
            fi
        done
        _slowecho_bluetooth "quit\n" >&3
        break
    # read from bluetoothctl buffered line by line
    done < <(timeout "$2" stdbuf -oL bluetoothctl --agent=NoInputNoOutput <&3)
    exec 3>&-
}

function list_available_bluetooth() {
    local mac_address
    local device_name
    local info_text="\n\nSearching ..."

    # sixaxis: add USB pairing information
    [[ -n "$(lsmod | grep hid_sony)" ]] && info_text="Searching ...\n\nDualShock registration: while this text is visible, unplug the controller, press the PS/SHARE button, and then replug the controller."

    dialog --backtitle "$__backtitle" --infobox "$info_text" 7 60 >/dev/tty
    if hasPackage bluez 5; then
        # sixaxis: reply to authorization challenge on USB cable connect
        while read mac_address; read device_name; do
            echo "$mac_address"
            echo "$device_name"
        done < <(bluez_cmd_bluetooth "default-agent\nscan on" "15" "Authorize service$" "yes" >/dev/null; bluez_cmd_bluetooth "devices" "3" | grep "^Device " | cut -d" " -f2,3- | sed 's/ /\n/')
    else
        while read; read mac_address; read device_name; do
            echo "$mac_address"
            echo "$device_name"
        done < <(hcitool scan --flush | tail -n +2 | sed 's/\t/\n/g')
    fi
}

function list_registered_bluetooth() {
    local line
    local mac_address
    local device_name
    while read line; do
        mac_address="$(echo "$line" | sed 's/ /,/g' | cut -d, -f1)"
        device_name="$(echo "$line" | sed 's/'"$mac_address"' //g')"
        echo -e "$mac_address\n$device_name"
    done < <($(get_script_bluetooth bluez-test-device) list)
}

function display_active_and_registered_bluetooth() {
    local registered
    local active

    registered="$($(get_script_bluetooth bluez-test-device) list 2>&1)"
    [[ -z "$registered" ]] && registered="There are no registered devices"

    if [[ "$(hcitool con)" != "Connections:" ]]; then
        active="$(hcitool con 2>&1 | sed 1d)"
    else
        active="There are no active connections"
    fi

    printMsgs "dialog" "Registered Devices:\n\n$registered\n\n\nActive Connections:\n\n$active"
}

function remove_device_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()
    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_registered_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "There are no devices to remove."
    else
        local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the bluetooth device you would like to remove" 22 76 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && return

        remove_bluetooth_device=$($(get_script_bluetooth bluez-test-device) remove $choice)
        if [[ -z "$remove_bluetooth_device" ]] ; then
            printMsgs "dialog" "Device removed"
        else
            printMsgs "dialog" "An error occurred removing the bluetooth device. Please ensure you typed the mac address correctly"
        fi
    fi
}

function register_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()

    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_available_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "No devices were found. Ensure device is on and try again"
        return
    fi

    local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the bluetooth device you would like to connect to" 22 76 16)
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    mac_address="$choice"
    device_name="${mac_addresses[$choice]}"
    
     if [[ "$device_name" =~ "PLAYSTATION(R)3 Controller" ]]; then
        $(get_script_bluetooth bluez-test-device) disconnect "$mac_address" 2>&1
        $(get_script_bluetooth bluez-test-device) trusted "$mac_address" yes 2>&1
        local trusted=$($(get_script_bluetooth bluez-test-device) trusted "$mac_address" 2>&1)
        if [[ "$trusted" -eq 1 ]]; then
            printMsgs "dialog" "Successfully authenticated $device_name ($mac_address).\n\nYou can now remove the USB cable."
        else
            printMsgs "dialog" "Unable to authenticate $device_name ($mac_address).\n\nPlease try to register the device again, making sure to follow the on-screen steps exactly."
        fi
        return
    fi

       messa=$(echo -e "pair $mac_address" | bluetoothctl)
       printMsgs "dialog" "Successfully paired with $mac_address $messa"
       messa=$(bluetoothctl -- trust $mac_address)
       printMsgs "dialog" "Successfully registered and connected to $mac_address $messa"
       messa=$(bluetoothctl -- connect $mac_address)
        printMsgs "dialog" "Successfully registered and connected to $mac_address $messa"
        return 0

    printMsgs "dialog" "An error occurred connecting to the bluetooth device ($error)"
    return 1
}

function udev_bluetooth() {
    declare -A mac_addresses=()
    local mac_address
    local device_name
    local options=()
    while read mac_address; read device_name; do
        mac_addresses+=(["$mac_address"]="$device_name")
        options+=("$mac_address" "$device_name")
    done < <(list_registered_bluetooth)

    if [[ ${#mac_addresses[@]} -eq 0 ]] ; then
        printMsgs "dialog" "There are no registered bluetooth devices."
    else
        local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the bluetooth device you would like to create a udev rule for" 22 76 16)
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && return
        device_name="${mac_addresses[$choice]}"
        local config="/etc/udev/rules.d/99-bluetooth.rules"
        if ! grep -q "$device_name" "$config"; then
            local line="SUBSYSTEM==\"input\", ATTRS{name}==\"$device_name\", MODE=\"0666\", ENV{ID_INPUT_JOYSTICK}=\"1\""
            addLineToFile "$line" "$config"
            printMsgs "dialog" "Added $line to $config\n\nPlease reboot for the configuration to take effect."
        else
            printMsgs "dialog" "An entry already exists for $device_name in $config"
        fi
    fi
}

function connect_bluetooth() {
    local mac_address
    local device_name
    while read mac_address; read device_name; do
        bluetoothctl connect "$mac_address" 2>/dev/null
    done < <(list_registered_bluetooth)
}

function boot_bluetooth() {
    connect_mode="$(_get_connect_mode)"
    case "$connect_mode" in
        boot)
            connect_bluetooth
            ;;
        background)
            local script=""
            local macs=()
            local mac_address
            local device_name
            while read mac_address; read device_name; do
                macs+=($mac_address)
            done < <(list_registered_bluetooth)
            local script="while true; do for mac in ${macs[@]}; do hcitool con | grep -q \"\$mac\" || { echo \"connect \$mac\nquit\"; sleep 1; } | bluetoothctl >/dev/null 2>&1; sleep 10; done; done"
            nohup nice -n19 /bin/sh -c "$script" >/dev/null &
            ;;
    esac
}

function connect_mode_bluetooth() {
    local connect_mode="$(_get_connect_mode)"

    local cmd=(dialog --backtitle "$__backtitle" --default-item "$connect_mode" --menu "Choose a connect mode" 22 76 16)

    local options=(
        default "Bluetooth stack default behaviour (recommended)"
        boot "Connect to devices once at boot"
        background "Force connecting to devices in the background"
    )

    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    local config="/etc/systemd/system/connect-bluetooth.service"
    case "$choice" in
        boot|background)
            local type="simple"
            [[ "$choice" == "background" ]] && type="forking"
            cat > "$config" << _EOF_
[Unit]
Description=Connect Bluetooth

[Service]
Type=$type
ExecStart=/bin/bash "$scriptdir/retropie_packages.sh" bluetooth boot

[Install]
WantedBy=multi-user.target
_EOF_
            systemctl enable "$config"
            ;;
        default)
            if systemctl is-enabled connect-bluetooth | grep -q "enabled"; then
               systemctl disable "$config"
            fi
            rm -f "$config"
            ;;
    esac
    iniConfig "=" '"' "$configdir/all/bluetooth.cfg"
    iniSet "connect_mode" "$choice"
    chown $user:$user "$configdir/all/bluetooth.cfg"
}

function gui_bluetooth() {
    addAutoConf "8bitdo_hack" 0

    while true; do
        local connect_mode="$(_get_connect_mode)"

        local cmd=(dialog --backtitle "$__backtitle" --menu "Configure Bluetooth Devices" 22 76 16)
        local options=(
            R "Register and Connect to Bluetooth Device"
            X "Remove Bluetooth Device"
            D "Display Registered & Connected Bluetooth Devices"
            U "Set up udev rule for Joypad (required for joypads from 8Bitdo etc)"
            C "Connect now to all registered devices"
            M "Configure bluetooth connect mode (currently: $connect_mode)"
        )

        local atebitdo
        if getAutoConf 8bitdo_hack; then
            atebitdo=1
            options+=(8 "8Bitdo mapping hack (ON - old firmware)")
        else
            atebitdo=0
            options+=(8 "8Bitdo mapping hack (OFF - new firmware)")
        fi

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            # temporarily restore Bluetooth stack (if needed)
            service sixad status &>/dev/null && sixad -r
            case "$choice" in
                R)
                    register_bluetooth
                    ;;
                X)
                    remove_device_bluetooth
                    ;;
                D)
                    display_active_and_registered_bluetooth
                    ;;
                U)
                    udev_bluetooth
                    ;;
                C)
                    connect_bluetooth
                    ;;
                M)
                    connect_mode_bluetooth
                    ;;
                8)
                    atebitdo="$((atebitdo ^ 1))"
                    setAutoConf "8bitdo_hack" "$atebitdo"
                    ;;
            esac
        else
            # restart sixad (if running)
            service sixad status &>/dev/null && service sixad restart && printMsgs "dialog" "NOTICE: The ps3controller driver was temporarily interrupted in order to allow compatibility with standard Bluetooth peripherals. Please re-pair your Dual Shock controller to continue (or disregard this message if currently using another controller)."
            break
        fi
    done
}
