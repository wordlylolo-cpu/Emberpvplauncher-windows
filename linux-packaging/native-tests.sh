#!/usr/bin/env bash
set -euo pipefail
export XDG_RUNTIME_DIR="${RUNNER_TEMP}/emberpvp-wayland"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export WAYLAND_DISPLAY=wayland-emberpvp
export LIBGL_ALWAYS_SOFTWARE=1
weston --backend=headless-backend.so --renderer=gl --socket="$WAYLAND_DISPLAY" --idle-time=0 --width=1440 --height=1000 --log="${RUNNER_TEMP}/weston-emberpvp.log" &
compositor_pid=$!
trap 'kill "$compositor_pid" 2>/dev/null || true' EXIT
for attempt in $(seq 1 100); do
  test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && break
  kill -0 "$compositor_pid"
  sleep .1
done
test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
manifest=source/packaging/linux/org.emberpvp.EmberpvpLauncher.yml
if [[ "${1:-tests}" == tests ]]; then
  timeout 90 flatpak-builder --run build-flatpak "$manifest" env QT_QPA_PLATFORM=wayland LIBGL_ALWAYS_SOFTWARE=1 /app/libexec/emberpvp-ci/SkinRendererTest -o -,txt
  timeout 90 flatpak-builder --run build-flatpak "$manifest" env QT_QPA_PLATFORM=wayland LIBGL_ALWAYS_SOFTWARE=1 /app/libexec/emberpvp-ci/AppearanceUiTest -o -,txt
else
  log="${RUNNER_TEMP}/emberpvp-flatpak-startup.log"
  flatpak run --user --env=QT_QPA_PLATFORM=wayland --env=WAYLAND_DEBUG=client --env=LIBGL_ALWAYS_SOFTWARE=1 org.emberpvp.EmberpvpLauncher --dir /tmp/emberpvp-ci-isolated --show-window >"$log" 2>&1 &
  launcher_pid=$!
  trap 'kill "$launcher_pid" "$compositor_pid" 2>/dev/null || true' EXIT
  sleep 8
  kill -0 "$launcher_pid"
  if ! grep -Eq 'xdg_toplevel.*(set_title|set_app_id)|xdg_surface.*get_toplevel|xdg_wm_base.*get_xdg_surface' "$log"; then
    cat "$log"
    echo 'No native Wayland window was observed.' >&2
    exit 1
  fi
  echo 'Installed Flatpak created a native Wayland window and stayed running.'
  kill "$launcher_pid"
  wait "$launcher_pid" || true
fi
