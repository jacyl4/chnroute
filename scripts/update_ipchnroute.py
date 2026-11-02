#!/usr/bin/env python3
"""Merge validated China IPv4 sources without replacing output on total failure."""

import hashlib
import http.client
import ipaddress
import json
import os
from pathlib import Path
import sys
import tempfile
import urllib.request

from ip_cidr_dedupe import _iter_networks


SOURCES = (
    ("apnic", "https://ftp.apnic.net/stats/apnic/delegated-apnic-extended-latest"),
    ("apnic", "https://ftp.iana.org/pub/mirror/rirstats/apnic/delegated-apnic-extended-latest"),
    ("apnic", "https://ftp.lacnic.net/pub/stats/apnic/delegated-apnic-extended-latest"),
    ("cidr", "https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"),
    ("cidr", "https://ispip.clang.cn/all_cn.txt"),
    ("cidr", "https://ispip.clang.cn/all_cn_apnic.txt"),
    ("cidr", "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/china.txt"),
    ("cidr", "https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt"),
    ("ripe", "https://stat.ripe.net/data/country-resource-list/data.json?resource=cn&v4_format=prefix"),
)


def parse_source(kind, text):
    if kind == "ripe":
        payload = json.loads(text)
        if not isinstance(payload, dict) or payload.get("status") != "ok":
            raise ValueError("RIPEstat response is not OK")
        rows = payload["data"]["resources"]["ipv4"]
        if not isinstance(rows, list):
            raise ValueError("RIPEstat IPv4 resources must be a list")
    elif kind == "apnic":
        rows = []
        for line in text.splitlines():
            fields = line.split("|")
            if len(fields) < 3 or fields[:3] != ["apnic", "CN", "ipv4"]:
                continue
            if len(fields) < 7:
                raise ValueError("truncated APNIC CN IPv4 record")
            if fields[6] not in ("allocated", "assigned"):
                continue
            start = ipaddress.IPv4Address(fields[3])
            count = int(fields[4])
            if count <= 0:
                raise ValueError("invalid APNIC address count")
            end = ipaddress.IPv4Address(int(start) + count - 1)
            rows.extend(str(net) for net in ipaddress.summarize_address_range(start, end))
    elif kind == "cidr":
        rows = [line.strip() for line in text.splitlines()
                if line.strip() and not line.lstrip().startswith("#")]
    else:
        raise ValueError(f"unknown source format: {kind}")

    # Reject an entire malformed response, rather than extracting IPs from HTML.
    networks = [ipaddress.IPv4Network(row, strict=False) for row in rows]
    if not networks or any(net.prefixlen == 0 for net in networks):
        raise ValueError("empty source or unexpected default route")
    return networks


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "chnroute-updater/1.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8-sig")


def update(output=Path("IPchnroute"), sources=SOURCES, fetcher=fetch):
    networks = []
    successful = 0
    for kind, url in sources:
        try:
            source_networks = parse_source(kind, fetcher(url))
        except (OSError, http.client.HTTPException, ValueError, KeyError, TypeError) as exc:
            print(f"WARNING: skipped {url}: {exc}", file=sys.stderr)
            continue
        successful += 1
        networks.extend(str(net) for net in source_networks)
        print(f"OK: {url}: {len(source_networks)} IPv4 blocks", file=sys.stderr)

    if not successful:
        raise RuntimeError("all IP sources failed; existing output left unchanged")

    merged = ipaddress.collapse_addresses(_iter_networks(networks))
    data = "".join(f"{net}\n" for net in merged).encode("ascii")
    checksum = (hashlib.sha256(data).hexdigest() + "\n").encode("ascii")
    pending = []
    try:
        for target, content in ((output, data), (Path(str(output) + ".sha256sum"), checksum)):
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as temp:
                pending.append((Path(temp.name), target))
                temp.write(content)
            os.chmod(temp.name, target.stat().st_mode & 0o777 if target.exists() else 0o644)
        for temporary, target in pending:
            os.replace(temporary, target)
    finally:
        for temporary, _ in pending:
            temporary.unlink(missing_ok=True)
    print(f"Merged {successful}/{len(sources)} sources into {len(data.splitlines())} CIDRs",
          file=sys.stderr)


if __name__ == "__main__":
    try:
        update()
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
