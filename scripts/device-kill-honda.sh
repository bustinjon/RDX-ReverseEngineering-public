#!/system/bin/sh
# Called with a unique session directory. Never execute during offline tests.
dir=$1
seconds=$2
case "$dir" in /data/local/tmp/rdx_*) ;; *) exit 2 ;; esac
case "$seconds" in 30) ;; *) exit 2 ;; esac
read uptime rest < /proc/uptime || exit 3
deadline=$((${uptime%%.*} + seconds))
echo "$deadline" > "$dir/honda-deadline" || exit 3
i=0
while [ "$i" -lt 300 ] && [ ! -e "$dir/cancel" ]; do
  read uptime rest < /proc/uptime || exit 3
  [ "${uptime%%.*}" -lt "$deadline" ] || break
  am force-stop com.honda.androidauto.projection.sink || exit 4
  i=$((i + 1))
  sleep 1
done
echo "HONDA_LOOP_FINISHED iterations=$i"
# One in-flight am command can overrun the deadline; the watchdog is independent.
