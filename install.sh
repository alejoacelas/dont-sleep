#!/usr/bin/env bash
set -euo pipefail

LABEL="com.example.dont-sleep"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVOKING_USER="${SUDO_USER:-${USER}}"
INSTALL_SCRIPT="/usr/local/libexec/dont-sleep.sh"
INSTALL_PLIST="/Library/LaunchDaemons/${LABEL}.plist"

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo "$0"
fi

tmp_plist="$(mktemp "/tmp/${LABEL}.XXXXXX.plist")"
trap 'rm -f "${tmp_plist}"' EXIT

sed \
  -e "s|/ABSOLUTE/PATH/TO/dont-sleep.sh|${INSTALL_SCRIPT}|" \
  -e "s|YOUR_USERNAME|${INVOKING_USER}|g" \
  "${SCRIPT_DIR}/dont-sleep.plist" > "${tmp_plist}"
plutil -lint "${tmp_plist}" >/dev/null

if launchctl print "system/${LABEL}" >/dev/null 2>&1; then
  launchctl bootout "system/${LABEL}"
fi

install -d -o root -g wheel -m 755 /usr/local/libexec
install -o root -g wheel -m 755 "${SCRIPT_DIR}/dont-sleep.sh" "${INSTALL_SCRIPT}"
install -o root -g wheel -m 644 "${tmp_plist}" "${INSTALL_PLIST}"
launchctl bootstrap system "${INSTALL_PLIST}"

launchctl print "system/${LABEL}" >/dev/null
printf 'Installed and running %s with a 15%% battery cutoff.\n' "${LABEL}"
