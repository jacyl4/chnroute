#!/usr/bin/env python3
"""Partition domestic IPv4 into CT (including unknown) and all other ISPs."""

from concurrent.futures import ThreadPoolExecutor
import heapq
import http.client
import ipaddress
import os
from pathlib import Path
import sys
import tempfile

from update_ipchnroute import fetch, parse_source


# Priority: IPNetDB first, BGP classifications second, APNIC fallback last.
# othernet is deliberately not a labelled operator: unclassified addresses go CT.
CLANG_OPERATORS = {
    "CT": "chinatelecom", "CU": "unicom_cnc", "CMCC": "cmcc",
    "CBTN": "chinabtn", "CERNET": "cernet", "GWBN": "gwbn",
}
BGP_OPERATORS = {
    "CT": "chinanet", "CU": "unicom", "CMCC": "cmcc", "CERNET": "cernet",
    "GWBN": "drpeng", "CSTNET": "cstnet", "GOOGLECN": "googlecn",
}
SOURCES = tuple(
    (priority, label, f"https://ispip.clang.cn/{name}{suffix}.txt")
    for priority, suffix in ((0, ""), (2, "_apnic"))
    for label, name in CLANG_OPERATORS.items()
) + tuple(
    (1, label, f"https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/{name}.txt")
    for label, name in BGP_OPERATORS.items()
)


def load_sources(sources=SOURCES, fetcher=fetch):
    def download(source):
        priority, label, url = source
        try:
            networks = parse_source("cidr", fetcher(url))
        except (OSError, http.client.HTTPException, ValueError, TypeError) as exc:
            print(f"WARNING: skipped {label} {url}: {exc}", file=sys.stderr)
            return None
        print(f"OK: {label} {url}: {len(networks)} IPv4 blocks", file=sys.stderr)
        return priority, label, networks

    with ThreadPoolExecutor(max_workers=8) as pool:
        records = [record for record in pool.map(download, sources) if record is not None]
    missing = {label for _, label, _ in sources} - {label for _, label, _ in records}
    if missing:
        raise RuntimeError("no valid source for operators: " + ", ".join(sorted(missing)))
    if not records:
        raise RuntimeError("no valid operator sources")
    return records


def classify(country, records):
    """Sweep address boundaries; source tier, specificity, then CT resolve ties."""
    events = {}

    def event(address, action):
        events.setdefault(address, []).append(action)

    for network in ipaddress.collapse_addresses(country):
        event(int(network.network_address), ("country", 1))
        event(int(network.broadcast_address) + 1, ("country", -1))
    identity = 0
    for priority, label, networks in records:
        # Do not collapse here: more-specific source records must retain precedence.
        for network in set(networks):
            key = (priority, -network.prefixlen, 0 if label == "CT" else 1, identity)
            event(int(network.network_address), ("add", (key, label)))
            event(int(network.broadcast_address) + 1, ("remove", identity))
            identity += 1

    active = set()
    heap = []
    domestic = 0
    ranges = {"CT": [], "OTHER": []}
    boundaries = sorted(events)
    for index, address in enumerate(boundaries[:-1]):
        for action, value in events[address]:
            if action == "country":
                domestic += value
            elif action == "add":
                key, label = value
                active.add(key[-1])
                heapq.heappush(heap, (key, label))
            else:
                active.discard(value)
        while heap and heap[0][0][-1] not in active:
            heapq.heappop(heap)
        if not domestic:
            continue
        label = heap[0][1] if heap else "CT"
        group = ranges["CT" if label == "CT" else "OTHER"]
        end = boundaries[index + 1] - 1
        if group and group[-1][1] + 1 == address:
            group[-1] = (group[-1][0], end)
        else:
            group.append((address, end))

    def cidrs(group):
        return [network for start, end in ranges[group]
                for network in ipaddress.summarize_address_range(
                    ipaddress.IPv4Address(start), ipaddress.IPv4Address(end))]

    return cidrs("CT"), cidrs("OTHER")


def render(ct, other):
    outputs = {}
    for alternate in ("CMCC", "CU"):
        lines = ["/ip firewall address-list"]
        for label, networks in (("CT", ct), (alternate, other)):
            lines.extend(f"add list=dpbr-{label} address={net}" for net in networks)
        outputs[f"ros-dpbr-CT-{alternate}.rsc"] = "\n".join(lines) + "\n"
    lines = ["/ip route rule"]
    for label, networks in (("CT", ct), ("CMCC", other)):
        lines.extend(f"add dst-address={net} action=lookup table={label}" for net in networks)
    outputs["ros-pbr-CT-CMCC.rsc"] = "\n".join(lines) + "\n"
    return outputs


def update(root=Path("."), sources=SOURCES, fetcher=fetch):
    country = parse_source("cidr", (root / "IPchnroute").read_text())
    ct, other = classify(country, load_sources(sources, fetcher))
    if not ct or not other:
        raise RuntimeError("empty CT or alternate group; existing rules left unchanged")
    merged = list(ipaddress.collapse_addresses(ct + other))
    if merged != list(ipaddress.collapse_addresses(country)):
        raise RuntimeError("operator groups do not cover IPchnroute")
    if sum(net.num_addresses for net in ct + other) != sum(net.num_addresses for net in merged):
        raise RuntimeError("operator groups overlap")

    pending = []
    try:
        for name, content in render(ct, other).items():
            target = root / name
            with tempfile.NamedTemporaryFile(dir=root, delete=False) as temporary:
                pending.append((Path(temporary.name), target))
                temporary.write(content.encode("ascii"))
            os.chmod(temporary.name, target.stat().st_mode & 0o777 if target.exists() else 0o644)
        for temporary, target in pending:
            os.replace(temporary, target)
    finally:
        for temporary, _ in pending:
            temporary.unlink(missing_ok=True)
    print(f"Generated all 3 RouterOS files: CT={len(ct)} CIDRs, alternate={len(other)} CIDRs; "
          "disjoint and covering IPchnroute", file=sys.stderr)


if __name__ == "__main__":
    try:
        update()
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
