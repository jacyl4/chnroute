#!/usr/bin/env python3

"""Collapse and deduplicate IPv4 CIDR blocks read from stdin."""

import ipaddress
import sys


def _iter_networks(lines):
    """Yield IPv4Network instances from the provided line iterator."""
    seen = set()
    for raw in lines:
        line = raw.strip()
        if not line or line in seen:
            continue
        seen.add(line)
        try:
            yield ipaddress.IPv4Network(line, strict=False)
        except ValueError:
            continue


def main() -> int:
    collapsed = sorted(
        ipaddress.collapse_addresses(_iter_networks(sys.stdin)),
        key=lambda net: (int(net.network_address), net.prefixlen),
    )

    for network in collapsed:
        print(network)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
