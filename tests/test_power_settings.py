import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "omarchy/power-settings.py"
TEMPLATE = ROOT / "omarchy/power-settings.conf"
spec = importlib.util.spec_from_file_location("power_settings", HELPER)
power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(power)


class PowerSettingsTests(unittest.TestCase):
    def setUp(self):
        self.desired = power.parse(TEMPLATE.read_text())

    def test_defaults_are_compared(self):
        changed = power.differences("[UPower]\n", self.desired)
        self.assertEqual(set(changed), {"PercentageCritical", "PercentageAction"})
        self.assertEqual(changed["PercentageAction"], ("2.0", "5.0"))

    def test_matching_values_ignore_numeric_format(self):
        text = TEMPLATE.read_text().replace("5.0", "5").replace("=true", "=TRUE")
        self.assertEqual(power.differences(text, self.desired), {})

    def test_render_preserves_other_sections_and_comments(self):
        text = "# keep\n[UPower]\nIgnoreLid=false\nPercentageAction=2.0\n[Other]\nPercentageAction=42\n"
        result = power.render(text, self.desired)
        self.assertIn("# keep\n", result)
        self.assertIn("IgnoreLid=false\n", result)
        self.assertIn("[Other]\nPercentageAction=42\n", result)
        self.assertEqual(power.differences(result, self.desired), {})
        self.assertEqual(power.render(result, self.desired), result)

    def test_render_missing_section_and_final_newline(self):
        for text in ("", "# keep", "[Other]\nx=1", "[UPower]\nx=1"):
            result = power.render(text, self.desired)
            self.assertEqual(power.differences(result, self.desired), {})

    def test_check_does_not_write(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "UPower.conf"
            target.write_text("[UPower]\n")
            result = subprocess.run([sys.executable, str(HELPER), "check", str(TEMPLATE),
                                     "--target", str(target)], capture_output=True, text=True, check=True)
            self.assertIn("PercentageAction: 2.0 -> 5.0", result.stdout)
            self.assertEqual(target.read_text(), "[UPower]\n")
            self.assertEqual(len(list(Path(directory).iterdir())), 1)

    def test_apply_backs_up_and_only_restarts_when_changed(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "UPower.conf"
            original = "[UPower]\nIgnoreLid=false\n"
            target.write_text(original)
            argv = [str(HELPER), "apply", str(TEMPLATE), "--target", str(target)]
            with patch.object(sys, "argv", argv), patch.object(power.subprocess, "run") as restart:
                power.main()
                restart.assert_called_once_with(["systemctl", "restart", "upower.service"], check=True)
                restart.reset_mock()
                power.main()
                restart.assert_not_called()
            backups = list(Path(directory).glob("*.bak.*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), original)
            self.assertIn("IgnoreLid=false", target.read_text())


class DotctlConfirmationTests(unittest.TestCase):
    def run_settings(self, differences="", enabled=True, dry_run=False, yes=False):
        source = (ROOT / "dotctl").read_text()
        function = source[source.index("ensure_omarchy_power_settings() {"):
                          source.index("ensure_fish_login_shell() {")]
        helpers = source[source.index("show_cmd() {"):source.index("usage() {")]
        script = """
set -euo pipefail
REPO=/unused
VERBOSE=false
info() { echo "$*"; }
ok() { echo "$*"; }
warn() { echo "$*"; }
die() { echo "$*"; exit 1; }
python3() { printf '%s' "$DIFFERENCES"; }
omarchy() {
  if [[ "$*" == 'toggle enabled screensaver-off' ]]; then
    $ENABLED
  else
    echo "MUTATION: omarchy $*"
  fi
}
sudo() { echo "MUTATION: sudo $*"; }
"""
        import os
        env = dict(os.environ, DIFFERENCES=differences, ENABLED=str(enabled).lower())
        script += f"DRY_RUN={str(dry_run).lower()}\nYES={str(yes).lower()}\n"
        result = subprocess.run(["bash"], input=script + helpers + function +
                                "ensure_omarchy_power_settings\n", env=env,
                                capture_output=True, text=True, check=True)
        return result.stdout

    def test_matching_settings_do_not_mutate(self):
        self.assertNotIn("MUTATION:", self.run_settings(yes=True))

    def test_noninteractive_differences_are_kept(self):
        output = self.run_settings("  PercentageAction: 2 -> 5", enabled=False)
        self.assertIn("PercentageAction: 2 -> 5", output)
        self.assertIn("Keeping current UPower settings", output)
        self.assertIn("Keeping current screensaver setting", output)
        self.assertNotIn("MUTATION:", output)

    def test_dry_run_does_not_mutate_even_with_yes(self):
        output = self.run_settings("  PercentageAction: 2 -> 5", enabled=False,
                                   dry_run=True, yes=True)
        self.assertIn("Would ask", output)
        self.assertNotIn("MUTATION:", output)

    def test_yes_applies_both_differences(self):
        output = self.run_settings("  PercentageAction: 2 -> 5", enabled=False, yes=True)
        self.assertIn("MUTATION: sudo python3 /unused/omarchy/power-settings.py apply", output)
        self.assertIn("MUTATION: omarchy toggle screensaver-off on", output)


if __name__ == "__main__":
    unittest.main()
