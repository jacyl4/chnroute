import http.client
import ipaddress
from pathlib import Path
import random
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import generate_ros as ros


def nets(*values):
    return [ipaddress.IPv4Network(value) for value in values]


def members(networks):
    return {int(ip) for network in networks for ip in network}


class ClassificationTests(unittest.TestCase):
    def test_ct_unknown_and_all_other_operators(self):
        country = nets("1.0.0.0/24")
        records = [(0, "CT", nets("1.0.0.0/27"))]
        for index, label in enumerate(("CU", "CMCC", "CBTN", "CERNET", "GWBN"), 1):
            records.append((0, label, nets(f"1.0.0.{index * 32}/27")))
        ct, other = ros.classify(country, records)
        self.assertEqual(members(ct), members(nets("1.0.0.0/27", "1.0.0.192/26")))
        self.assertFalse(members(ct) & members(other))
        self.assertEqual(members(ct) | members(other), members(country))

    def test_source_priority_overrides_lower_tier_specificity(self):
        country = nets("1.0.0.0/24")
        records = [(0, "CT", country), (1, "CMCC", nets("1.0.0.0/25")),
                   (2, "CU", nets("1.0.0.128/25"))]
        self.assertEqual(ros.classify(country, records), (country, []))

    def test_longest_prefix_and_ct_exact_tie(self):
        country = nets("1.0.0.0/24")
        records = [(0, "CT", country), (0, "CMCC", nets("1.0.0.0/25")),
                   (0, "CT", nets("1.0.0.0/26")), (0, "CU", nets("1.0.0.0/26"))]
        ct, other = ros.classify(country, records)
        self.assertEqual(other, nets("1.0.0.64/26"))
        self.assertEqual(ros.classify(country, list(reversed(records))), (ct, other))

    def test_clip_outside_country_and_merge_adjacent(self):
        country = nets("1.0.0.0/25", "1.0.0.128/25", "2.0.0.0/24")
        records = [(0, "CMCC", nets("1.0.0.0/16", "3.0.0.0/24"))]
        self.assertEqual(ros.classify(country, records),
                         (nets("2.0.0.0/24"), nets("1.0.0.0/24")))

    def test_top_of_ipv4_space(self):
        country = nets("255.255.255.252/30")
        ct, other = ros.classify(country, [(0, "CU", nets("255.255.255.255/32"))])
        self.assertEqual(members(ct) | members(other), members(country))
        self.assertEqual(other, nets("255.255.255.255/32"))

    def test_randomized_classification_matches_per_address_oracle(self):
        rng = random.Random(20261102)
        country = nets("1.0.0.0/24")
        base = int(country[0].network_address)
        for case in range(60):
            records = []
            for _ in range(25):
                prefix = rng.randint(23, 32)
                address = ipaddress.IPv4Address(base + rng.randrange(256))
                network = ipaddress.IPv4Network(f"{address}/{prefix}", strict=False)
                records.append((rng.randrange(3), rng.choice(("CT", "CU", "CMCC")), [network]))
            ct, other = ros.classify(country, records)
            expected_ct = set()
            for ip in country[0]:
                candidates = [(tier, -net.prefixlen, label != "CT")
                              for tier, label, networks in records for net in networks if ip in net]
                if not candidates or not min(candidates)[2]:
                    expected_ct.add(int(ip))
            with self.subTest(case=case):
                self.assertEqual(members(ct), expected_ct)
                self.assertEqual(members(other), members(country) - expected_ct)


class GenerationTests(unittest.TestCase):
    def test_all_outputs_share_the_same_partition(self):
        ct, other = nets("1.0.0.0/25"), nets("1.0.0.128/25")
        outputs = ros.render(ct, other)
        self.assertEqual(outputs["ros-pbr-CT-CMCC.rsc"],
                         "/ip route rule\nadd dst-address=1.0.0.0/25 action=lookup table=CT\n"
                         "add dst-address=1.0.0.128/25 action=lookup table=CMCC\n")
        cmcc = outputs["ros-dpbr-CT-CMCC.rsc"]
        self.assertEqual(outputs["ros-dpbr-CT-CU.rsc"], cmcc.replace("dpbr-CMCC", "dpbr-CU"))
        self.assertIn("add list=dpbr-CT address=1.0.0.0/25\n", cmcc)

    def test_source_failure_uses_fallback(self):
        sources = [(0, "CT", "offline"), (2, "CT", "fallback"), (0, "CMCC", "good")]

        def fetch(url):
            if url == "offline":
                raise http.client.IncompleteRead(b"truncated")
            return "1.0.0.0/25" if url == "fallback" else "1.0.0.128/25"

        records = ros.load_sources(sources, fetch)
        self.assertEqual(len(records), 2)

    def test_missing_operator_category_preserves_all_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "IPchnroute").write_text("1.0.0.0/24\n")
            for filename in ros.render([], []):
                (root / filename).write_text("old rules\n")
            sources = [(0, "CT", "valid"), (0, "CMCC", "empty")]
            with self.assertRaises(RuntimeError):
                ros.update(root, sources, lambda url: "1.0.0.0/25" if url == "valid" else "")
            for filename in ros.render([], []):
                self.assertEqual((root / filename).read_text(), "old rules\n")

    def test_update_and_no_temporary_or_bytecode_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "IPchnroute").write_text("1.0.0.0/24\n")
            sources = [(0, "CT", "ct"), (0, "CU", "cu")]
            ros.update(root, sources, lambda url: "1.0.0.0/25" if url == "ct" else "1.0.0.128/25")
            self.assertEqual(len(list(root.iterdir())), 4)
            self.assertEqual((root / "ros-dpbr-CT-CMCC.rsc").read_text(),
                             ros.render(nets("1.0.0.0/25"), nets("1.0.0.128/25"))["ros-dpbr-CT-CMCC.rsc"])


if __name__ == "__main__":
    unittest.main()
