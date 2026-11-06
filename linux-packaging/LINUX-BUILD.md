# Emberpvp Linux Flatpak

Native C++/Qt application, Minecraft Java 1.21.11 + Fabric only. This direct x86_64 Flatpak bundle is independent of Flathub's application listings. Flathub supplies the KDE runtime and build SDK. There is no published AUR, apt, RPM, or Flathub application package named Emberpvp.

## Build

Install Flatpak and flatpak-builder on a Linux build machine. Add the Flathub remote for your user and install org.kde.Sdk//6.10, org.kde.Platform//6.10, and org.freedesktop.Sdk.Extension.openjdk17 for that SDK's Freedesktop base. Then, from the source root:

```
flatpak-builder --user --force-clean --install-deps-from=flathub --build-only build-flatpak packaging/linux/org.emberpvp.EmberpvpLauncher.yml
flatpak-builder --user --finish-only --repo=flatpak-repo build-flatpak packaging/linux/org.emberpvp.EmberpvpLauncher.yml
flatpak build-bundle flatpak-repo EmberpvpLauncher-Linux-x86_64.flatpak org.emberpvp.EmberpvpLauncher stable --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo
```

The application module runs the policy/unit tests. The CI workflow also starts a headless Weston compositor, runs the 3D skin renderer and appearance checks with QT_QPA_PLATFORM=wayland, and checks a native Wayland window from the installed bundle. Real Microsoft sign-in, actual Minecraft gameplay, and physical GPU/driver combinations require interactive testing. No particular FPS improvement is guaranteed.

The sandbox grants network, GPU, audio, and home-directory access for Microsoft/game downloads, Minecraft rendering, and custom instances/imports. It does not require root for launching. The download can be installed per user. NVIDIA graphics extensions are managed by Flatpak; physical NVIDIA hardware has not been benchmarked in CI.

The packaging module versions/checksums follow the upstream Prism Flathub manifests at https://github.com/flathub/org.prismlauncher.PrismLauncher. Original notices remain in the application source and package. The matching launcher source and pinned dependency build definitions accompany the release under GPL-3.0-only; dependencies retain their own licenses.
