#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
  echo 'Run this script with sudo or the OS authentication dialog to add the Emberpvp pacman repository.' >&2
  exit 1
fi
[[ $(uname -m) == x86_64 ]] || { echo 'Only Arch Linux x86_64 is supported.' >&2; exit 1; }
[[ -r /etc/arch-release && -r /etc/pacman.conf ]] || { echo "This setup requires an Arch Linux installation." >&2; exit 1; }
command -v pacman >/dev/null
command -v pacman-key >/dev/null
command -v curl >/dev/null
fingerprint='8D778544D320F057BA94FA770D763F81538EFA62'
tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -m 700 "$tmpdir/gnupg"
curl --proto '=https' --tlsv1.2 -fL https://emberpvp.xyz/arch/emberpvp-repository.asc -o "$tmpdir/repository.asc"
actual=$(gpg --homedir "$tmpdir/gnupg" --batch --show-keys --with-colons "$tmpdir/repository.asc" | awk -F: '$1 == "fpr" { print $10; exit }')
[[ "$actual" == "$fingerprint" ]] || { echo 'Repository key fingerprint does not match.' >&2; exit 1; }
# Do not replace an unrelated repository definition.
if grep -Eq '^\[emberpvp\]' /etc/pacman.conf; then
  echo 'An inline [emberpvp] repository already exists. Review it before using this installer.' >&2
  exit 1
fi
if [[ -e /etc/pacman.d/emberpvp.conf ]] && ! grep -Fq 'https://emberpvp.xyz/arch/$arch' /etc/pacman.d/emberpvp.conf; then
  echo 'An existing Emberpvp repository points elsewhere. Review it before using this installer.' >&2
  exit 1
fi
pacman-key --add "$tmpdir/repository.asc"
pacman-key --lsign-key "$fingerprint"
cat > "$tmpdir/emberpvp.conf" <<'EOF'
[emberpvp]
SigLevel = Required DatabaseRequired
Server = https://emberpvp.xyz/arch/$arch
EOF
install -Dm644 "$tmpdir/emberpvp.conf" /etc/pacman.d/emberpvp.conf
if ! grep -Eq '^[[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman.d/emberpvp.conf[[:space:]]*$' /etc/pacman.conf; then
  cp -a /etc/pacman.conf "/etc/pacman.conf.emberpvp-backup.$(date +%Y%m%d%H%M%S)"
  printf '\n# Emberpvp signed community repository\nInclude = /etc/pacman.d/emberpvp.conf\n' >> /etc/pacman.conf
fi
# Sync only this new repository. Existing Arch databases and packages are untouched.
printf '[options]\nArchitecture = auto\nSigLevel = Required DatabaseRequired\nInclude = /etc/pacman.d/emberpvp.conf\n' > "$tmpdir/sync.conf"
pacman --config "$tmpdir/sync.conf" -Sy --noconfirm
pacman -Si emberpvp
echo 'Emberpvp repository configured. Install with: sudo pacman -S emberpvp'
echo 'For a fully current Arch system, use: sudo pacman -Syu emberpvp'
