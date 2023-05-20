#!/bin/sh
# backlightd

cat="/bin/cat"
chown="/usr/sbin/chown"
id="/usr/bin/id"
intel_backlight="/usr/local/bin/intel_backlight"
logger="/usr/bin/logger"
mkdir="/bin/mkdir"
sysrc="/usr/sbin/sysrc"

config_set() {
    sysrc -nq "$1=$2" | awk -F '->' '{print $2}' | awk '{$1=$1};1'
}

config_get() {
    sysrc -n "$1" | awk '{$1=$1};1'
}

config_exists() {
    if config_get "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

backlight_current() {
    value="$($intel_backlight)"
    value="${value%%\%*}"
    value="${value##*:}"
    echo "$value"
}

backlight_fade() {
    target="$1"
    step="$2"
    delay="$3"
    curr="$(backlight_current)"
    if [ "$target" -eq "$curr" ]; then
        return
    elif [ "$target" -lt "$curr" ]; then
        step="$((-step))"
    fi
    for value in $(seq "$curr" "$step" "$target"); do
        sleep "$((delay / 100))"
        $intel_backlight "$value" >/dev/null
    done
    $intel_backlight "$target" >/dev/null
}

parse_event() {
    line="$1"
    line="$(echo "$line" | tr -d '\r\n')"
    if [ "${line:0:1}" = "!" ]; then
        line="${line#?}"
        event="$(echo "$line" | awk '{for(i=1;i<=NF;i++){print $i}}' | awk -F '=' '{print $1"="$2}')"
        echo "$event"
    else
        return 1
    fi
}

next_backlight_level() {
    curr="$1"
    direction="$2"
    levels="$(config_get "backlightd_levels" | tr ' ' '\n' | sort -n | tr '\n' ' ')"
    if [ "$direction" -gt 0 ]; then
        lvls="$(echo "$levels" | awk -v curr="$curr" '$1 > curr')"
        echo "$lvls" | head -n 1
    elif [ "$direction" -lt 0 ]; then
        lvls="$(echo "$levels" | tac | awk -v curr="$curr" '$1 < curr')"
        echo "$lvls" | head -n 1
    else
        echo "$curr"
    fi
}

handle_event() {
    event="$1"
    if [ -z "$event" ] || [ "$(echo "$event" | awk -F '=' '{print $1}')" != "notify" ] || [ "$(echo "$event" | awk -F '=' '{print $2}')" != "0x10" ] || [ "$(echo "$event" | awk -F '=' '{print $3}')" != "subsystem" ]; then
        return
    fi
    curr="$(backlight_current)"
    if [ "$curr" -eq 100 ]; then
        return
    fi
    target="$(next_backlight_level "$curr" 1)"
    backlight_fade "$target" 1 10
}

main_set() {
    target="$1"
    curr="$(backlight_current)"
    echo "set backlight from $curr to $target"
    $intel_backlight "$target" >/dev/null
    exit 0
}

main_fade() {
    target="$1"
    step="${2:-2}"
    delay="${3:-10}"
    curr="$(backlight_current)"
    echo "fade backlight from $curr to $target"
    backlight_fade "$target" "$step" "$delay"
}

main_init() {
    levels="${1:-0 1 4 10 30 50 70 100}"
    config_set "backlightd_levels" "$levels"
}

main_run() {
    while read -r line; do
        event="$(parse_event "$line")"
        if [ -z "$event" ]; then
            break
        fi
        handle_event "$event"
    done </var/run/devd.seqpacket.pipe
}

case "$1" in
    set)
        main_set "$2"
        ;;
    fade)
        main_fade "$2" "$3" "$4"
        ;;
    init)
        main_init "$2"
        ;;
    run)
        main_run
        ;;
    *)
        echo "Usage: $0 {set|fade|init|run}" >&2
        exit 1
        ;;
esac
