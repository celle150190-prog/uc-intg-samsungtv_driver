from pathlib import Path

p = Path('upstream/intg-samsungtv/tv.py')
s = p.read_text()
MARK = 'Samsung REST keep-alive'
if MARK in s:
    raise SystemExit('keep-alive patch already present')

s = s.replace('import logging\n', 'import logging\nimport netifaces\n', 1)
s = s.replace(
    '        self._mac_address: str = device_config.mac_address or ""\n',
    '        self._mac_address: str = device_config.mac_address or ""\n        self._keepalive_task: asyncio.Task | None = None\n        self._keepalive_until: datetime | None = None\n', 1)

anchor = '''    @property\n    def timeout(self) -> int:\n        """Return the timeout for the connection."""\n        if self._device_config.token == "":\n            return 30\n        return 3\n\n'''
insert = '''    @property\n    def timeout(self) -> int:\n        """Return the timeout for the connection."""\n        if self._device_config.token == "":\n            return 30\n        return 3\n\n    def _local_broadcast_address(self) -> str:\n        """Return the IPv4 broadcast address of the default network interface."""\n        try:\n            gateways = netifaces.gateways().get("default", {})\n            default_ipv4 = gateways.get(netifaces.AF_INET)\n            if default_ipv4:\n                interface = default_ipv4[1]\n                addresses = netifaces.ifaddresses(interface).get(netifaces.AF_INET, [])\n                if addresses and addresses[0].get("broadcast"):\n                    return addresses[0]["broadcast"]\n        except Exception as ex:  # pylint: disable=broad-exception-caught\n            _LOG.debug("[%s] Unable to determine local broadcast address: %s", self.log_id, ex)\n        return "255.255.255.255"\n\n    def _start_rest_keepalive(self) -> None:\n        """Start the hourly Samsung REST keep-alive for up to 24 hours."""\n        self._stop_rest_keepalive()\n        self._keepalive_until = datetime.utcnow() + timedelta(hours=24)\n        self._keepalive_task = asyncio.create_task(self._rest_keepalive_loop())\n        _LOG.debug("[%s] %s started (hourly, max 24h)", self.log_id, MARK)\n\n    def _stop_rest_keepalive(self) -> None:\n        """Stop an active Samsung REST keep-alive task."""\n        if self._keepalive_task is not None:\n            self._keepalive_task.cancel()\n            self._keepalive_task = None\n        self._keepalive_until = None\n\n    async def _rest_keepalive_loop(self) -> None:\n        """Query the Samsung REST API once per hour while the TV is off."""\n        try:\n            while self._keepalive_until and datetime.utcnow() < self._keepalive_until:\n                await asyncio.sleep(3600)\n                if not self._keepalive_until or datetime.utcnow() >= self._keepalive_until:\n                    break\n                if self._power_state != MediaStates.OFF:\n                    _LOG.debug("[%s] %s stopped because TV state is %s", self.log_id, MARK, self._power_state)\n                    break\n                info = self.get_device_info()\n                power_state = info.get("device", {}).get("PowerState")\n                _LOG.debug("[%s] %s: REST /api/v2/ PowerState=%s", self.log_id, MARK, power_state)\n        except asyncio.CancelledError:\n            raise\n        except Exception as ex:  # pylint: disable=broad-exception-caught\n            _LOG.debug("[%s] %s failed: %s", self.log_id, MARK, ex)\n        finally:\n            self._keepalive_task = None\n            self._keepalive_until = None\n\n'''
if anchor not in s:
    raise SystemExit('timeout anchor not found')
s = s.replace(anchor, insert, 1)

s = s.replace(
    '''    async def _handle_power_on(self) -> None:\n        """Handle turning the TV on."""\n''',
    '''    async def _handle_power_on(self) -> None:\n        """Handle turning the TV on."""\n        self._stop_rest_keepalive()\n''', 1)

old = '''            self._end_of_power_off = datetime.utcnow() + timedelta(seconds=65)\n            self._power_state = MediaStates.OFF\n'''
new = '''            self._end_of_power_off = datetime.utcnow() + timedelta(seconds=65)\n            self._power_state = MediaStates.OFF\n            self._start_rest_keepalive()\n'''
if old not in s:
    raise SystemExit('power-off anchor not found')
s = s.replace(old, new, 1)

old_wol = '''            wakeonlan.send_magic_packet(self._device_config.mac_address)\n'''
new_wol = '''            wakeonlan.send_magic_packet(\n                self._device_config.mac_address,\n                ip_address=self._local_broadcast_address(),\n            )\n'''
if old_wol not in s:
    raise SystemExit('WOL anchor not found')
s = s.replace(old_wol, new_wol, 1)

p.write_text(s)
print('Applied hourly REST keep-alive + local-broadcast WOL patch')
