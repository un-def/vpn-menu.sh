#!/bin/sh

VERSION='0.1.0.dev0'

mode=''
multiple=false
active_marker='[*] '

error() {
    echo "${@}" >&2
    exit 1
}

usage() {
    error "Usage: vpn-menu.sh --rofi|--dmenu [--multiple] \
[--active-marker MARKER] [DMENU_PATH [DMENU_ARGS...]]

    --rofi
        Run as Rofi modi
    --dmenu
        Run with dmenu or similar tool
    --multiple
        Allow multiple active VPN connections
        By default, the script will turn off all VPN connections
        before activating a new one. This option allows to
        turn on/off each connection independently.
    --active-marker MARKER
        Customize the active marker
        The active marker is an arbitrary string used as a prefix
        for active connection name(s) in the connection list.
        Default is '[*] '.
    "
}

set_mode() {
    _mode=${1#--}
    if [ -n "${mode}" ]; then
        error "Conflicting options: --${_mode} and --${mode}"
    fi
    mode=$_mode
}

maybe_remove_active_marker() {
    length=$(printf '%s' "${active_marker}" | wc -c)
    if [ "$(echo "${1}" | cut -c "-${length}")" = "${active_marker}" ]; then
        echo "${1}" | cut -c $((length + 1))-
        return 0
    fi
    echo "${1}"
    return 1
}

connection_list() {
    nmcli --get-values name,type,active,state connection show \
    | awk -F ':' '
        $2 != "vpn" { next }
        $3 == "yes" { $1 = "\a" $1 }
        { print $1 }
    ' \
    | LC_COLLATE=C sort \
    | sed -n "s/^\a/${active_marker}/;p"
}

disconnect_all() {
    active_connections=$(
        nmcli --get-values name,type connection show --active \
        | awk -F ':' '
            $2 != "vpn" { next }
            { print $1 }
        '
    )
    if [ -z "${active_connections}" ]; then
        return
    fi
    echo "${active_connections}" | xargs -d '\n' nmcli connection down \
        > /dev/null
}

toggle_connection() {
    if connection=$(maybe_remove_active_marker "${1}"); then
        action='down'
    else
        action='up'
    fi
    if [ ${multiple} != true ]; then
        disconnect_all
        if [ ${action} = 'down' ]; then
            return
        fi
    fi
    nmcli connection "${action}" "${connection}" > /dev/null &
}

run_rofi_mode() {
    if [ ${#} -eq 0 ]; then
        connection_list
    else
        toggle_connection "${1}"
    fi
}

run_dmenu_mode() {
    if [ ${#} -gt 0 ]; then
        selected=$(connection_list | "${@}")
    else
        selected=$(connection_list | dmenu -i -p VPN)
    fi
    if [ -z "${selected}" ]; then
        exit
    fi
    toggle_connection "${selected}"
}

########## main ##########

while test ${#} -gt 0; do
    case "${1}" in
        -h|--help)
            usage
            ;;
        --version)
            echo "${VERSION}"
            exit
            ;;
        --rofi|--dmenu)
            set_mode "${1}"
            shift
            ;;
        --multiple)
            multiple=true
            shift
            ;;
        --active-marker)
            shift
            if [ ${#} -eq 0 ]; then
                error '--active-marker option requires a value'
            fi
            active_marker=${1}
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            error "Unknown option: ${1}"
            ;;
        *)
            break
    esac
done

if [ -z "${mode}" ]; then
    usage
fi

"run_${mode}_mode" "${@}"
