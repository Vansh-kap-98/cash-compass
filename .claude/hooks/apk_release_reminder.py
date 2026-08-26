"""PostToolUse hook: remind about the APK release loop after a git pull.

Merging or pulling changes nothing on any installed phone. The APK is a frozen
snapshot, so new commits only reach a device after a rebuild and reinstall.
This fires on `git pull` because that is the moment new code lands locally and
the rebuild becomes possible.

Reads the hook payload on stdin, prints a systemMessage JSON object when the
command was a git pull, and stays silent otherwise. Silence is the normal case:
anything printed here becomes UI noise.
"""

import json
import sys

REMINDER = (
    "APK release loop - new commits are not on any phone yet:\n"
    "  1. Bump version in mobile/pubspec.yaml (0.1.0+N -> +N+1)\n"
    "  2. cd mobile && flutter build apk --release --split-per-abi "
    "--obfuscate --split-debug-info=build/debug-info\n"
    "  3. Send app-arm64-v8a-release.apk to testers\n"
    "Signed with your keystore, so it installs over the old build - "
    "no uninstall, data preserved."
)


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # A malformed or empty payload must never break the tool call.
        return

    command = (payload.get("tool_input") or {}).get("command") or ""
    if "git pull" not in command:
        return

    json.dump({"systemMessage": REMINDER}, sys.stdout)


if __name__ == "__main__":
    main()
