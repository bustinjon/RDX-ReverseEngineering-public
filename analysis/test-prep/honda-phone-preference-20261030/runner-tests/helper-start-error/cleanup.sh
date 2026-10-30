#!/system/bin/sh
dir='/data/local/tmp/rdx_05b1b4e01f83419cbfe143d5601baf6c'
: > "$dir/cancel"
am force-stop com.rdx.fullscreen.usbhelper || exit 4
# Restore only our exact write; preserve settings changed subsequently by someone else.
current=$(settings get secure enabled_accessibility_services)
if [ "$current" = 'org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService' ]; then
  settings put secure enabled_accessibility_services 'org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/.PermissionClickService' || exit 5
  if [ "$(settings get secure accessibility_enabled)" = '1' ]; then
    settings put secure accessibility_enabled '1' || exit 6
  fi
  echo ACCESSIBILITY_RESTORED
else
  echo ACCESSIBILITY_NOT_RESTORED_SETTINGS_CHANGED
fi
echo CLEANUP_FINISHED
if [ -s '/data/local/tmp/rdx_05b1b4e01f83419cbfe143d5601baf6c/capture.pid' ]; then
  capture_pid=$(cat '/data/local/tmp/rdx_05b1b4e01f83419cbfe143d5601baf6c/capture.pid')
  case "$capture_pid" in ''|*[!0-9]*) exit 7 ;; esac
  if kill -0 "$capture_pid" 2>/dev/null; then
    capture_command=$(cat "/proc/$capture_pid/cmdline")
    case "$capture_command" in
      *'/data/local/tmp/rdx_05b1b4e01f83419cbfe143d5601baf6c/capture.log'*) kill "$capture_pid" || exit 8 ;;
      *) echo CAPTURE_PID_IDENTITY_MISMATCH; exit 9 ;;
    esac
  fi
fi
