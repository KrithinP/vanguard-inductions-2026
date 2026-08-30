# Escape hatch for recruits who cannot dual-boot or run a VM.
# ROS 2 Jazzy + Gazebo Harmonic on a browser-accessible Linux desktop.
FROM tiryoh/ros2-desktop-vnc:jazzy

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3-colcon-common-extensions \
      python3-rosdep \
      python3-pip \
      ros-jazzy-ros-gz \
      ros-jazzy-turtlesim \
      ros-jazzy-rqt-graph \
      ros-jazzy-tf2-tools \
      ros-jazzy-teleop-twist-keyboard \
      git nano vim less tree \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --break-system-packages opencv-contrib-python

# NOTE: rosdep is deliberately NOT initialised here. At build time it fetches
# several raw.githubusercontent.com URLs and stalls for minutes (or fails
# outright) on a slow or filtered connection. Nothing here needs it.

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc \
 && echo "[ -f ~/vanguard_ws/install/setup.bash ] && source ~/vanguard_ws/install/setup.bash" >> /root/.bashrc

WORKDIR /root/vanguard_ws
