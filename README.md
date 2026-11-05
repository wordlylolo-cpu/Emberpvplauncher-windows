# Emberpvp Launcher — Windows 11 x64

Independent GPL-3.0-only Prism Launcher fork. Minecraft Java **1.21.11 + Fabric only**, with the Emberpvp interface, player preview, performance presets, mod management, and fictional prelaunch animation.

## Download

[Download the tested Windows bundle](https://github.com/wordlylolo-cpu/Emberpvplauncher-windows/actions/runs/42074130281/artifacts/13437083957).

Extract the bundle and run **EmberpvpLauncher-Windows11-x64-Setup.exe** on Windows. It installs for the current user. Alternatively, extract **EmberpvpLauncher-Windows11-x64.zip** and run `emberpvp-launcher.exe`, keeping its DLLs and folders together. Both include matching source and license notices. `SHA256SUMS.txt` contains the checksums. These builds are unsigned.

No personal accounts, settings, worlds or tokens are included. Sign in and create a Fabric 1.21.11 instance in your own Windows installation. CurseForge needs your own API key; Modrinth does not. Performance presets install compatible mods and settings; no particular FPS gain is promised.

## Verification

The [Windows compiler run](https://github.com/wordlylolo-cpu/Emberpvplauncher-windows/actions/runs/42071224199) passed all **34 CTest suites**, the 3D skin-renderer test, and the packaged native-window smoke test. Its installer check exposed a path-format issue, corrected in the packaging workflow.

The [successful packaging run](https://github.com/wordlylolo-cpu/Emberpvplauncher-windows/actions/runs/42074130281) reuses those tested binaries, includes the corrected packaging source, verifies the portable GUI on a fresh runner without the Qt development kit, and tests custom-directory installation, native-window startup, registry uninstall registration, and removal while preserving a user-added file.

The build/test host is Windows Server 2022; the intended runtime is Windows 11 x64. Microsoft sign-in and Minecraft gameplay on a physical Windows 11 PC still require an interactive test with a licensed account. The original Linux installation is independent and unchanged.

## Source and building

`payload/*.b64` contain the compressed base source, verified against `payload/manifest.json`. `windows-overrides/` contains the complete Windows corrections and dependency port/triplet files. The Windows workflow reconstructs the source, applies these files, and includes the resulting matching archive in the installer, portable package and download bundle.

Extract the source archive and read `packaging/windows/WINDOWS-BUILD.md` for Windows build commands and dependencies. The full build workflow is `.github/workflows/windows.yml`; packaging-only validation is `.github/workflows/windows-package.yml`. Upstream notices remain in LICENSE and COPYING.md. Redistribute matching source with redistributed binaries as required by GPL-3.0.
