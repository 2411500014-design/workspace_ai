"""The computer's addresses on the local network, so a phone on the same Wi-Fi can connect."""

from __future__ import annotations

import ipaddress
import socket


def lan_addresses() -> list[str]:
    """Private IPv4 addresses of this machine, best guess first. Never raises."""
    found: list[str] = []
    try:
        # Connecting a UDP socket sends nothing; it only picks the outgoing interface.
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.connect(("10.255.255.255", 1))
            found.append(probe.getsockname()[0])
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            found.append(str(info[4][0]))
    except OSError:
        pass
    result: list[str] = []
    for address in found:
        try:
            ip = ipaddress.ip_address(address)
        except ValueError:
            continue
        if ip.is_private and not ip.is_loopback and not ip.is_link_local and address not in result:
            result.append(address)
    return result


def accepts_connections(address: str, port: int, timeout: float = 0.3) -> bool:
    """Whether this server can be reached on ``address``: false when it listens on localhost only."""
    try:
        with socket.create_connection((address, port), timeout=timeout):
            return True
    except OSError:
        return False
