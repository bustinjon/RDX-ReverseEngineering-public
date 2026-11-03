# Helper activation only

User explicitly said "Do it" in response to the proposed same-APK, helper-running Diagnostics comparison. This authorizes the necessary ADB/helper-start step despite the earlier blanket device boundary. It does not authorize M5/M6 milestones, phone handoff, an AA session or additional features.

Start UsbHelperService only on the verified 21037 APK using its existing cooperative phone-scoped configuration action. Keep auto-clicker/accessibility and overlay off. No reinstall or OEM settings changes. Preserve existing preflight/firmware/lock-task checks, with no bypass. Save startup evidence and installed hash. On refusal after attempted activation, force-stop only this helper package and save cleanup evidence. No Git or source edits.

This isolates helper startup from auto-clicker activation and overlay capture arming, which must not be silently included. The existing configuration action persists the helper's cooperative phone identity before startup to prevent legacy Honda-force-stop/VBUS behavior; this own-app configuration is documented as part of activation, not claimed to be a bit-for-bit app-data invariant.
