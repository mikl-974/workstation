#!/usr/bin/env bash

export OC_FORCE_X11="${OC_FORCE_X11:-1}"
export GDK_BACKEND="${GDK_BACKEND:-x11}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
export WEBKIT_DISABLE_COMPOSITING_MODE="${WEBKIT_DISABLE_COMPOSITING_MODE:-1}"
export WEBKIT_DISABLE_DMABUF_RENDERER="${WEBKIT_DISABLE_DMABUF_RENDERER:-1}"
export GSK_RENDERER="${GSK_RENDERER:-cairo}"

for candidate in /run/current-system/sw/lib /nix/store/*gcc-*-lib/lib; do
	if [ -e "$candidate/libstdc++.so.6" ]; then
		export LD_LIBRARY_PATH="$candidate${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
		break
	fi
done

unset WAYLAND_DISPLAY

exec /run/current-system/sw/bin/opencode "$@"