"""Exercise Docker setup with mocked package/service commands, never using sudo."""
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / "dotctl").read_text()
HELPERS = SOURCE[SOURCE.index("show_cmd() {"):SOURCE.index("usage() {")]
DOCKER = SOURCE[SOURCE.index("docker_desktop_integration() {"):
                SOURCE.index("omarchy_prerequisites() {")]


class DockerTests(unittest.TestCase):
    def run_shell(self, body, *, installed="", dry_run=False, yes=False, extra=""):
        script = """
set -euo pipefail
VERBOSE=false
info() { echo "$*"; }
ok() { echo "$*"; }
warn() { echo "$*"; }
die() { echo "$*"; exit 1; }
check_ok() { echo "OK: $*"; }
check_fail() { echo "FAIL: $*"; }
is_wsl() { true; }
sudo() { echo "MUTATION: sudo $*"; }
"""
        script += f"DRY_RUN={str(dry_run).lower()}\nYES={str(yes).lower()}\n"
        script += HELPERS + DOCKER
        script += """
docker_package_installed() { [[ " $INSTALLED " == *" $1 "* ]]; }
# These functions make CLI discovery and daemon inspection deterministic.
docker() { echo "DOCKER: $*"; return "${DOCKER_STATUS:-0}"; }
command() {
  if [[ "$*" == '-v docker' && "${HAS_DOCKER:-false}" == false ]]; then
    return 1
  fi
  builtin command "$@"
}
"""
        return subprocess.run(
            ["bash"], input=script + extra + body,
            env=dict(os.environ, INSTALLED=installed), capture_output=True, text=True,
        )

    def run_install(self, **kwargs):
        extra = """
docker_desktop_integration() { false; }
ubuntu_docker_repository() { echo REPOSITORY; }
ensure_docker_service() { echo SERVICE; }
ensure_docker_group() { echo GROUP; }
"""
        return self.run_shell("ubuntu_docker\n", extra=extra + kwargs.pop("extra", ""), **kwargs)

    def test_fresh_install_includes_all_plugins(self):
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("REPOSITORY", result.stdout)
        self.assertIn("sudo apt-get update", result.stdout)
        self.assertIn("docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin", result.stdout)
        self.assertIn("SERVICE\nGROUP", result.stdout)

    def test_complete_install_does_not_touch_apt(self):
        result = self.run_install(installed="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("REPOSITORY", result.stdout)
        self.assertNotIn("apt-get", result.stdout)

    def test_partial_install_only_installs_missing_packages(self):
        result = self.run_install(installed="docker-ce docker-ce-cli containerd.io")
        self.assertIn("install -y --no-install-recommends docker-buildx-plugin docker-compose-plugin", result.stdout)

    def test_conflicting_packages_are_never_removed(self):
        for package in ("docker.io", "containerd", "runc", "podman-docker", "docker-compose-v2"):
            with self.subTest(package=package):
                result = self.run_install(installed=package)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Keeping them unchanged", result.stdout)
                self.assertNotIn("MUTATION:", result.stdout)

    def test_desktop_skips_native_install_even_with_conflicts(self):
        result = self.run_install(installed="containerd", extra="docker_desktop_integration() { true; }\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Docker Desktop", result.stdout)
        self.assertNotIn("REPOSITORY", result.stdout)
        self.assertNotIn("SERVICE", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_unmanaged_cli_is_preserved(self):
        result = self.run_install(extra="HAS_DOCKER=true\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unmanaged Docker CLI", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_install_dry_run_does_not_mutate(self):
        result = self.run_install(dry_run=True, yes=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("apt-get", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_group_requires_consent_and_warns_about_privileges(self):
        extra = 'id() { if [[ "$1" == -un ]]; then echo tester; else echo "tester users"; fi; }\n'
        result = self.run_shell("ensure_docker_group\n", extra=extra)
        self.assertNotIn("MUTATION:", result.stdout)
        result = self.run_shell("ensure_docker_group\n", extra=extra, yes=True)
        self.assertIn("sudo usermod -aG docker tester", result.stdout)
        self.assertIn("logging out", result.stdout)
        result = self.run_shell("ensure_docker_group\n", extra=extra, yes=True, dry_run=True)
        self.assertIn("root-equivalent", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_existing_group_is_idempotent(self):
        result = self.run_shell("ensure_docker_group\n", yes=True, extra='id() { if [[ "$1" == -un ]]; then echo tester; else echo "tester docker"; fi; }\n')
        self.assertIn("already a member", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_desktop_detection_uses_wsl_symlink_targets(self):
        result = self.run_shell("docker_desktop_integration\n", extra='readlink() { echo /mnt/wsl/docker-desktop/cli-tools/usr/bin/docker; }\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_shell("docker_desktop_integration\n", extra='is_wsl() { false; }\n')
        self.assertNotEqual(result.returncode, 0)

    def test_doctor_is_read_only_and_checks_plugins_and_daemon(self):
        result = self.run_shell("HAS_DOCKER=true\ndoctor_docker\n", extra='timeout() { shift; "$@"; }\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK: Docker Compose", result.stdout)
        self.assertIn("OK: Docker Buildx", result.stdout)
        self.assertIn("OK: Docker daemon", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_doctor_reports_unreachable_daemon(self):
        result = self.run_shell("HAS_DOCKER=true\ndoctor_docker\n", extra='timeout() { return 1; }\n')
        self.assertIn("FAIL: Docker daemon is unreachable", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_service_is_idempotent_and_dry_run_safe(self):
        start = DOCKER.index("ensure_docker_service() {")
        end = DOCKER.index("ensure_docker_group() {")
        service = DOCKER[start:end].replace("[[ -d /run/systemd/system ]]", "$HAS_SYSTEMD")
        for active in (True, False):
            extra = service + f"HAS_SYSTEMD=true\nACTIVE={str(active).lower()}\n"
            extra += 'systemctl() { $ACTIVE; }\n'
            result = self.run_shell("ensure_docker_service\n", extra=extra)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual("MUTATION:" in result.stdout, not active)
            result = self.run_shell("ensure_docker_service\n", extra=extra, dry_run=True)
            self.assertNotIn("MUTATION:", result.stdout)
        result = self.run_shell("ensure_docker_service\n", extra=service + "HAS_SYSTEMD=false\n")
        self.assertIn("systemd is not running", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_repository_configuration_and_cleanup(self):
        extra = r'''
# No existing Docker source, but do not depend on host APT files.
grep() { return 1; }
dpkg() { echo amd64; }
curl() {
  echo "FETCH: $*"
  if [[ "${FETCH_FAIL:-false}" == true ]]; then return 22; fi
  local previous="" argument
  for argument in "$@"; do
    if [[ "$previous" == -o && "$argument" != /dev/null ]]; then
      printf 'test signing key\n' > "$argument"
    fi
    previous="$argument"
  done
}
'''
        result = self.run_shell("ubuntu_docker_repository\n", extra=extra)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("https://download.docker.com/linux/ubuntu/gpg", result.stdout)
        self.assertIn("/etc/apt/keyrings/docker.asc", result.stdout)
        self.assertIn("/etc/apt/sources.list.d/dotctl-docker.sources", result.stdout)
        # The temporary download is cleaned up even after the subshell returns.
        for line in result.stdout.splitlines():
            if "sudo install -m 644" in line:
                temporary_path = line.split("sudo install -m 644 ", 1)[1].split()[0]
                self.assertFalse(Path(temporary_path).exists())
        result = self.run_shell("ubuntu_docker_repository\n", extra=extra + "FETCH_FAIL=true\n")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("MUTATION:", result.stdout)
        result = self.run_shell("ubuntu_docker_repository\n", extra=extra, dry_run=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("FETCH:", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_existing_repository_is_reused(self):
        result = self.run_shell("ubuntu_docker_repository\n", extra='grep() { return 0; }\ncurl() { echo UNEXPECTED_DOWNLOAD; }\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("UNEXPECTED_DOWNLOAD", result.stdout)
        self.assertNotIn("MUTATION:", result.stdout)

    def test_system_layer_calls_ubuntu_docker(self):
        function = SOURCE[SOURCE.index("system_layer() {"):SOURCE.index("github_auth() {")]
        for platform in ("ubuntu", "ubuntu-wsl"):
            result = self.run_shell("system_layer\n", extra=function + f'platform() {{ echo {platform}; }}\nubuntu_prerequisites() {{ :; }}\nensure_fish_login_shell() {{ :; }}\nubuntu_docker() {{ echo DOCKER_SETUP; }}\n')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("DOCKER_SETUP", result.stdout)


if __name__ == "__main__":
    unittest.main()
