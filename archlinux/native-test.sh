#!/usr/bin/env bash
set -euo pipefail
export XDG_RUNTIME_DIR="$(mktemp -d)"
chmod 700 "$XDG_RUNTIME_DIR"
export WAYLAND_DISPLAY=wayland-emberpvp
export QT_QPA_PLATFORM=wayland
export LIBGL_ALWAYS_SOFTWARE=1
weston --backend=headless-backend.so --renderer=gl --socket="$WAYLAND_DISPLAY" --idle-time=0 --width=1440 --height=1000 --log="$XDG_RUNTIME_DIR/weston.log" &
weston_pid=$!
trap 'kill "$weston_pid" 2>/dev/null || true' EXIT
for i in $(seq 1 100); do test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && break; kill -0 "$weston_pid"; sleep .1; done
test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
"$GITHUB_WORKSPACE/archlinux/src/build/SkinRendererTest" -o -,txt
"$GITHUB_WORKSPACE/archlinux/src/build/AppearanceUiTest" -o -,txt
export WAYLAND_DEBUG=client
/usr/bin/emberpvp --dir "$XDG_RUNTIME_DIR/isolated-launcher" --show-window > "$GITHUB_WORKSPACE/archlinux/startup.log" 2>&1 &
launcher_pid=$!
trap 'kill "$launcher_pid" "$weston_pid" 2>/dev/null || true' EXIT
sleep 8
kill -0 "$launcher_pid"
grep -Eq 'xdg_toplevel.*(set_title|set_app_id)|xdg_surface.*get_toplevel|xdg_wm_base.*get_xdg_surface' "$GITHUB_WORKSPACE/archlinux/startup.log"
echo 'Installed native Arch package created a Wayland window.'
kill "$launcher_pid"
wait "$launcher_pid" || true
