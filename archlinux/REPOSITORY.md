# Emberpvp Arch repository

This is an independent community pacman repository. It is not an official Arch repository or an AUR listing. It serves the native x86_64 package `emberpvp` and requires one-time configuration per machine.

The Arch build workflow builds the pinned corresponding source in an Arch container, runs policy/unit tests, installs the package, then tests the renderer, appearance, and actual installed Wayland window. Physical GPU/KDE and Microsoft/gameplay verification remain separate interactive checks.

Public repository: https://emberpvp.xyz/arch/x86_64/
Install instructions: https://emberpvp.xyz/download/arch/
Signing fingerprint: 8D778544D320F057BA94FA770D763F81538EFA62

The signing key is retained locally in `~/.local/share/emberpvp-packaging/gnupg` with restricted permissions. Never add that directory, private keys, or revocation certificates to the website checkout, GitHub, release files, or website source archive. Back it up privately. Only its public key and detached signatures are published.

For a future package revision, update PKGBUILD version/pkgrel/source checksum, run the native build checks, verify the release digest, then sign the verified package using the retained local signing key. Use repo-add --sign --key with this fingerprint to rebuild the database. Export the public key, copy actual database aliases into static files, update arch-release-assets.json, and publish the tested website. Increment pkgrel for a changed binary; do not replace an existing versioned package with different bytes.

The setup script adds `/etc/pacman.d/emberpvp.conf`, appends one Include to pacman.conf after backing it up, adds and locally trusts the pinned public key, and synchronizes only this new database. It requires OS administrator authentication. It does not install or upgrade the launcher or other system packages. The website recommends `sudo pacman -Syu emberpvp` for the initial package installation; `sudo pacman -S emberpvp` then works normally with the configured repository.

Normal launcher and game execution do not need root permissions. Launcher source and original copyright notices remain GPL-3.0-only, with matching source linked alongside the binaries.
