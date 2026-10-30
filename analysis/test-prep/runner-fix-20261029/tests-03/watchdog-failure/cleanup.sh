#!/system/bin/sh
dir='/data/local/tmp/rdx_0c69c546ad964d9591e24ec4a649c289'
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
