# Wireless Android Auto on the RDX head unit: feasibility (offline, 2026-11-05)

**Verdict: plausible, not proven (medium confidence).** All the hardware and the standard Android pieces are present. Our protocol stack can already run over any byte pipe. Two unknowns can only be answered on the car:
1. Will the car's Bluetooth stack let our app publish the Android Auto wireless service?
2. Is 1080p60 video stable over the car's Wi-Fi?

Both can be probed cheaply as Settings switches, one at a time.

Sources:
- open-headunit (AGPL-3.0, ideas only): `connection/wifi/modes/nativeaa/*`, `connection/wifi/direct/*`, `connection/projection/SocketProjectionConnection.kt`.
- The car dump from today's survey: `analysis/test-prep/todo-tests-20261103/capabilities-20261105-212242/`. It is private and holds network names and addresses, so it must not be published.

## How wireless Android Auto works (from open-headunit)
1. The phone is already paired with the car over Bluetooth for calls.
2. The car publishes a Bluetooth RFCOMM service with the Android Auto UUID `4de17a00-52cb-11e6-bdf4-0800200c9a66`. Open-headunit uses the plain `BluetoothAdapter.listenUsingRfcommWithServiceRecord`.
3. Over that link the car sends a start request: our IP address and port. The phone asks for Wi-Fi details, and the car sends the network name, password, security WPA2 and access-point type (WppMessages: types 1 and 3).
4. The phone joins the car's Wi-Fi, either a Wi-Fi Direct group or a normal hotspot. Open-headunit notes that ZLink does it over a plain WPA2 access point.
5. The phone opens TCP to the car (port 5288). From there it is the same Android Auto protocol as over USB: version exchange, TLS, channels.

## What the car has (from today's dump; high confidence)
| Need | Car | Notes |
|---|---|---|
| Wi-Fi | `android.hardware.wifi`; Wi-Fi on, station mode, not connected | Its scan list includes 5 GHz networks, so the radio is dual-band |
| Wi-Fi Direct | `android.hardware.wifi.direct`; `p2p_supplicant` running; p2p0 set up at boot | Group creation (`WifiP2pManager.createGroup`) needs only normal app permissions on 5.1 |
| Hotspot | Framework has an AP state (`mPersistWifiApState 0`); no tethering configured | Starting a hotspot from an app on 5.1 needs CHANGE_NETWORK_STATE, unless Honda configured a provisioning app (then system-only). Wi-Fi Direct is the safer first path |
| Bluetooth | Adapter on, name "HandsFreeLink". Profiles: Honda hands-free, A2DP sink, AVRCP, PAN, GATT, OPP, MAP | RFCOMM server sockets are core Bluetooth APIs (BLUETOOTH permission). **Unknown:** whether Honda's stack and its `bluetooth_secure_mode_manager` allow third-party service records |
| Internet in the car | Cellular modem (TCU, ppp0) connected | Not needed for AA. Worth noting for the parked extra-apps idea |

## What our side has (high confidence)
- `AaSessionService` moves frames through `transport.readFully/write/close`, with the native GalReceiver doing framing and TLS. A TCP socket can replace `UsbBulkTransport` with no protocol changes; open-headunit does the same with `SocketProjectionConnection`.
- The stock Honda native library also contains wireless projection pieces (WifiProjectionService, noted earlier). The protocol side is not the hard part.

## Risks and unknowns
1. **Bluetooth service record** (main unknown). Honda's hands-free stack might block or hide third-party RFCOMM records, or the phone might not query them. Probe P1 answers it with no Wi-Fi changes.
2. **Wi-Fi Direct behaviour.** Open-headunit has many recovery policies for flaky P2P: group churn, "Obtaining IP address" hangs, a wedged P2P stack. Expect tuning.
3. **Bandwidth and latency.** 1080p60 H.264 is about 10–20 Mbit/s. The radio is dual-band, but whether the P2P group lands on 5 GHz is unknown.
4. **Honda interference.** Honda's own Bluetooth and HFP must keep working. Calls and audio should not change, because AA wireless runs alongside HFP.
5. **Phone side.** Recent AA versions limit some start-up triggers. The README note is about tablet "self mode"; the Bluetooth route above is the official one cars use, so this risk is low.
6. **Licence.** Open-headunit is AGPL-3.0. Write our own code from these notes and do not copy files.

## Staged plan (each stage a Settings switch, off by default, one car visit each)
| Stage | What it does | Car risk | Answers |
|---|---|---|---|
| P1 Bluetooth probe | Publish the AA UUID service; log if the phone connects and what it sends first. No reply, no Wi-Fi | Very low (unplugging is not even needed; switch off) | Unknown 1 |
| P2 Wi-Fi Direct probe | Create a group, log name/band/IP, remove it after 60 s. No phone involved | Low | Whether groups work and which band |
| P3 Handshake | P1 plus answering with P2's credentials; log whether the phone joins and dials TCP | Low–medium | End-to-end setup |
| P4 Wireless session | TCP transport into the existing session code | Medium | Picture, touch and audio over Wi-Fi; stability |

USB stays the default throughout. Wireless only ever starts when its switch is on.

**Effort:** P1 and P2 are small, similar to one T60 feature each. P3 is moderate (the message formats are documented in open-headunit). P4 is moderate and mostly plumbing, plus tuning time.
