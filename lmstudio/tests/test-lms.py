"""Exercise LM Studio setup without installing software or downloading models."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SETUP = Path(__file__).resolve().parents[1] / "lms.sh"
QWEN = "qwen/qwen3.8-27b"
GEMMA = "google/gemma-4-12b"
GPT = "openai/gpt-oss-20b"
DOWNLOADS = [
    f"lms get --yes --mlx {QWEN}@4bit",
    f"lms get --yes --mlx {GEMMA}@4bit",
    f"lms get --yes --gguf {GPT}@mxfp4",
]


class LmStudioTests(unittest.TestCase):
    def run_setup(self, **overrides):
        with tempfile.TemporaryDirectory(prefix="test-lmstudio-") as directory:
            root = Path(directory)
            calls_file = root / "calls"
            lms = root / "lms"
            lms.write_text(
                """#!/bin/bash
printf 'lms %s\\n' "$*" >> "$TEST_CALLS"
case "$1" in
ls) printf '%s\\n' "$TEST_MODELS"; exit "$TEST_LIST_STATUS" ;;
get) exit "$TEST_DOWNLOAD_STATUS" ;;
*) exit 99 ;;
esac
"""
            )
            lms.chmod(0o755)
            source = SETUP.read_text().removesuffix('\nmain "$@"\n')
            script = (
                source
                + """
app_installed() { [[ "$TEST_APP_INSTALLED" == 1 ]]; }
has_terminal() { [[ "$TEST_HAS_UI" == 1 ]]; }
brew() {
    printf 'brew %s\\n' "$*" >> "$TEST_CALLS"
    return "$TEST_INSTALL_STATUS"
}
open() { return 99; }
gum() {
    printf 'gum %s\\n' "$*" >> "$TEST_CALLS"
    case "$*" in
    *Qwen3.8*) return "$TEST_QWEN_CHOICE" ;;
    *'Gemma 4'*) return "$TEST_GEMMA_CHOICE" ;;
    *gpt-oss*) return "$TEST_GPT_CHOICE" ;;
    *) return 99 ;;
    esac
}
main
"""
            )
            env = os.environ.copy()
            env.update(
                PATH=f"{root}:{env['PATH']}",
                TEST_CALLS=str(calls_file),
                TEST_APP_INSTALLED="1",
                TEST_HAS_UI="1",
                TEST_INSTALL_STATUS="0",
                TEST_LIST_STATUS="0",
                TEST_DOWNLOAD_STATUS="0",
                TEST_MODELS="[]",
                TEST_QWEN_CHOICE="0",
                TEST_GEMMA_CHOICE="0",
                TEST_GPT_CHOICE="0",
                SETUP_LMSTUDIO_QWEN38="",
                SETUP_LMSTUDIO_GEMMA4="",
                SETUP_LMSTUDIO_GPT_OSS="",
            )
            env.update(overrides)
            result = subprocess.run(
                ["/bin/bash", "-s"],
                input=script,
                env=env,
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )
            calls = calls_file.read_text().splitlines() if calls_file.exists() else []
            return result, calls

    def test_individual_choices(self):
        result, calls = self.run_setup(TEST_GEMMA_CHOICE="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        prompts = [call for call in calls if call.startswith("gum ")]
        self.assertEqual(len(prompts), 3)
        self.assertTrue(all("confirm --default=false" in call for call in prompts))
        self.assertEqual(
            [call for call in calls if call.startswith("lms get ")],
            [DOWNLOADS[0], DOWNLOADS[2]],
        )

    def test_installed_models_are_skipped(self):
        models = [
            {"modelKey": key, "deviceIdentifier": None}
            for key in (QWEN + "@8bit", GEMMA, GPT)
        ]
        result, calls = self.run_setup(TEST_MODELS=json.dumps(models))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["lms ls --json"])

    def test_remote_model_does_not_count_as_local(self):
        models = [{"modelKey": QWEN, "deviceIdentifier": "other-mac"}]
        result, calls = self.run_setup(
            TEST_MODELS=json.dumps(models),
            SETUP_LMSTUDIO_QWEN38="yes",
            SETUP_LMSTUDIO_GEMMA4="no",
            SETUP_LMSTUDIO_GPT_OSS="no",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["lms ls --json", DOWNLOADS[0]])

    def test_unattended_default_skips_inventory_and_downloads(self):
        result, calls = self.run_setup(TEST_HAS_UI="0")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [])

    def test_unattended_explicit_choices(self):
        result, calls = self.run_setup(
            TEST_HAS_UI="0",
            SETUP_LMSTUDIO_QWEN38="no",
            SETUP_LMSTUDIO_GEMMA4="YES",
            SETUP_LMSTUDIO_GPT_OSS="true",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["lms ls --json", *DOWNLOADS[1:]])

    def test_missing_app_is_installed_once(self):
        result, calls = self.run_setup(TEST_APP_INSTALLED="0", TEST_HAS_UI="0")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["brew install --cask lm-studio"])

    def test_failures_stop_before_later_downloads(self):
        cases = (
            ({"TEST_QWEN_CHOICE": "130"}, 130, 0),
            ({"SETUP_LMSTUDIO_QWEN38": "invalid"}, 2, 0),
            ({"TEST_LIST_STATUS": "7"}, 7, 0),
            ({"TEST_MODELS": "{}"}, 5, 0),
            ({"TEST_DOWNLOAD_STATUS": "8"}, 8, 1),
            ({"TEST_APP_INSTALLED": "0", "TEST_INSTALL_STATUS": "9"}, 9, 0),
        )
        for overrides, status, download_count in cases:
            with self.subTest(overrides=overrides):
                result, calls = self.run_setup(**overrides)
                self.assertEqual(result.returncode, status, result.stderr)
                downloads = [call for call in calls if call.startswith("lms get ")]
                self.assertEqual(len(downloads), download_count)


if __name__ == "__main__":
    unittest.main()
