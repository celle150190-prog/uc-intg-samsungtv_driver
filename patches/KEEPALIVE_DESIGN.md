# Keep-alive test design

Reference archive: `uc-intg-samsungtv_driver-1.5.1-wol-localbroadcast-aarch64.tar(3).gz`
Reference SHA-256: `4af296d6ab1e6796b8484ee945be7eb33091904d962a13bb0dfecddca3c8d5e0`

Goal: after the TV is switched off, perform one harmless local Samsung REST GET `/api/v2/` once per hour for up to 24 hours. No KEY command, no power command, no WebSocket command is sent by the keep-alive task.

The custom driver must remain a normal PyInstaller ARM64 `bin/driver`; no shell wrapper or sidecar process is used.
