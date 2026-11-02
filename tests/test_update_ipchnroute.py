import hashlib
import http.client
import importlib.util
import ipaddress
from pathlib import Path
import sys
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("updater", SCRIPTS / "update_ipchnroute.py")
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class ParseTests(unittest.TestCase):
    def test_cidr_comments_duplicates_and_host_bits(self):
        nets = updater.parse_source("cidr", "# generated\n\n1.0.0.1/24\n1.0.0.0/24\n")
        self.assertEqual([str(n) for n in nets], ["1.0.0.0/24"] * 2)

    def test_invalid_or_empty_sources_are_rejected(self):
        for text in ("", "# empty", "<html>1.0.0.0/24</html>",
                     "1.0.0.0/24\nbad", "::/0", "0.0.0.0/0"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                updater.parse_source("cidr", text)

    def test_apnic_non_power_of_two_range_and_filtering(self):
        text = "\n".join([
            "apnic|CN|ipv4|1.0.0.0|768|20260101|allocated|id",
            "apnic|CN|ipv4|1.0.4.0|256|20260101|assigned|id",
            "apnic|JP|ipv4|2.0.0.0|256|20260101|allocated|id",
            "apnic|CN|ipv4|3.0.0.0|256|20260101|reserved|id",
            "apnic|CN|ipv6|2400::|32|20260101|allocated|id",
        ])
        self.assertEqual([str(n) for n in updater.parse_source("apnic", text)],
                         ["1.0.0.0/23", "1.0.2.0/24", "1.0.4.0/24"])

    def test_ripe_json(self):
        text = '{"status":"ok","data":{"resources":{"ipv4":["1.0.0.0/24"]}}}'
        self.assertEqual(str(updater.parse_source("ripe", text)[0]), "1.0.0.0/24")
        with self.assertRaises(ValueError):
            updater.parse_source("ripe", '{"status":"error"}')
        for text in ('[]', 'null', '{"status":"ok","data":{"resources":{"ipv4":"1.0.0.0/24"}}}'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                updater.parse_source("ripe", text)


class UpdateTests(unittest.TestCase):
    def test_merge_partial_failure_and_checksum(self):
        responses = {"a": "1.0.0.0/24\n1.0.0.0/25\n",
                     "b": "1.0.1.0/24\n1.0.0.0/24\n", "html": "<html>error</html>"}

        def fetch(url):
            if url == "offline":
                raise OSError("timeout")
            if url == "truncated":
                raise http.client.IncompleteRead(b"partial response")
            return responses[url]

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "IPchnroute"
            sources = [("cidr", url) for url in ("offline", "truncated", "a", "html", "b")]
            updater.update(output, sources, fetch)
            self.assertEqual(output.read_text(), "1.0.0.0/23\n")
            digest = Path(str(output) + ".sha256sum").read_text().strip()
            self.assertEqual(digest, hashlib.sha256(output.read_bytes()).hexdigest())
            # Source order and duplicates cannot change the generated result.
            updater.update(output, list(reversed(sources)), fetch)
            self.assertEqual(output.read_text(), "1.0.0.0/23\n")
            self.assertEqual(len(list(Path(directory).iterdir())), 2)

    def test_total_failure_preserves_existing_files(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "IPchnroute"
            checksum = Path(str(output) + ".sha256sum")
            output.write_text("old list\n")
            checksum.write_text("old checksum\n")
            with self.assertRaises(RuntimeError):
                updater.update(output, [("cidr", "empty"), ("cidr", "html")],
                               lambda url: "" if url == "empty" else "<html>error</html>")
            self.assertEqual(output.read_text(), "old list\n")
            self.assertEqual(checksum.read_text(), "old checksum\n")
            self.assertEqual(len(list(Path(directory).iterdir())), 2)

    def test_existing_cidr_dedupe_behavior(self):
        nets = updater._iter_networks(["1.0.0.0/24", "1.0.0.0/24", "invalid", "1.0.1.0/24"])
        self.assertEqual(list(ipaddress.collapse_addresses(nets)),
                         [ipaddress.IPv4Network("1.0.0.0/23")])


if __name__ == "__main__":
    unittest.main()
