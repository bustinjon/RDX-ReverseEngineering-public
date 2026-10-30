#!/system/bin/sh
dir='/data/local/tmp/rdx_6a698b6743724af6a669e31921acb866'
: > "$dir/cancel"
am startservice -a aa.overlay.STOP -n com.rdx.fullscreen.usbhelper/.AaOverlayService
am force-stop com.rdx.fullscreen.usbhelper
# Restore only our exact write; preserve settings changed subsequently by someone else.
current=$(settings get secure enabled_accessibility_services)
if [ "$current" = 'org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService' ]; then
  settings put secure enabled_accessibility_services 'org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/.PermissionClickService'
  if [ "$(settings get secure accessibility_enabled)" = '1' ]; then
    settings put secure accessibility_enabled '1'
  fi
fi
echo CLEANUP_FINISHED
