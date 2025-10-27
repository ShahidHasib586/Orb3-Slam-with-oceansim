# ~/run_isaac_ros2_jazzy_fastdds.sh
#!/usr/bin/env bash
set -u  # keep terminal open on exit; don't use `set -e` or `exec`

# --- EDIT if needed ---
ISAAC_ROOT="$HOME/isaacsim/_build/linux-x86_64/release"
BRIDGE_DIR="$ISAAC_ROOT/exts/isaacsim.ros2.bridge"
# ----------------------

if [[ ! -d "$BRIDGE_DIR" ]]; then
  echo "❌ Bridge not found at $BRIDGE_DIR"
  read -rp "Press Enter to close..."; exit 1
fi

# 0) Drop any system ROS from this shell (prevents mixing)
strip_ros () { printf "%s" "${1:-}" | tr ':' '\n' | grep -vE '^/opt/ros|/usr/lib/ros' | paste -sd ':' - ; }
export AMENT_PREFIX_PATH="$(strip_ros "${AMENT_PREFIX_PATH:-}")"
export COLCON_PREFIX_PATH="$(strip_ros "${COLCON_PREFIX_PATH:-}")"
export ROS_PACKAGE_PATH="$(strip_ros "${ROS_PACKAGE_PATH:-}")"
export PYTHONPATH="$(strip_ros "${PYTHONPATH:-}")"
export LD_LIBRARY_PATH="$(strip_ros "${LD_LIBRARY_PATH:-}")"

# 1) Use the bridge’s embedded **Jazzy** with **FastDDS**
export ROS_DISTRO=jazzy
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp   # <- important
export PYTHONNOUSERSITE=1

# 2) Add the bridge’s Jazzy libs so rmw_* can be loaded
export LD_LIBRARY_PATH="$BRIDGE_DIR/jazzy/lib:${LD_LIBRARY_PATH:-}"

# 3) Make Isaac’s Python see rclpy when /jazzy is mounted (inside process)
export PYTHONPATH="/jazzy/lib/python3.11/site-packages${PYTHONPATH:+:$PYTHONPATH}"

# 4) (Optional) stability tweaks
# export FASTDDS_SHM_LISTEN_ADDRESS=127.0.0.1

# 5) Start Isaac with the bridge enabled; keep logs and the terminal open
LOG="$HOME/isaacsim_ros2_jazzy_fastdds.log"
"$ISAAC_ROOT/isaac-sim.sh" --enable isaacsim.ros2.bridge --/log/level=info 2>&1 | tee "$LOG"
echo "[launcher] Exit code: $?"
echo "[launcher] Log: $LOG"
read -rp "Press Enter to close..."
