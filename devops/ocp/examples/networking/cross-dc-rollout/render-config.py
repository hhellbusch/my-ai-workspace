#!/usr/bin/env python3
"""Render NNCP Helm values, test env files, and Kafka net Helm values from inventory YAML."""

from __future__ import annotations

import argparse
import ipaddress
import sys
from pathlib import Path
from string import Template
from typing import Any

try:
    import yaml
except ImportError:
    print("Missing PyYAML — install python3-pyyaml (dnf install python3-pyyaml)", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent
NNCP_CHART = ROOT.parent.parent / "messaging" / "kafka" / "cross-dc-nncp-helm"
KAFKA_NET_CHART = ROOT.parent.parent / "messaging" / "kafka" / "cross-dc-kafka-net-helm"
TEST_DIR = ROOT.parent / "cross-dc-network-test"
TEMPLATE_DIR = ROOT / "templates"

BROKER_IPAM_MODES = frozenset({"whereabouts", "static"})


def load_inventory(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        raise SystemExit(f"{path}: expected a YAML mapping at top level")
    return data


def side_prefix(cluster_id: str) -> str:
    cid = cluster_id.lower().replace("-", "")
    if cid.endswith("a"):
        return "A"
    if cid.endswith("b"):
        return "B"
    raise SystemExit(f"cluster.id must end with -a or -b (got {cluster_id!r})")


def bond_vlan_iface(net: dict[str, Any]) -> str:
    return f"{net['bondName']}.{net['vlanId']}"


def parse_ip(value: str, label: str) -> ipaddress.IPv4Address:
    try:
        return ipaddress.IPv4Address(value)
    except ipaddress.AddressValueError as exc:
        raise SystemExit(f"{label}: invalid IPv4 address {value!r}") from exc


def pool_bounds(pool: dict[str, str]) -> tuple[ipaddress.IPv4Address, ipaddress.IPv4Address]:
    start = parse_ip(pool["start"], "pool start")
    end = parse_ip(pool["end"], "pool end")
    if int(start) > int(end):
        raise SystemExit(f"pool start {start} is after end {end}")
    return start, end


def broker_ipam_mode(inv: dict[str, Any]) -> str:
    wl = inv.get("workload", {})
    mode = wl.get("brokerIpam", {}).get("mode", "whereabouts")
    if mode not in BROKER_IPAM_MODES:
        raise SystemExit(
            f"workload.brokerIpam.mode must be one of {sorted(BROKER_IPAM_MODES)} (got {mode!r})"
        )
    return mode


def ip_in_pool(ip: ipaddress.IPv4Address, pool: dict[str, str]) -> bool:
    lo, hi = pool_bounds(pool)
    return int(lo) <= int(ip) <= int(hi)


def validate_inventory(inv: dict[str, Any]) -> None:
    net = inv["replicationNetwork"]
    mode = broker_ipam_mode(inv)
    wl = inv["workload"]
    brokers = wl.get("brokers") or []

    host_ips: set[ipaddress.IPv4Address] = set()
    for node in inv["nodes"]:
        host_ips.add(parse_ip(node["hostIp"], node["hostname"]))

    pools: dict[str, tuple[ipaddress.IPv4Address, ipaddress.IPv4Address]] = {}
    for name, pool in inv["ipPools"].items():
        pools[name] = pool_bounds(pool)
        for ip in host_ips:
            lo, hi = pools[name]
            if int(lo) <= int(ip) <= int(hi):
                raise SystemExit(
                    f"host IP {ip} falls in {name} pool ({pool['start']}-{pool['end']})"
                )

    if "test" in pools and "kafka" in pools:
        t_lo, t_hi = pools["test"]
        k_lo, k_hi = pools["kafka"]
        if not (t_hi < k_lo or k_hi < t_lo):
            raise SystemExit("test and kafka IP pools overlap — carve disjoint ranges")

    if mode == "whereabouts":
        pool = inv["ipPools"].get("kafka")
        if not pool or not pool.get("start") or not pool.get("end"):
            raise SystemExit("brokerIpam.mode=whereabouts requires ipPools.kafka range/start/end")
        if brokers:
            raise SystemExit(
                "workload.brokers should be empty when brokerIpam.mode=whereabouts "
                "(use static mode for per-broker replIp rows)"
            )
    else:
        if not brokers:
            raise SystemExit("brokerIpam.mode=static requires workload.brokers[] with name + replIp")
        seen: set[str] = set()
        seen_ips: set[ipaddress.IPv4Address] = set()
        kafka_pool = inv["ipPools"].get("kafka", {})
        for broker in brokers:
            name = broker.get("name")
            repl = broker.get("replIp")
            if not name or not repl:
                raise SystemExit("each workload.brokers row needs name and replIp")
            if name in seen:
                raise SystemExit(f"duplicate broker name: {name}")
            seen.add(name)
            ip = parse_ip(repl, name)
            if ip in seen_ips:
                raise SystemExit(f"duplicate broker replIp: {repl}")
            seen_ips.add(ip)
            if ip in host_ips:
                raise SystemExit(f"broker {name} replIp {repl} collides with a host IP")
            test_pool = inv["ipPools"].get("test")
            if test_pool and ip_in_pool(ip, test_pool):
                raise SystemExit(f"broker {name} replIp {repl} falls in test pool")
            if kafka_pool and ip_in_pool(ip, kafka_pool):
                pass  # static brokers typically live inside kafka pool — OK


def render_nncp_values(inv: dict[str, Any]) -> dict[str, Any]:
    net = inv["replicationNetwork"]
    return {
        "replicationNetwork": {
            "bondName": net["bondName"],
            "bondMode": net["bondMode"],
            "ports": net["ports"],
            "vlanId": net["vlanId"],
            "prefixLength": net["prefixLength"],
            "maxUnavailable": 1,
            "localGateway": net["localGateway"],
            "remoteSubnet": net["remoteSubnet"],
        },
        "nodes": [
            {"hostname": n["hostname"], "ip": n["hostIp"]} for n in inv["nodes"]
        ],
    }


def render_kafka_values(inv: dict[str, Any]) -> dict[str, Any]:
    net = inv["replicationNetwork"]
    wl = inv["workload"]
    mode = broker_ipam_mode(inv)
    prefix = net.get("prefixLength", 26)

    values: dict[str, Any] = {
        "replicationNetwork": {
            "bondName": net["bondName"],
            "vlanId": net["vlanId"],
            "prefixLength": prefix,
            "localGateway": net["localGateway"],
            "remoteSubnet": net["remoteSubnet"],
        },
        "workload": {
            "namespace": wl["namespace"],
            "nadName": wl["nadName"],
            "cniType": wl.get("cniType", "macvlan"),
            "macvlanMode": wl.get("macvlanMode", "bridge"),
            "replicationPort": wl["replicationPort"],
            "podSelector": wl["podSelector"],
        },
        "ipam": {
            "mode": mode,
            "prefixLength": prefix,
        },
        "brokers": [],
        "multiNetworkPolicy": {
            "defaultDenyOnNad": (wl.get("multiNetworkPolicy") or {}).get(
                "defaultDenyOnNad", True
            ),
        },
    }

    if mode == "whereabouts":
        pool = inv["ipPools"]["kafka"]
        values["ipam"].update(
            {
                "range": pool["range"],
                "rangeStart": pool["start"],
                "rangeEnd": pool["end"],
            }
        )
    else:
        values["brokers"] = [
            {"name": b["name"], "replIp": b["replIp"]} for b in (wl.get("brokers") or [])
        ]

    return values


def render_test_env(inv: dict[str, Any]) -> str:
    net = inv["replicationNetwork"]
    pool = inv["ipPools"]["test"]
    prefix = side_prefix(inv["cluster"]["id"])
    test_nodes = [
        n["hostname"]
        for n in inv["nodes"]
        if n.get("networkTest", True)
    ]
    if not test_nodes:
        raise SystemExit("no nodes marked for networkTest — set networkTest: true on at least one node")

    lines = [
        "# Generated from inventory — do not edit by hand; re-run render-config.py",
        f"export DC{prefix}_KUBECONFIG=\"{inv['cluster']['kubeconfig']}\"",
        f"export DC{prefix}_NODE_NAMES=\"{' '.join(test_nodes)}\"",
        f"export DC{prefix}_BOND_VLAN_IFACE=\"{bond_vlan_iface(net)}\"",
        f"export DC{prefix}_LOCAL_GATEWAY=\"{net['localGateway']}\"",
        f"export DC{prefix}_REMOTE_SUBNET=\"{net['remoteSubnet']}\"",
        f"export DC{prefix}_TEST_POOL_RANGE=\"{pool['range']}\"",
        f"export DC{prefix}_TEST_POOL_START=\"{pool['start']}\"",
        f"export DC{prefix}_TEST_POOL_END=\"{pool['end']}\"",
        f"export DC{prefix}_EXPECTED_MTU=\"{net['expectedMtu']}\"",
        f"export TEST_PROBE_IMAGE=\"{inv['probe']['image']}\"",
        "",
    ]
    return "\n".join(lines)


def write_yaml(path: Path, data: dict[str, Any], header: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        fh.write(f"# {header}\n")
        fh.write("# Source: render-config.py — edit inventory YAML and re-render\n\n")
        yaml.dump(data, fh, default_flow_style=False, sort_keys=False)


def render_firewall_request(inv_a: dict[str, Any], inv_b: dict[str, Any]) -> str:
    template_path = TEMPLATE_DIR / "firewall-change-request.md.example"
    tpl = Template(template_path.read_text(encoding="utf-8"))

    def kafka_firewall_note(inv: dict[str, Any]) -> str:
        mode = broker_ipam_mode(inv)
        if mode == "static":
            ips = ", ".join(b["replIp"] for b in inv["workload"].get("brokers") or [])
            return f"static broker /32s: {ips}"
        pool = inv["ipPools"]["kafka"]
        return f"pool {pool['start']}-{pool['end']}"

    net_a = inv_a["replicationNetwork"]
    net_b = inv_b["replicationNetwork"]
    pool_a = inv_a["ipPools"]
    pool_b = inv_b["ipPools"]
    port = inv_a["workload"]["replicationPort"]
    return tpl.substitute(
        dc_a_id=inv_a["cluster"]["id"],
        dc_b_id=inv_b["cluster"]["id"],
        dc_a_subnet=net_a["localSubnet"],
        dc_b_subnet=net_b["localSubnet"],
        dc_a_test_pool=f"{pool_a['test']['start']}-{pool_a['test']['end']}",
        dc_b_test_pool=f"{pool_b['test']['start']}-{pool_b['test']['end']}",
        dc_a_kafka_pool=f"{pool_a['kafka']['start']}-{pool_a['kafka']['end']}",
        dc_b_kafka_pool=f"{pool_b['kafka']['start']}-{pool_b['kafka']['end']}",
        dc_a_kafka_firewall=kafka_firewall_note(inv_a),
        dc_b_kafka_firewall=kafka_firewall_note(inv_b),
        replication_port=port,
        expected_mtu=net_a["expectedMtu"],
    )


def render_one(inventory_path: Path, write: bool = True) -> dict[str, Path]:
    inv = load_inventory(inventory_path)
    validate_inventory(inv)
    cid = inv["cluster"]["id"]
    outputs = {
        "nncp_values": NNCP_CHART / f"values-{cid}.yaml",
        "kafka_values": KAFKA_NET_CHART / f"values-{cid}.yaml",
        "test_env": TEST_DIR / f"dc-{cid.split('-')[-1]}.env",
    }
    if not write:
        return outputs

    write_yaml(
        outputs["nncp_values"],
        render_nncp_values(inv),
        f"NNCP Helm values for {cid}",
    )
    write_yaml(
        outputs["kafka_values"],
        render_kafka_values(inv),
        f"Kafka NAD/MultiNetworkPolicy Helm values for {cid} (brokerIpam.mode={broker_ipam_mode(inv)})",
    )
    outputs["test_env"].write_text(render_test_env(inv), encoding="utf-8")
    return outputs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--inventory",
        type=Path,
        help="Path to inventory-dc-a.yaml or inventory-dc-b.yaml",
    )
    parser.add_argument(
        "--both",
        action="store_true",
        help="Render from inventory-dc-a.yaml and inventory-dc-b.yaml in this directory",
    )
    parser.add_argument(
        "--firewall-request",
        type=Path,
        help="Write firewall change request markdown to this path (requires both inventories)",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Validate inventory without writing files",
    )
    args = parser.parse_args()

    if args.both:
        paths = [ROOT / "inventory-dc-a.yaml", ROOT / "inventory-dc-b.yaml"]
    elif args.inventory:
        paths = [args.inventory]
    else:
        parser.error("pass --inventory or --both")

    results = []
    for path in paths:
        if not path.is_file():
            raise SystemExit(f"inventory not found: {path} (copy from *.example.yaml)")
        out = render_one(path, write=not args.validate_only)
        results.append((path, out))

    if args.firewall_request:
        inv_a = load_inventory(ROOT / "inventory-dc-a.yaml")
        inv_b = load_inventory(ROOT / "inventory-dc-b.yaml")
        validate_inventory(inv_a)
        validate_inventory(inv_b)
        args.firewall_request.parent.mkdir(parents=True, exist_ok=True)
        args.firewall_request.write_text(
            render_firewall_request(inv_a, inv_b), encoding="utf-8"
        )
        print(f"Wrote {args.firewall_request}")

    if args.validate_only:
        for path, _ in results:
            print(f"OK: {path} (brokerIpam.mode={broker_ipam_mode(load_inventory(path))})")
        return

    for path, out in results:
        print(f"From {path.name}:")
        for label, target in out.items():
            print(f"  {label}: {target}")


if __name__ == "__main__":
    main()
