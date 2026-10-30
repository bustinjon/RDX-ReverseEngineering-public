#!/system/bin/sh
# Independent of the laptop and Honda loop. No invocation during offline validation.
dir=$1
seconds=$2
case "$dir" in /data/local/tmp/rdx_*) ;; *) exit 2 ;; esac
case "$seconds" in ''|*[!0-9]*) exit 2 ;; esac
[ "$seconds" -ge 60 ] && [ "$seconds" -le 300 ] || exit 2
read uptime rest < /proc/uptime || exit 3
deadline=$((${uptime%%.*} + seconds))
echo "$deadline" > "$dir/deadline" || exit 3
echo "WATCHDOG_STARTED deadline=$deadline"
sleep "$seconds"
sh "$dir/cleanup.sh"
